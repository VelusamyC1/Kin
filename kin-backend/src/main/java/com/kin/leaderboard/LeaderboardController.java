package com.kin.leaderboard;

import com.kin.user.User;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/leaderboard")
@RequiredArgsConstructor
public class LeaderboardController {

    private final LeaderboardService leaderboardService;

    @GetMapping
    public ResponseEntity<List<LeaderboardEntry>> leaderboard(
            @RequestParam(defaultValue = "global") String scope,
            @RequestParam(defaultValue = "50") int limit,
            @AuthenticationPrincipal User user) {

        String scopeValue = switch (scope) {
            case "city"    -> user.getCity();
            case "country" -> user.getCountry();
            default        -> null;
        };

        if ((scope.equals("city") || scope.equals("country")) && scopeValue == null) {
            return ResponseEntity.badRequest().build();
        }

        return ResponseEntity.ok(leaderboardService.leaderboard(scope, scopeValue, limit));
    }
}
