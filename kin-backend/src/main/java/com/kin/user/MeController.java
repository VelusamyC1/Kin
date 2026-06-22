package com.kin.user;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/me")
@RequiredArgsConstructor
public class MeController {

    @GetMapping
    public ResponseEntity<Map<String, Object>> me(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(Map.of(
                "id", user.getId(),
                "email", user.getEmail(),
                "firstName", user.getFirstName(),
                "lastName", user.getLastName(),
                "country", user.getCountry() != null ? user.getCountry() : "",
                "city", user.getCity() != null ? user.getCity() : "",
                "hand", user.getHand() != null ? user.getHand() : "",
                "playsTournaments", user.isPlaysTournaments()
        ));
    }
}
