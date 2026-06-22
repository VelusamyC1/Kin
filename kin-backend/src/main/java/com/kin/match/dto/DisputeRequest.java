package com.kin.match.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.List;

@Data
public class DisputeRequest {

    @NotEmpty @Size(min = 1, max = 3)
    @Valid
    private List<SetScoreRequest> proposedSets;
}
