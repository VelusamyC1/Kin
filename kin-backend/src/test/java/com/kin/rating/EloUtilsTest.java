package com.kin.rating;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.*;

class EloUtilsTest {

    @ParameterizedTest(name = "selfLevel={0} -> elo={1}")
    @CsvSource({
        "0, 1000",
        "1, 1143",
        "2, 1286",
        "3, 1428",
        "4, 1571",
        "5, 1714",
        "6, 1857",
        "7, 2000"
    })
    void seedElo_mapsCorrectly(int selfLevel, int expectedElo) {
        assertThat(EloUtils.seedElo(selfLevel)).isEqualTo(expectedElo);
    }

    @Test
    void seedElo_rejectsOutOfRange() {
        assertThatThrownBy(() -> EloUtils.seedElo(-1)).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> EloUtils.seedElo(8)).isInstanceOf(IllegalArgumentException.class);
    }

    @ParameterizedTest(name = "elo={0} -> level={1}")
    @CsvSource({
        "1000, 0.00",
        "1143, 1.00",
        "1500, 3.50",
        "2000, 7.00",
        "500,  0.00",   // clamped at 0
        "2500, 7.00"    // clamped at 7
    })
    void levelFromElo_mapsAndClamps(int elo, String expectedLevel) {
        assertThat(EloUtils.levelFromElo(elo)).isEqualByComparingTo(new BigDecimal(expectedLevel));
    }

    @ParameterizedTest(name = "matches={0} -> tier={1}")
    @CsvSource({
        "0,  Rookie",
        "9,  Rookie",
        "10, Banger",
        "24, Banger",
        "25, Pro",
        "49, Pro",
        "50, Champion",
        "100, Champion"
    })
    void tierFromMatches_correct(int matches, String expectedTier) {
        assertThat(EloUtils.tierFromMatches(matches)).isEqualTo(expectedTier);
    }

    @Test
    void seedElo_and_levelFromElo_areConsistent() {
        // round-trip: seed from level → derive level back → should match original
        for (int lvl = 0; lvl <= 7; lvl++) {
            int elo = EloUtils.seedElo(lvl);
            BigDecimal derived = EloUtils.levelFromElo(elo);
            assertThat(derived).isEqualByComparingTo(BigDecimal.valueOf(lvl).setScale(2));
        }
    }
}
