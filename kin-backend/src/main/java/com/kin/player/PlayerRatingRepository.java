package com.kin.player;

import com.kin.rating.Rating;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface PlayerRatingRepository extends JpaRepository<Rating, UUID> {
    Optional<Rating> findByUserId(UUID userId);
}
