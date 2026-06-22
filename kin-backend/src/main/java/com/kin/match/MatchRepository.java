package com.kin.match;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public interface MatchRepository extends JpaRepository<Match, UUID> {

    @Query("""
        SELECT m FROM Match m
        WHERE m.status = 'pending'
          AND m.autoConfirmAt <= :now
        """)
    List<Match> findPendingAutoConfirm(OffsetDateTime now);

    @Query("""
        SELECT DISTINCT m FROM Match m
        JOIN m.players mp
        WHERE mp.user.id = :userId
          AND (:status = 'all' OR m.status = :status)
        ORDER BY m.playedAt DESC
        """)
    List<Match> findByPlayerAndStatus(UUID userId, String status);
}
