package com.kin.rating;

import com.kin.user.User;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "ratings")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Rating {

    @Id
    private UUID userId;

    @OneToOne(fetch = FetchType.LAZY)
    @MapsId
    @JoinColumn(name = "user_id")
    private User user;

    @Column(nullable = false)
    private int elo;

    @Column(nullable = false, precision = 3, scale = 2)
    private BigDecimal level;

    @Column(name = "matches_confirmed", nullable = false)
    private int matchesConfirmed;

    @Builder.Default
    @Column(name = "is_provisional", nullable = false)
    private boolean isProvisional = true;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @PrePersist
    @PreUpdate
    void touch() {
        updatedAt = OffsetDateTime.now();
    }
}
