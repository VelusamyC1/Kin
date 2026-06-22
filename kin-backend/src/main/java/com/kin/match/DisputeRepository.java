package com.kin.match;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.Optional;
import java.util.UUID;

public interface DisputeRepository extends JpaRepository<Dispute, UUID> {

    @Query("SELECT d FROM Dispute d WHERE d.match.id = :matchId AND d.state = 'open'")
    Optional<Dispute> findOpenByMatchId(UUID matchId);
}
