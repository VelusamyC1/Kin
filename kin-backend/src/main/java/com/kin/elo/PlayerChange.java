package com.kin.elo;

import java.util.UUID;

public record PlayerChange(UUID userId, int eloBefore, int change, int eloAfter) {}
