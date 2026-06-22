package com.kin.leaderboard;

import com.kin.rating.EloUtils;
import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class LeaderboardService {

    private final EntityManager em;

    @Transactional(readOnly = true)
    public List<LeaderboardEntry> leaderboard(String scope, String scopeValue, int limit) {
        int safeLimit = Math.min(limit, 100);

        String whereClause = switch (scope) {
            case "city"    -> "AND u.city    = :scopeValue";
            case "country" -> "AND u.country = :scopeValue";
            default        -> ""; // global
        };

        String sql = """
            SELECT
                ROW_NUMBER() OVER (ORDER BY r.elo DESC) AS rank,
                u.id, u.first_name, u.last_name, u.city, u.country,
                r.elo, r.level, r.matches_confirmed, r.is_provisional
            FROM ratings r
            JOIN users u ON u.id = r.user_id
            WHERE 1=1
            """ + whereClause + """
            ORDER BY r.elo DESC
            LIMIT :limit
            """;

        Query q = em.createNativeQuery(sql);
        q.setParameter("limit", safeLimit);
        if (!whereClause.isEmpty()) q.setParameter("scopeValue", scopeValue);

        @SuppressWarnings("unchecked")
        List<Object[]> rows = q.getResultList();

        return rows.stream().map(r -> new LeaderboardEntry(
                ((Number) r[0]).longValue(),
                UUID.fromString(r[1].toString()),
                (String) r[2],
                (String) r[3],
                (String) r[4],
                (String) r[5],
                ((Number) r[6]).intValue(),
                (BigDecimal) r[7],
                EloUtils.tierFromMatches(((Number) r[8]).intValue()),
                ((Number) r[8]).intValue(),
                (Boolean) r[9]
        )).toList();
    }
}
