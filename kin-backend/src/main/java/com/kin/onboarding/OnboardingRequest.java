package com.kin.onboarding;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class OnboardingRequest {

    @NotNull
    @Min(0) @Max(7)
    private Integer selfLevel;

    private boolean playsTournaments;
}
