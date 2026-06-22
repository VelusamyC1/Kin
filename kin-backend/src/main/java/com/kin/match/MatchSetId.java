package com.kin.match;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

public class MatchSetId implements Serializable {
    private UUID match;
    private short setNo;

    @Override public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof MatchSetId s)) return false;
        return setNo == s.setNo && Objects.equals(match, s.match);
    }
    @Override public int hashCode() { return Objects.hash(match, setNo); }
}
