package com.kin.notification;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.time.OffsetDateTime;
import java.util.Map;
import java.util.UUID;

@Data
@AllArgsConstructor
public class NotificationDto {
    private UUID id;
    private String type;
    private Map<String, Object> payload;
    private OffsetDateTime readAt;
    private OffsetDateTime createdAt;
}
