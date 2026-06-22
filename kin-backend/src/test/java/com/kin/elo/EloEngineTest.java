package com.kin.elo;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;

class EloEngineTest {

    private EloEngine engine;

    // fixed UUIDs for readability
    private static final UUID A1 = UUID.randomUUID();
    private static final UUID A2 = UUID.randomUUID();
    private static final UUID B1 = UUID.randomUUID();
    private static final UUID B2 = UUID.randomUUID();

    @BeforeEach
    void setUp() { engine = new EloEngine(); }

    // ---------------------------------------------------------------
    // Zero-sum: sum of all changes must be within ±2
    // ---------------------------------------------------------------

    @Test
    void zeroSum_evenMatch_established() {
        var players = evenMatch(1500, 1500, false);
        var sets    = List.of(new SetScore(6, 4), new SetScore(6, 4)); // team1 wins
        assertZeroSum(engine.compute(players, sets));
    }

    @Test
    void zeroSum_unevenElo_provisional() {
        var players = List.of(
            new PlayerInput(A1, 1800, true, 1),
            new PlayerInput(A2, 1700, true, 1),
            new PlayerInput(B1, 1200, false, 2),
            new PlayerInput(B2, 1100, false, 2)
        );
        var sets = List.of(new SetScore(6, 1), new SetScore(6, 2));
        assertZeroSum(engine.compute(players, sets));
    }

    @Test
    void zeroSum_blowout() {
        var players = evenMatch(1500, 1500, false);
        var sets    = List.of(new SetScore(6, 0), new SetScore(6, 0), new SetScore(6, 0));
        assertZeroSum(engine.compute(players, sets));
    }

    @Test
    void zeroSum_nailbiter() {
        var players = evenMatch(1500, 1500, false);
        var sets    = List.of(new SetScore(7, 6), new SetScore(6, 7), new SetScore(7, 6));
        assertZeroSum(engine.compute(players, sets));
    }

    // ---------------------------------------------------------------
    // Winners gain, losers lose
    // ---------------------------------------------------------------

    @Test
    void winners_gainPoints_losers_losePoints() {
        var players = evenMatch(1500, 1500, false);
        var sets    = List.of(new SetScore(6, 3), new SetScore(6, 3));
        var result  = engine.compute(players, sets);

        var team1 = result.stream().filter(c -> getTeam(players, c.userId()) == 1).toList();
        var team2 = result.stream().filter(c -> getTeam(players, c.userId()) == 2).toList();

        team1.forEach(c -> assertThat(c.change()).isPositive());
        team2.forEach(c -> assertThat(c.change()).isNegative());
    }

    // ---------------------------------------------------------------
    // K-factor: provisional players move more
    // ---------------------------------------------------------------

    @Test
    void provisional_K40_movesMoreThan_established_K20() {
        var provisionalPlayers = evenMatch(1500, 1500, true);
        var establishedPlayers = evenMatch(1500, 1500, false);
        var sets = List.of(new SetScore(6, 3), new SetScore(6, 3));

        int provChange  = Math.abs(engine.compute(provisionalPlayers, sets).get(0).change());
        int estabChange = Math.abs(engine.compute(establishedPlayers, sets).get(0).change());

        assertThat(provChange).isGreaterThan(estabChange);
    }

    // ---------------------------------------------------------------
    // Margin multiplier: blowout > nailbiter
    // ---------------------------------------------------------------

    @Test
    void blowout_givesMorePoints_than_nailbiter() {
        var players  = evenMatch(1500, 1500, false);
        var blowout  = List.of(new SetScore(6, 0), new SetScore(6, 0));
        var nailbiter= List.of(new SetScore(7, 6), new SetScore(7, 6));

        int blowoutGain   = winnerGain(engine.compute(players, blowout));
        int nailbiterGain = winnerGain(engine.compute(players, nailbiter));

        assertThat(blowoutGain).isGreaterThan(nailbiterGain);
    }

    // ---------------------------------------------------------------
    // Expected value: favourite wins → small gain; upset → large gain
    // ---------------------------------------------------------------

    @Test
    void underdog_upset_gains_more_than_favourite_expected_win() {
        // team1 (weak) upsets team2 (strong)
        var players = List.of(
            new PlayerInput(A1, 1200, false, 1),
            new PlayerInput(A2, 1200, false, 1),
            new PlayerInput(B1, 1800, false, 2),
            new PlayerInput(B2, 1800, false, 2)
        );
        var sets = List.of(new SetScore(6, 3), new SetScore(6, 3)); // underdog wins

        var resultUpset = engine.compute(players, sets);
        int underdogGain = winnerGain(resultUpset);

        // now the favourite wins normally
        var players2 = List.of(
            new PlayerInput(A1, 1800, false, 1),
            new PlayerInput(A2, 1800, false, 1),
            new PlayerInput(B1, 1200, false, 2),
            new PlayerInput(B2, 1200, false, 2)
        );
        var resultNormal = engine.compute(players2, sets);
        int favouriteGain = winnerGain(resultNormal);

        assertThat(underdogGain).isGreaterThan(favouriteGain);
    }

    // ---------------------------------------------------------------
    // eloAfter consistency
    // ---------------------------------------------------------------

    @Test
    void eloAfter_equals_eloBefore_plus_change() {
        var players = evenMatch(1500, 1500, false);
        var sets    = List.of(new SetScore(6, 4), new SetScore(6, 4));
        engine.compute(players, sets).forEach(c ->
            assertThat(c.eloAfter()).isEqualTo(c.eloBefore() + c.change())
        );
    }

    // ---------------------------------------------------------------
    // Validation
    // ---------------------------------------------------------------

    @Test
    void validation_rejects_wrongPlayerCount() {
        var players = List.of(new PlayerInput(A1, 1500, false, 1));
        var sets    = List.of(new SetScore(6, 3));
        assertThatThrownBy(() -> engine.compute(players, sets))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void validation_rejects_unevenTeams() {
        var players = List.of(
            new PlayerInput(A1, 1500, false, 1),
            new PlayerInput(A2, 1500, false, 1),
            new PlayerInput(B1, 1500, false, 1),
            new PlayerInput(B2, 1500, false, 2)
        );
        var sets = List.of(new SetScore(6, 3));
        assertThatThrownBy(() -> engine.compute(players, sets))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void validation_rejects_duplicatePlayers() {
        var players = List.of(
            new PlayerInput(A1, 1500, false, 1),
            new PlayerInput(A1, 1500, false, 1), // duplicate
            new PlayerInput(B1, 1500, false, 2),
            new PlayerInput(B2, 1500, false, 2)
        );
        var sets = List.of(new SetScore(6, 3));
        assertThatThrownBy(() -> engine.compute(players, sets))
            .isInstanceOf(IllegalArgumentException.class);
    }

    // ---------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------

    private List<PlayerInput> evenMatch(int eloA, int eloB, boolean provisional) {
        return List.of(
            new PlayerInput(A1, eloA, provisional, 1),
            new PlayerInput(A2, eloA, provisional, 1),
            new PlayerInput(B1, eloB, provisional, 2),
            new PlayerInput(B2, eloB, provisional, 2)
        );
    }

    private void assertZeroSum(List<PlayerChange> changes) {
        int sum = changes.stream().mapToInt(PlayerChange::change).sum();
        assertThat(sum).as("Zero-sum: net change across all players").isBetween(-2, 2);
    }

    private int winnerGain(List<PlayerChange> changes) {
        return changes.stream().mapToInt(PlayerChange::change).max().orElseThrow();
    }

    private int getTeam(List<PlayerInput> players, UUID userId) {
        return players.stream().filter(p -> p.userId().equals(userId)).findFirst().orElseThrow().team();
    }
}
