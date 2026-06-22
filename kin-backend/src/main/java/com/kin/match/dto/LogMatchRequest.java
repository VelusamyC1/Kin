package com.kin.match.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Data
public class LogMatchRequest {

    @NotNull
    private UUID partnerId;

    @NotNull @Size(min = 2, max = 2)
    private List<UUID> opponentIds;

    @NotNull @NotEmpty @Size(min = 1, max = 3)
    @Valid
    private List<SetScoreRequest> sets;

    @NotNull
    private OffsetDateTime playedAt;
}
