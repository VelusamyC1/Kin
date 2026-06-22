package com.kin.leaderboard;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.math.BigDecimal;
import java.util.UUID;

@Data
@AllArgsConstructor
public class LeaderboardEntry {
    private long rank;
    private UUID userId;
    private String firstName;
    private String lastName;
    private String city;
    private String country;
    private int elo;
    private BigDecimal level;
    private String tier;
    private int matchesConfirmed;
    private boolean isProvisional;
}
