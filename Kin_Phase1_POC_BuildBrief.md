# Kin — Phase 1 POC Build Brief

> **For:** Claude Code build sessions
> **Scope:** Sign up → log a doubles match (pick partner + opponents, enter score) → confirm/dispute → compute Elo ranking → display rank & leaderboard.
> **Out of scope (Phase 2):** Kai matchmaking, group chat, subscriptions/billing, share cards, social feed/circles beyond the player picker.

---

## 1. Tech stack

| Layer | Choice |
|---|---|
| Mobile client | Flutter (iOS + Android) |
| Backend | Spring Boot (Java 21) |
| Database | PostgreSQL |
| Auth | JWT (access token 15min + refresh token 30 days) |
| Notifications | Reuse existing notification service |
| Scheduling | Spring `@Scheduled` (auto-confirm job) |

**POC simplifications (call these out to Claude Code so it doesn't over-build):**
- Single Spring Boot monolith, no microservices.
- No real push provider needed for POC — notifications can be persisted rows + in-app list; wire the real provider later.
- Flutter state management: **Riverpod** (AsyncNotifier pattern — compile-safe, testable, fits API-driven screens).
- Seed 50 fake players (dev profile `DataLoader` bean) so the picker and leaderboard look real.

---

## 2. Phase 1 screen list (Flutter)

1. Login / Signup
2. Onboarding level quiz (self-rated level → provisional Elo)
3. Dashboard (your Elo, level, tier, rank, recent matches)
4. Log match (pick partner → pick 2 opponents → enter set scores → see predicted Elo change)
5. Confirm result (incoming: confirm or dispute within 48h)
6. Dispute / correct result
7. Profile + match history
8. Leaderboard (city / country / global toggle)
9. Notifications
10. Settings (minimal: account, logout)

---

## 3. Data model (PostgreSQL)

```sql
-- ACCOUNTS ---------------------------------------------------------------
CREATE TABLE users (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email              TEXT UNIQUE NOT NULL,
  password_hash      TEXT NOT NULL,
  first_name         TEXT NOT NULL,
  last_name          TEXT NOT NULL,
  gender             TEXT,                    -- not shown on profile
  country            TEXT,
  city               TEXT,
  hand               TEXT,                    -- 'right' | 'left'
  plays_tournaments  BOOLEAN NOT NULL DEFAULT false,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- REFRESH TOKENS ---------------------------------------------------------
CREATE TABLE refresh_tokens (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ON refresh_tokens(token_hash);

-- RATING (current snapshot, one row per user) ----------------------------
CREATE TABLE ratings (
  user_id           UUID PRIMARY KEY REFERENCES users(id),
  elo               INTEGER NOT NULL,
  level             NUMERIC(3,2) NOT NULL,     -- 0.00 .. 7.00, derived from elo
  matches_confirmed INTEGER NOT NULL DEFAULT 0,
  is_provisional    BOOLEAN NOT NULL DEFAULT true,
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RATING HISTORY (audit + form charts) -----------------------------------
CREATE TABLE rating_history (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id),
  match_id   UUID NOT NULL,
  elo_before INTEGER NOT NULL,
  elo_after  INTEGER NOT NULL,
  change     INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- MATCHES ----------------------------------------------------------------
CREATE TABLE matches (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_by      UUID NOT NULL REFERENCES users(id),
  status          TEXT NOT NULL DEFAULT 'pending', -- pending|confirmed|disputed|expired
  played_at       TIMESTAMPTZ NOT NULL,
  auto_confirm_at TIMESTAMPTZ NOT NULL,            -- played_at + 48h (or created_at + 48h)
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE match_players (
  match_id  UUID NOT NULL REFERENCES matches(id),
  user_id   UUID NOT NULL REFERENCES users(id),
  team      SMALLINT NOT NULL,        -- 1 or 2
  is_winner BOOLEAN NOT NULL,
  PRIMARY KEY (match_id, user_id)
);

CREATE TABLE match_sets (
  match_id    UUID NOT NULL REFERENCES matches(id),
  set_no      SMALLINT NOT NULL,      -- 1,2,3
  team1_games SMALLINT NOT NULL,
  team2_games SMALLINT NOT NULL,
  PRIMARY KEY (match_id, set_no)
);

-- CONFIRMATIONS (one row per non-creator participant) --------------------
CREATE TABLE confirmations (
  match_id UUID NOT NULL REFERENCES matches(id),
  user_id  UUID NOT NULL REFERENCES users(id),
  state    TEXT NOT NULL DEFAULT 'pending', -- pending|confirmed|disputed
  acted_at TIMESTAMPTZ,
  PRIMARY KEY (match_id, user_id)
);

CREATE TABLE disputes (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id      UUID NOT NULL REFERENCES matches(id),
  raised_by     UUID NOT NULL REFERENCES users(id),
  proposed_sets JSONB NOT NULL,        -- corrected score line
  state         TEXT NOT NULL DEFAULT 'open', -- open|accepted|rejected
  resolved_at   TIMESTAMPTZ
);

-- SOCIAL (just enough for the player picker) -----------------------------
CREATE TABLE follows (
  follower_id UUID NOT NULL REFERENCES users(id),
  followee_id UUID NOT NULL REFERENCES users(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (follower_id, followee_id)
);

-- NOTIFICATIONS ----------------------------------------------------------
CREATE TABLE notifications (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id),
  type       TEXT NOT NULL,            -- confirm_request|result_confirmed|disputed|ranking_updated
  payload    JSONB NOT NULL,
  read_at    TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

---

## 4. Elo engine (the source of truth)

**Decisions locked:**
- Team rating = **average of both partners' Elo**.
- **Margin matters** via a bounded multiplier.
- Elo is canonical; **level (0–7) is a display band derived from Elo**.

### Formula (run once, when a match becomes `confirmed`)

```
teamAElo = avg(playerElo for team A)
teamBElo = avg(playerElo for team B)

For each player p on team A (symmetric for B):
  expected      = 1 / (1 + 10^((opponentTeamElo - ownTeamElo) / 400))
  result        = 1 if player's team won else 0
  K             = 40 if p.is_provisional else 20
  baseChange    = K * (result - expected)
  marginMult    = 1 + (clamp(gamesDiff, -12, 12) / 12)   // gamesDiff from p's perspective
  change        = round(baseChange * marginMult)
```

- `gamesDiff = totalGamesWon - totalGamesLost` across all sets, from the player's team perspective. Winners positive, losers negative.
- **Margin multiplier range:** ~1.0 (nail-biter) to ~1.5 (blowout); applied symmetrically.
- **Provisional:** `is_provisional = true` until `matches_confirmed >= 10`, then flip to false. After flip, K=20.
- **Keep it ~zero-sum:** apply the same `marginMult` magnitude to winners and losers so net change across the four players ≈ 0. Add a unit test asserting `sum(changes) within ±2`.

### Onboarding seed (provisional Elo from self-rated level)

```
selfLevel (0..7)  ->  seedElo = 1000 + round(selfLevel * 142.8)   // spans ~1000..2000
ratings: elo=seedElo, level=levelFromElo(seedElo), is_provisional=true, matches_confirmed=0
```

### Level mapping (display only)

```
level = clamp((elo - 1000) / 142.8, 0, 7)   // ~142.8 Elo per level band, 2dp
```

Tier (Kin Club style — display label from confirmed-match count, not skill):
`0–9 = Rookie`, `10–24 = Banger`, `25–49 = Pro`, `50+ = Champion`. (Adjustable; cosmetic.)

### Leaderboard

- Rank = order by `elo DESC` within scope (`city` = same city, `country` = same country, `global` = all).
- Compute rank on read for POC (simple `ROW_NUMBER()` query). Add caching later if needed.

---

## 5. Match confirm / dispute state machine

This is the riskiest part — implement it carefully and test edge cases.

```
            log match (creator)
                  │
                  ▼
            ┌──────────┐   all non-creators confirm
            │ PENDING  │ ─────────────────────────────┐
            └──────────┘                               ▼
              │      │  any participant disputes  ┌────────────┐
              │      └──────────────────────────► │ DISPUTED   │
              │                                    └────────────┘
              │  48h elapses, no dispute            │          │
              │  (auto_confirm_at reached)          │ accept   │ reject
              ▼                                     │          │
        ┌────────────┐ ◄───────────────────────────┘          │
        │ CONFIRMED  │                              stays DISPUTED
        └────────────┘   (creator drops → EXPIRED, no Elo)
              │
              ▼
        Run Elo recompute ONCE → write rating_history → notify all players
```

**Rules**
- On log, create `confirmations` rows for every participant **except the creator** (creator implicitly confirms).
- Match → `confirmed` when **all** confirmation rows are `confirmed`, **or** when `now() >= auto_confirm_at` and status still `pending`.
- A dispute moves match → `disputed` and opens a `disputes` row with `proposed_sets`.
  - Creator **accepts** → replace `match_sets`, dispute state = `accepted`, match → `confirmed`.
  - Creator **rejects** → dispute state = `rejected`, match stays `disputed`. Creator must then either open to a new dispute correction or drop the match.
  - Creator **drops** → match → `expired`, no Elo effect.
- **Elo is computed exactly once**, at the confirm transition. The "predicted Elo change" shown at log time is read-only and never persisted.
- Scheduled job (every ~5 min) flips eligible `pending` matches to `confirmed` and runs the recompute.

**Edge cases to test**
- One of four players never acts → 48h auto-confirm fires.
- Two players dispute with different corrections → only one `open` dispute at a time; second dispute rejected with a clear message.
- Creator disputes own match → not allowed.
- Player tries to confirm twice → idempotent.
- Creator rejects a dispute → match stays `disputed`; creator must drop or wait for another correction.

---

## 6. REST API (Spring Boot)

```
# Auth
POST /auth/signup          {email, password, firstName, lastName, ...}  -> {accessToken, refreshToken}
POST /auth/login           {email, password}                             -> {accessToken, refreshToken}
POST /auth/refresh         {refreshToken}                                -> {accessToken, refreshToken}
POST /auth/logout          {refreshToken}                                -> 204 (revokes token)

# Onboarding
POST /onboarding/level     {selfLevel:0..7, playsTournaments:bool}       -> seeds provisional Elo

# Me
GET  /me                                           -> profile + rating snapshot
GET  /me/history?weeks=12                           -> rating_history for form chart
GET  /me/matches?status=pending|confirmed|all

# Players (for partner/opponent picker)
GET  /players?q=<name>&limit=20&offset=0           -> paginated typeahead (max limit=50)

# Matches
POST /matches              {partnerId, opponentIds:[a,b], sets:[{t1,t2}...], playedAt}
                           -> {matchId, status:'pending', predictedEloChange}
GET  /matches/{id}
POST /matches/{id}/confirm
POST /matches/{id}/dispute                         {proposedSets:[{t1,t2}...]}
POST /matches/{id}/dispute/{disputeId}/accept      (creator only → confirmed)
POST /matches/{id}/dispute/{disputeId}/reject      (creator only → stays disputed)
POST /matches/{id}/drop                            (creator only → expired)

# Leaderboard
GET  /leaderboard?scope=city|country|global&limit=50

# Notifications
GET  /notifications
POST /notifications/{id}/read
```

All endpoints except `/auth/signup`, `/auth/login`, and `/auth/refresh` require a valid JWT.

---

## 7. Suggested build order (for Claude Code sessions)

Build and verify in this sequence — each step is independently testable.

1. **Project scaffold** — Spring Boot app, Postgres connection, Flyway migration with the schema in §3. Health check endpoint.
2. **Auth** — JWT signup/login/refresh/logout, `/me`. Verify full token lifecycle end to end.
3. **Onboarding + rating seed** — level quiz endpoint (`playsTournaments` persisted), seed provisional Elo, `levelFromElo` util + unit tests.
4. **Elo engine as a pure, tested module** — implement §4 formula as a standalone service with unit tests (zero-sum assertion, provisional K, margin multiplier, level mapping) **before** wiring it to matches.
5. **Player seed data + picker endpoint** — `DataLoader` bean (dev profile only) inserts 50 fake players with varied Elo, cities, and confirmed match counts; `/players?q=` with pagination.
6. **Match logging** — `POST /matches`, create confirmations, return predicted change (read-only).
7. **Confirm/dispute state machine** — §5 including reject path and scheduled auto-confirm job. This is where most test effort goes.
8. **Recompute trigger** — on confirm, run Elo once, write `rating_history`, fire notifications.
9. **Leaderboard + history endpoints.**
10. **Flutter app** — build screens in §2 against the live API using Riverpod; start with auth + dashboard, then log-match, then confirm/dispute, then leaderboard/profile.

### Definition of "POC done"
A new user can: sign up → set provisional level → log a doubles match by picking a partner and two opponents and entering a 3-set score → opponents confirm (or 48h auto-confirm) → everyone's Elo updates correctly → the user sees their new rank on the leaderboard and the match in their history.

---

## 8. Things to deliberately NOT build in the POC
- Real push notifications (persist rows only).
- Payments / subscriptions.
- Kai matchmaking and group chat.
- Social feed, circles, rival watch.
- Image uploads / avatars (use initials).
- Production hardening (rate limiting, full GDPR flows) — note as follow-ups.

---

## 9. Gap fixes applied (changelog from original brief)

| # | Gap | Fix applied |
|---|---|---|
| 1 | No JWT refresh | Added `POST /auth/refresh` + `POST /auth/logout`; `refresh_tokens` table in schema |
| 2 | Player picker had no pagination | `GET /players` now takes `limit` (default 20, max 50) + `offset` |
| 3 | Dispute reject left match in dead-end | Added `POST /matches/{id}/dispute/{disputeId}/reject`; state machine updated |
| 4 | `playsTournaments` had no DB column | Added `plays_tournaments BOOLEAN` to `users` table |
| 5 | Seed data undefined | Defined as Spring `DataLoader` bean, dev profile only, 50 players |
| 6 | Flutter state management unresolved | Committed to **Riverpod** (AsyncNotifier pattern) |
