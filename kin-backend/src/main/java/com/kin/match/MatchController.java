package com.kin.match;

import com.kin.match.dto.DisputeRequest;
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

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/matches")
@RequiredArgsConstructor
public class MatchController {

    private final MatchService matchService;
    private final MatchStateService matchStateService;

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

    @PostMapping("/{id}/confirm")
    public ResponseEntity<Void> confirm(
            @PathVariable UUID id,
            @AuthenticationPrincipal User user) {
        matchStateService.confirm(id, user);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/{id}/dispute")
    public ResponseEntity<Map<String, UUID>> dispute(
            @PathVariable UUID id,
            @AuthenticationPrincipal User user,
            @Valid @RequestBody DisputeRequest req) {
        UUID disputeId = matchStateService.dispute(id, user, req);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of("disputeId", disputeId));
    }

    @PostMapping("/{id}/dispute/{disputeId}/accept")
    public ResponseEntity<Void> acceptDispute(
            @PathVariable UUID id,
            @PathVariable UUID disputeId,
            @AuthenticationPrincipal User user) {
        matchStateService.acceptDispute(id, disputeId, user);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/{id}/dispute/{disputeId}/reject")
    public ResponseEntity<Void> rejectDispute(
            @PathVariable UUID id,
            @PathVariable UUID disputeId,
            @AuthenticationPrincipal User user) {
        matchStateService.rejectDispute(id, disputeId, user);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/{id}/drop")
    public ResponseEntity<Void> drop(
            @PathVariable UUID id,
            @AuthenticationPrincipal User user) {
        matchStateService.drop(id, user);
        return ResponseEntity.ok().build();
    }
}
