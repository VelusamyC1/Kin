package com.kin.onboarding;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.math.BigDecimal;

@Data
@AllArgsConstructor
public class OnboardingResponse {
    private int elo;
    private BigDecimal level;
    private boolean isProvisional;
    private String tier;
}
