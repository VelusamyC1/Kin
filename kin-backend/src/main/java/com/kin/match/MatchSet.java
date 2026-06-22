package com.kin.match;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "match_sets")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@IdClass(MatchSetId.class)
public class MatchSet {

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "match_id")
    private Match match;

    @Id
    @Column(name = "set_no")
    private short setNo;

    @Column(name = "team1_games", nullable = false)
    private short team1Games;

    @Column(name = "team2_games", nullable = false)
    private short team2Games;
}
