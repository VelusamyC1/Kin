package com.kin.auth;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.UUID;

@Service
public class JwtService {

    private final SecretKey key;
    private final long accessTokenExpiryMs;

    public JwtService(
            @Value("${kin.jwt.secret}") String secret,
            @Value("${kin.jwt.access-token-expiry-ms}") long accessTokenExpiryMs) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.accessTokenExpiryMs = accessTokenExpiryMs;
    }

    public String generateAccessToken(UUID userId, String email) {
        long now = System.currentTimeMillis();
        return Jwts.builder()
                .subject(userId.toString())
                .claim("email", email)
                .issuedAt(new Date(now))
                .expiration(new Date(now + accessTokenExpiryMs))
                .signWith(key)
                .compact();
    }

    public Claims validateAndParse(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public UUID extractUserId(String token) {
        return UUID.fromString(validateAndParse(token).getSubject());
    }
}
