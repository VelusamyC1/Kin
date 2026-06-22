package com.kin.notification;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public interface NotificationRepository extends JpaRepository<Notification, UUID> {

    List<Notification> findByUserIdOrderByCreatedAtDesc(UUID userId);

    @Modifying
    @Transactional
    @Query("UPDATE Notification n SET n.readAt = :now WHERE n.id = :id AND n.user.id = :userId")
    int markRead(UUID id, UUID userId, OffsetDateTime now);
}
