package com.kin.rating;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Pure utility — no Spring deps, fully unit-testable.
 *
 * Spec:
 *   seedElo  = 1000 + round(selfLevel * 142.8)   selfLevel 0..7 → elo ~1000..2000
 *   level    = clamp((elo - 1000) / 142.8, 0, 7)  2dp
 *   tier     = Rookie(0-9) | Banger(10-24) | Pro(25-49) | Champion(50+)  by matchesConfirmed
 */
public final class EloUtils {

    private static final double ELO_PER_LEVEL = 142.8;
    private static final int BASE_ELO = 1000;

    private EloUtils() {}

    public static int seedElo(int selfLevel) {
        if (selfLevel < 0 || selfLevel > 7) throw new IllegalArgumentException("selfLevel must be 0–7");
        return BASE_ELO + (int) Math.round(selfLevel * ELO_PER_LEVEL);
    }

    public static BigDecimal levelFromElo(int elo) {
        double raw = (elo - BASE_ELO) / ELO_PER_LEVEL;
        double clamped = Math.max(0.0, Math.min(7.0, raw));
        return BigDecimal.valueOf(clamped).setScale(2, RoundingMode.HALF_UP);
    }

    public static String tierFromMatches(int matchesConfirmed) {
        if (matchesConfirmed < 10)  return "Rookie";
        if (matchesConfirmed < 25)  return "Banger";
        if (matchesConfirmed < 50)  return "Pro";
        return "Champion";
    }
}
