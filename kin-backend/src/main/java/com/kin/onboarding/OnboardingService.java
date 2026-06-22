package com.kin.onboarding;

import com.kin.rating.EloUtils;
import com.kin.rating.Rating;
import com.kin.rating.RatingRepository;
import com.kin.user.User;
import com.kin.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class OnboardingService {

    private final RatingRepository ratingRepository;
    private final UserRepository userRepository;

    @Transactional
    public OnboardingResponse setLevel(UUID userId, OnboardingRequest req) {
        if (ratingRepository.findByUserId(userId).isPresent()) {
            throw new IllegalStateException("Onboarding already completed");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        user.setPlaysTournaments(req.isPlaysTournaments());
        userRepository.save(user);

        int elo = EloUtils.seedElo(req.getSelfLevel());
        Rating rating = Rating.builder()
                .user(user)
                .elo(elo)
                .level(EloUtils.levelFromElo(elo))
                .matchesConfirmed(0)
                .isProvisional(true)
                .build();
        ratingRepository.save(rating);

        return new OnboardingResponse(
                elo,
                rating.getLevel(),
                true,
                EloUtils.tierFromMatches(0)
        );
    }
}
