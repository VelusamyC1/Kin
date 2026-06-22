package com.kin.match;

import com.kin.user.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Entity
@Table(name = "disputes")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Dispute {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "match_id", nullable = false)
    private Match match;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "raised_by", nullable = false)
    private User raisedBy;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "proposed_sets", nullable = false, columnDefinition = "jsonb")
    private List<Map<String, Integer>> proposedSets;

    @Builder.Default
    @Column(nullable = false)
    private String state = "open";

    @Column(name = "resolved_at")
    private OffsetDateTime resolvedAt;
}
