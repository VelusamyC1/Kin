package com.kin.rating;

import jakarta.persistence.*;
import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "rating_history")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RatingHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "match_id", nullable = false)
    private UUID matchId;

    @Column(name = "elo_before", nullable = false)
    private int eloBefore;

    @Column(name = "elo_after", nullable = false)
    private int eloAfter;

    @Column(nullable = false)
    private int change;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @PrePersist
    void prePersist() { if (createdAt == null) createdAt = OffsetDateTime.now(); }
}
