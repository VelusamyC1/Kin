package com.kin.elo;

import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

/**
 * Pure Elo computation — stateless, no DB access.
 *
 * Formula (from spec §4):
 *   teamElo       = avg of both partners' elo
 *   expected      = 1 / (1 + 10^((opponentTeamElo - ownTeamElo) / 400))
 *   K             = 40 (provisional) | 20 (established)
 *   baseChange    = K * (result - expected)
 *   gamesDiff     = totalGamesWon - totalGamesLost  (from player's team perspective; winners +, losers -)
 *   marginMult    = 1 + clamp(gamesDiff, -12, 12) / 12   range ~[0.0, 2.0], symmetric around 1
 *   change        = round(baseChange * marginMult)
 *
 * Zero-sum guarantee: same |marginMult| applied to both sides → net change ≈ 0 (within ±2 due to rounding).
 */
@Service
public class EloEngine {

    private static final int K_PROVISIONAL  = 40;
    private static final int K_ESTABLISHED  = 20;
    private static final double GAMES_CAP   = 12.0;

    /**
     * @param players exactly 4 players, team values must be 1 or 2 (2 per team)
     * @param sets    1–3 set scores
     * @return one PlayerChange per player
     */
    public List<PlayerChange> compute(List<PlayerInput> players, List<SetScore> sets) {
        validate(players, sets);

        List<PlayerInput> teamA = players.stream().filter(p -> p.team() == 1).toList();
        List<PlayerInput> teamB = players.stream().filter(p -> p.team() == 2).toList();

        double teamAElo = avg(teamA);
        double teamBElo = avg(teamB);

        int team1GamesTotal = sets.stream().mapToInt(SetScore::team1Games).sum();
        int team2GamesTotal = sets.stream().mapToInt(SetScore::team2Games).sum();

        // winner = team that won more sets (majority of sets)
        long team1SetsWon = sets.stream().filter(s -> s.team1Games() > s.team2Games()).count();
        long team2SetsWon = sets.stream().filter(s -> s.team2Games() > s.team1Games()).count();
        int winnerTeam = team1SetsWon > team2SetsWon ? 1 : 2;

        // absolute game difference — same magnitude applied to all players to preserve zero-sum.
        // using signed per-player gamesDiff would give losers marginMult≈0, breaking zero-sum.
        int absGamesDiff = Math.abs(team1GamesTotal - team2GamesTotal);
        double marginMult = 1.0 + clamp(absGamesDiff, 0, GAMES_CAP) / GAMES_CAP;

        return players.stream().map(p -> {
            boolean isTeam1 = p.team() == 1;
            double opponentTeamElo = isTeam1 ? teamBElo : teamAElo;
            double ownTeamElo      = isTeam1 ? teamAElo : teamBElo;
            boolean won            = p.team() == winnerTeam;

            double expected   = 1.0 / (1.0 + Math.pow(10.0, (opponentTeamElo - ownTeamElo) / 400.0));
            double result     = won ? 1.0 : 0.0;
            int    k          = p.isProvisional() ? K_PROVISIONAL : K_ESTABLISHED;
            double baseChange = k * (result - expected);
            int    change     = (int) Math.round(baseChange * marginMult);

            return new PlayerChange(p.userId(), p.elo(), change, p.elo() + change);
        }).toList();
    }

    // --- helpers ---

    private double avg(List<PlayerInput> players) {
        return players.stream().mapToInt(PlayerInput::elo).average().orElseThrow();
    }

    private double clamp(double value, double min, double max) {
        return Math.max(min, Math.min(max, value));
    }

    private void validate(List<PlayerInput> players, List<SetScore> sets) {
        if (players == null || players.size() != 4)
            throw new IllegalArgumentException("Exactly 4 players required");
        long team1Count = players.stream().filter(p -> p.team() == 1).count();
        long team2Count = players.stream().filter(p -> p.team() == 2).count();
        if (team1Count != 2 || team2Count != 2)
            throw new IllegalArgumentException("2 players per team required");
        if (sets == null || sets.isEmpty() || sets.size() > 3)
            throw new IllegalArgumentException("1–3 sets required");
        long uniqueIds = players.stream().map(PlayerInput::userId).distinct().count();
        if (uniqueIds != 4)
            throw new IllegalArgumentException("All 4 players must be distinct");
    }
}
