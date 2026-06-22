package com.kin.match;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

public class ConfirmationId implements Serializable {
    private UUID match;
    private UUID user;

    @Override public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof ConfirmationId c)) return false;
        return Objects.equals(match, c.match) && Objects.equals(user, c.user);
    }
    @Override public int hashCode() { return Objects.hash(match, user); }
}
