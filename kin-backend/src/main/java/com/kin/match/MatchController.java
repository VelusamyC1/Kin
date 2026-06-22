package com.kin.match;

import com.kin.match.dto.LogMatchRequest;
import com.kin.match.dto.LogMatchResponse;
import com.kin.match.dto.MatchResponse;
import com.kin.user.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/matches")
@RequiredArgsConstructor
public class MatchController {

    private final MatchService matchService;

    @PostMapping
    public ResponseEntity<LogMatchResponse> logMatch(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody LogMatchRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED).body(matchService.logMatch(user, req));
    }

    @GetMapping("/{id}")
    public ResponseEntity<MatchResponse> getMatch(
            @PathVariable UUID id,
            @AuthenticationPrincipal User user) {
        return matchService.getMatch(id, user.getId())
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}
