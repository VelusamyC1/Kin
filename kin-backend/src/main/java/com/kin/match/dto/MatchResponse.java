package com.kin.match.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Data
@AllArgsConstructor
public class MatchResponse {
    private UUID id;
    private String status;
    private OffsetDateTime playedAt;
    private OffsetDateTime autoConfirmAt;
    private List<MatchPlayerDto> players;
    private List<MatchSetDto> sets;

    @Data @AllArgsConstructor
    public static class MatchPlayerDto {
        private UUID userId;
        private String firstName;
        private String lastName;
        private int team;
        private boolean isWinner;
    }

    @Data @AllArgsConstructor
    public static class MatchSetDto {
        private int setNo;
        private int team1Games;
        private int team2Games;
    }
}
