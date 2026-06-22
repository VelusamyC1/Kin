package com.kin.match;

import com.kin.elo.EloEngine;
import com.kin.elo.PlayerInput;
import com.kin.elo.SetScore;
import com.kin.match.dto.LogMatchRequest;
import com.kin.match.dto.LogMatchResponse;
import com.kin.match.dto.MatchResponse;
import com.kin.rating.Rating;
import com.kin.rating.RatingRepository;
import com.kin.user.User;
import com.kin.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MatchService {

    private final MatchRepository matchRepository;
    private final ConfirmationRepository confirmationRepository;
    private final UserRepository userRepository;
    private final RatingRepository ratingRepository;
    private final EloEngine eloEngine;

    @Transactional
    public LogMatchResponse logMatch(User creator, LogMatchRequest req) {
        validateParticipants(creator.getId(), req.getPartnerId(), req.getOpponentIds());

        // fetch all 4 users
        List<UUID> allIds = List.of(creator.getId(), req.getPartnerId(),
                req.getOpponentIds().get(0), req.getOpponentIds().get(1));
        Map<UUID, User> users = userRepository.findAllById(allIds)
                .stream().collect(Collectors.toMap(User::getId, u -> u));
        allIds.forEach(id -> {
            if (!users.containsKey(id)) throw new IllegalArgumentException("Player not found: " + id);
        });

        // fetch ratings (need Elo for predicted change)
        Map<UUID, Rating> ratings = ratingRepository.findAllById(allIds)
                .stream().collect(Collectors.toMap(r -> r.getUserId(), r -> r));
        allIds.forEach(id -> {
            if (!ratings.containsKey(id)) throw new IllegalArgumentException(
                    "Player has not completed onboarding: " + id);
        });

        // determine winner from sets
        long team1SetsWon = req.getSets().stream()
                .filter(s -> s.getTeam1Games() > s.getTeam2Games()).count();
        long team2SetsWon = req.getSets().stream()
                .filter(s -> s.getTeam2Games() > s.getTeam1Games()).count();
        if (team1SetsWon == team2SetsWon) throw new IllegalArgumentException("Match cannot end in a draw");
        boolean team1Wins = team1SetsWon > team2SetsWon;

        // build match entity
        OffsetDateTime now = OffsetDateTime.now();
        Match match = Match.builder()
                .createdBy(creator)
                .playedAt(req.getPlayedAt())
                .autoConfirmAt(now.plusHours(48))
                .build();

        // players: creator + partner = team 1, opponents = team 2
        match.getPlayers().add(MatchPlayer.builder().match(match)
                .user(users.get(creator.getId())).team((short) 1).isWinner(team1Wins).build());
        match.getPlayers().add(MatchPlayer.builder().match(match)
                .user(users.get(req.getPartnerId())).team((short) 1).isWinner(team1Wins).build());
        match.getPlayers().add(MatchPlayer.builder().match(match)
                .user(users.get(req.getOpponentIds().get(0))).team((short) 2).isWinner(!team1Wins).build());
        match.getPlayers().add(MatchPlayer.builder().match(match)
                .user(users.get(req.getOpponentIds().get(1))).team((short) 2).isWinner(!team1Wins).build());

        // sets
        for (int i = 0; i < req.getSets().size(); i++) {
            var s = req.getSets().get(i);
            match.getSets().add(MatchSet.builder().match(match)
                    .setNo((short) (i + 1))
                    .team1Games(s.getTeam1Games().shortValue())
                    .team2Games(s.getTeam2Games().shortValue())
                    .build());
        }

        // confirmations: all non-creator participants
        List.of(req.getPartnerId(), req.getOpponentIds().get(0), req.getOpponentIds().get(1))
                .forEach(uid -> match.getConfirmations().add(
                        Confirmation.builder().match(match).user(users.get(uid)).build()));

        matchRepository.save(match);

        // predicted Elo change — read-only, never persisted
        List<PlayerInput> inputs = List.of(
                toInput(creator.getId(), ratings, 1),
                toInput(req.getPartnerId(), ratings, 1),
                toInput(req.getOpponentIds().get(0), ratings, 2),
                toInput(req.getOpponentIds().get(1), ratings, 2)
        );
        List<SetScore> sets = req.getSets().stream()
                .map(s -> new SetScore(s.getTeam1Games(), s.getTeam2Games()))
                .toList();

        Map<UUID, Integer> predicted = eloEngine.compute(inputs, sets).stream()
                .collect(Collectors.toMap(c -> c.userId(), c -> c.change()));

        return new LogMatchResponse(match.getId(), match.getStatus(), predicted);
    }

    private PlayerInput toInput(UUID userId, Map<UUID, Rating> ratings, int team) {
        Rating r = ratings.get(userId);
        return new PlayerInput(userId, r.getElo(), r.isProvisional(), team);
    }

    @Transactional(readOnly = true)
    public Optional<MatchResponse> getMatch(UUID matchId, UUID requestingUserId) {
        return matchRepository.findById(matchId).map(this::toResponse);
    }

    @Transactional(readOnly = true)
    public List<MatchResponse> getMyMatches(UUID userId, String status) {
        return matchRepository.findByPlayerAndStatus(userId, status)
                .stream().map(this::toResponse).toList();
    }

    private MatchResponse toResponse(Match m) {
        var players = m.getPlayers().stream()
                .map(mp -> new MatchResponse.MatchPlayerDto(
                        mp.getUser().getId(),
                        mp.getUser().getFirstName(),
                        mp.getUser().getLastName(),
                        mp.getTeam(),
                        mp.isWinner()))
                .toList();
        var sets = m.getSets().stream()
                .map(s -> new MatchResponse.MatchSetDto(s.getSetNo(), s.getTeam1Games(), s.getTeam2Games()))
                .toList();
        return new MatchResponse(m.getId(), m.getStatus(), m.getPlayedAt(), m.getAutoConfirmAt(), players, sets);
    }

    private void validateParticipants(UUID creatorId, UUID partnerId, List<UUID> opponentIds) {
        Set<UUID> all = new HashSet<>(List.of(creatorId, partnerId,
                opponentIds.get(0), opponentIds.get(1)));
        if (all.size() != 4) throw new IllegalArgumentException("All 4 players must be distinct");
    }
}
