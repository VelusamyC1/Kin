package com.kin.user;

import com.kin.rating.EloUtils;
import com.kin.rating.RatingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/me")
@RequiredArgsConstructor
public class MeController {

    private final RatingRepository ratingRepository;

    @GetMapping
    public ResponseEntity<Map<String, Object>> me(@AuthenticationPrincipal User user) {
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("id", user.getId());
        response.put("email", user.getEmail());
        response.put("firstName", user.getFirstName());
        response.put("lastName", user.getLastName());
        response.put("country", user.getCountry() != null ? user.getCountry() : "");
        response.put("city", user.getCity() != null ? user.getCity() : "");
        response.put("hand", user.getHand() != null ? user.getHand() : "");
        response.put("playsTournaments", user.isPlaysTournaments());

        ratingRepository.findByUserId(user.getId()).ifPresent(r -> {
            Map<String, Object> rating = new LinkedHashMap<>();
            rating.put("elo", r.getElo());
            rating.put("level", r.getLevel());
            rating.put("matchesConfirmed", r.getMatchesConfirmed());
            rating.put("isProvisional", r.isProvisional());
            rating.put("tier", EloUtils.tierFromMatches(r.getMatchesConfirmed()));
            response.put("rating", rating);
        });

        return ResponseEntity.ok(response);
    }
}
