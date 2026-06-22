package com.kin.player;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.math.BigDecimal;
import java.util.UUID;

@Data
@AllArgsConstructor
public class PlayerResponse {
    private UUID id;
    private String firstName;
    private String lastName;
    private String city;
    private String country;
    private Integer elo;
    private BigDecimal level;
    private String tier;
}
