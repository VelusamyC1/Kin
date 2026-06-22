package com.kin.match;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

public class MatchPlayerId implements Serializable {
    private UUID match;
    private UUID user;

    @Override public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof MatchPlayerId mp)) return false;
        return Objects.equals(match, mp.match) && Objects.equals(user, mp.user);
    }
    @Override public int hashCode() { return Objects.hash(match, user); }
}
