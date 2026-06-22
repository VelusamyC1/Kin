package com.kin.match.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class SetScoreRequest {
    @NotNull @Min(0) private Integer team1Games;
    @NotNull @Min(0) private Integer team2Games;
}
