package com.kin.match;

import com.kin.elo.EloEngine;
import com.kin.elo.PlayerInput;
import com.kin.elo.SetScore;
import com.kin.notification.Notification;
import com.kin.notification.NotificationRepository;
import com.kin.rating.EloUtils;
import com.kin.rating.Rating;
import com.kin.rating.RatingHistory;
import com.kin.rating.RatingHistoryRepository;
import com.kin.rating.RatingRepository;
import com.kin.user.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class EloRecomputeService {

    private final EloEngine eloEngine;
    private final RatingRepository ratingRepository;
    private final RatingHistoryRepository ratingHistoryRepository;
    private final NotificationRepository notificationRepository;

    @Transactional
    public void recompute(Match match) {
        List<MatchPlayer> matchPlayers = match.getPlayers();
        List<MatchSet> sets = match.getSets();

        List<PlayerInput> inputs = matchPlayers.stream().map(mp -> {
            Rating r = ratingRepository.findByUserId(mp.getUser().getId())
                    .orElseThrow(() -> new IllegalStateException("Rating missing for " + mp.getUser().getId()));
            return new PlayerInput(mp.getUser().getId(), r.getElo(), r.isProvisional(), mp.getTeam());
        }).toList();

        List<SetScore> setScores = sets.stream()
                .map(s -> new SetScore(s.getTeam1Games(), s.getTeam2Games()))
                .toList();

        var changes = eloEngine.compute(inputs, setScores);

        changes.forEach(change -> {
            Rating rating = ratingRepository.findByUserId(change.userId()).orElseThrow();
            int before = rating.getElo();

            rating.setElo(change.eloAfter());
            rating.setLevel(EloUtils.levelFromElo(change.eloAfter()));
            rating.setMatchesConfirmed(rating.getMatchesConfirmed() + 1);
            if (rating.isProvisional() && rating.getMatchesConfirmed() >= 10) {
                rating.setProvisional(false);
            }
            ratingRepository.save(rating);

            ratingHistoryRepository.save(RatingHistory.builder()
                    .userId(change.userId())
                    .matchId(match.getId())
                    .eloBefore(before)
                    .eloAfter(change.eloAfter())
                    .change(change.change())
                    .build());

            User user = matchPlayers.stream()
                    .filter(mp -> mp.getUser().getId().equals(change.userId()))
                    .findFirst().orElseThrow().getUser();

            notificationRepository.save(Notification.builder()
                    .user(user)
                    .type("ranking_updated")
                    .payload(Map.of(
                            "matchId",  match.getId().toString(),
                            "eloBefore", before,
                            "eloAfter",  change.eloAfter(),
                            "change",    change.change()
                    ))
                    .build());
        });

        log.info("Elo recomputed for match {}", match.getId());
    }
}
