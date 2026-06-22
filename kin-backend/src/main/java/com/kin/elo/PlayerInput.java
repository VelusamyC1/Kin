package com.kin.elo;

import java.util.UUID;

public record PlayerInput(UUID userId, int elo, boolean isProvisional, int team) {}
