package com.kin.onboarding;

import com.kin.user.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/onboarding")
@RequiredArgsConstructor
public class OnboardingController {

    private final OnboardingService onboardingService;

    @PostMapping("/level")
    public ResponseEntity<OnboardingResponse> setLevel(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody OnboardingRequest req) {
        return ResponseEntity.ok(onboardingService.setLevel(user.getId(), req));
    }
}
