package com.kin.auth;

import com.kin.auth.dto.*;
import com.kin.user.User;
import com.kin.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.OffsetDateTime;
import java.util.Base64;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtService jwtService;
    private final PasswordEncoder passwordEncoder;

    @Value("${kin.jwt.refresh-token-expiry-days}")
    private int refreshTokenExpiryDays;

    private final SecureRandom secureRandom = new SecureRandom();

    @Transactional
    public AuthResponse signup(SignupRequest req) {
        if (userRepository.existsByEmail(req.getEmail())) {
            throw new IllegalArgumentException("Email already registered");
        }
        User user = User.builder()
                .email(req.getEmail().toLowerCase())
                .passwordHash(passwordEncoder.encode(req.getPassword()))
                .firstName(req.getFirstName())
                .lastName(req.getLastName())
                .gender(req.getGender())
                .country(req.getCountry())
                .city(req.getCity())
                .hand(req.getHand())
                .build();
        userRepository.save(user);
        return issueTokens(user);
    }

    @Transactional
    public AuthResponse login(LoginRequest req) {
        User user = userRepository.findByEmail(req.getEmail().toLowerCase())
                .orElseThrow(() -> new IllegalArgumentException("Invalid credentials"));
        if (!passwordEncoder.matches(req.getPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("Invalid credentials");
        }
        return issueTokens(user);
    }

    @Transactional
    public AuthResponse refresh(RefreshRequest req) {
        String hash = hash(req.getRefreshToken());
        RefreshToken stored = refreshTokenRepository.findByTokenHash(hash)
                .orElseThrow(() -> new IllegalArgumentException("Invalid refresh token"));
        if (!stored.isValid()) {
            throw new IllegalArgumentException("Refresh token expired or revoked");
        }
        stored.setRevokedAt(OffsetDateTime.now());
        refreshTokenRepository.save(stored);
        return issueTokens(stored.getUser());
    }

    @Transactional
    public void logout(RefreshRequest req) {
        String hash = hash(req.getRefreshToken());
        refreshTokenRepository.findByTokenHash(hash).ifPresent(t -> {
            t.setRevokedAt(OffsetDateTime.now());
            refreshTokenRepository.save(t);
        });
    }

    private AuthResponse issueTokens(User user) {
        String rawRefresh = generateRawToken();
        RefreshToken rt = RefreshToken.builder()
                .user(user)
                .tokenHash(hash(rawRefresh))
                .expiresAt(OffsetDateTime.now().plusDays(refreshTokenExpiryDays))
                .build();
        refreshTokenRepository.save(rt);
        String accessToken = jwtService.generateAccessToken(user.getId(), user.getEmail());
        return new AuthResponse(accessToken, rawRefresh);
    }

    private String generateRawToken() {
        byte[] bytes = new byte[32];
        secureRandom.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private String hash(String token) {
        try {
            var digest = java.security.MessageDigest.getInstance("SHA-256");
            byte[] hashed = digest.digest(token.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(hashed);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
