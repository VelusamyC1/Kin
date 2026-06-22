package com.kin.notification;

import com.kin.user.User;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationRepository notificationRepository;

    @GetMapping
    public ResponseEntity<List<NotificationDto>> list(@AuthenticationPrincipal User user) {
        List<NotificationDto> dtos = notificationRepository
                .findByUserIdOrderByCreatedAtDesc(user.getId())
                .stream()
                .map(n -> new NotificationDto(n.getId(), n.getType(), n.getPayload(), n.getReadAt(), n.getCreatedAt()))
                .toList();
        return ResponseEntity.ok(dtos);
    }

    @PostMapping("/{id}/read")
    public ResponseEntity<Void> markRead(
            @PathVariable UUID id,
            @AuthenticationPrincipal User user) {
        int updated = notificationRepository.markRead(id, user.getId(), OffsetDateTime.now());
        return updated > 0 ? ResponseEntity.ok().build() : ResponseEntity.notFound().build();
    }
}
