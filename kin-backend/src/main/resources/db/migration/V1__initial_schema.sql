-- ACCOUNTS ---------------------------------------------------------------
CREATE TABLE users (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email             TEXT UNIQUE NOT NULL,
  password_hash     TEXT NOT NULL,
  first_name        TEXT NOT NULL,
  last_name         TEXT NOT NULL,
  gender            TEXT,
  country           TEXT,
  city              TEXT,
  hand              TEXT,
  plays_tournaments BOOLEAN NOT NULL DEFAULT false,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
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
CREATE INDEX idx_refresh_tokens_token_hash ON refresh_tokens(token_hash);

-- RATING -----------------------------------------------------------------
CREATE TABLE ratings (
  user_id           UUID PRIMARY KEY REFERENCES users(id),
  elo               INTEGER NOT NULL,
  level             NUMERIC(3,2) NOT NULL,
  matches_confirmed INTEGER NOT NULL DEFAULT 0,
  is_provisional    BOOLEAN NOT NULL DEFAULT true,
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RATING HISTORY ---------------------------------------------------------
CREATE TABLE rating_history (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id),
  match_id   UUID NOT NULL,
  elo_before INTEGER NOT NULL,
  elo_after  INTEGER NOT NULL,
  change     INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_rating_history_user_id ON rating_history(user_id);

-- MATCHES ----------------------------------------------------------------
CREATE TABLE matches (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_by      UUID NOT NULL REFERENCES users(id),
  status          TEXT NOT NULL DEFAULT 'pending',
  played_at       TIMESTAMPTZ NOT NULL,
  auto_confirm_at TIMESTAMPTZ NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT matches_status_check CHECK (status IN ('pending','confirmed','disputed','expired'))
);
CREATE INDEX idx_matches_status ON matches(status);
CREATE INDEX idx_matches_auto_confirm_at ON matches(auto_confirm_at) WHERE status = 'pending';

CREATE TABLE match_players (
  match_id  UUID NOT NULL REFERENCES matches(id),
  user_id   UUID NOT NULL REFERENCES users(id),
  team      SMALLINT NOT NULL CHECK (team IN (1,2)),
  is_winner BOOLEAN NOT NULL,
  PRIMARY KEY (match_id, user_id)
);

CREATE TABLE match_sets (
  match_id    UUID NOT NULL REFERENCES matches(id),
  set_no      SMALLINT NOT NULL CHECK (set_no BETWEEN 1 AND 3),
  team1_games SMALLINT NOT NULL,
  team2_games SMALLINT NOT NULL,
  PRIMARY KEY (match_id, set_no)
);

-- CONFIRMATIONS ----------------------------------------------------------
CREATE TABLE confirmations (
  match_id UUID NOT NULL REFERENCES matches(id),
  user_id  UUID NOT NULL REFERENCES users(id),
  state    TEXT NOT NULL DEFAULT 'pending',
  acted_at TIMESTAMPTZ,
  PRIMARY KEY (match_id, user_id),
  CONSTRAINT confirmations_state_check CHECK (state IN ('pending','confirmed','disputed'))
);

-- DISPUTES ---------------------------------------------------------------
CREATE TABLE disputes (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id      UUID NOT NULL REFERENCES matches(id),
  raised_by     UUID NOT NULL REFERENCES users(id),
  proposed_sets JSONB NOT NULL,
  state         TEXT NOT NULL DEFAULT 'open',
  resolved_at   TIMESTAMPTZ,
  CONSTRAINT disputes_state_check CHECK (state IN ('open','accepted','rejected'))
);

-- SOCIAL -----------------------------------------------------------------
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
  type       TEXT NOT NULL,
  payload    JSONB NOT NULL,
  read_at    TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT notifications_type_check CHECK (
    type IN ('confirm_request','result_confirmed','disputed','ranking_updated')
  )
);
CREATE INDEX idx_notifications_user_id_read_at ON notifications(user_id, read_at);
