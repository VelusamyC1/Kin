package com.kin.match;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ConfirmationRepository extends JpaRepository<Confirmation, ConfirmationId> {

    @Query("SELECT c FROM Confirmation c WHERE c.match.id = :matchId")
    List<Confirmation> findByMatchId(UUID matchId);

    @Query("SELECT c FROM Confirmation c WHERE c.match.id = :matchId AND c.user.id = :userId")
    Optional<Confirmation> findByMatchIdAndUserId(UUID matchId, UUID userId);
}
