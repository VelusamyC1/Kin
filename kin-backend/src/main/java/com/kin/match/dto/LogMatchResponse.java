package com.kin.match.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.util.Map;
import java.util.UUID;

@Data
@AllArgsConstructor
public class LogMatchResponse {
    private UUID matchId;
    private String status;
    private Map<UUID, Integer> predictedEloChange;  // userId -> change
}
