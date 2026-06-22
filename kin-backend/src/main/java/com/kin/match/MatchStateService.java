package com.kin.match;

import com.kin.match.dto.DisputeRequest;
import com.kin.notification.Notification;
import com.kin.notification.NotificationRepository;
import com.kin.user.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class MatchStateService {

    private final MatchRepository matchRepository;
    private final ConfirmationRepository confirmationRepository;
    private final DisputeRepository disputeRepository;
    private final NotificationRepository notificationRepository;
    private final EloRecomputeService eloRecomputeService;

    // ---------------------------------------------------------------
    // CONFIRM
    // ---------------------------------------------------------------

    @Transactional
    public void confirm(UUID matchId, User actor) {
        Match match = requireMatch(matchId);
        requireStatus(match, "pending");
        requireNonCreator(match, actor, "Creator cannot confirm their own match");

        Confirmation conf = confirmationRepository.findByMatchIdAndUserId(matchId, actor.getId())
                .orElseThrow(() -> new IllegalArgumentException("You are not a participant of this match"));

        if ("confirmed".equals(conf.getState())) return; // idempotent

        conf.setState("confirmed");
        conf.setActedAt(OffsetDateTime.now());
        confirmationRepository.save(conf);

        notifyCreator(match, actor, "confirm_request",
                Map.of("matchId", matchId.toString(), "action", "confirmed",
                        "by", actor.getFirstName() + " " + actor.getLastName()));

        tryAutoConfirm(match);
    }

    // ---------------------------------------------------------------
    // DISPUTE
    // ---------------------------------------------------------------

    @Transactional
    public UUID dispute(UUID matchId, User actor, DisputeRequest req) {
        Match match = requireMatch(matchId);
        if (!List.of("pending", "disputed").contains(match.getStatus())) {
            throw new IllegalStateException("Match is " + match.getStatus() + " — cannot dispute");
        }
        requireNonCreator(match, actor, "Creator cannot dispute their own match");

        confirmationRepository.findByMatchIdAndUserId(matchId, actor.getId())
                .orElseThrow(() -> new IllegalArgumentException("You are not a participant of this match"));

        if (disputeRepository.findOpenByMatchId(matchId).isPresent()) {
            throw new IllegalStateException("A dispute is already open for this match. Wait for the creator to resolve it first.");
        }

        List<Map<String, Integer>> proposed = req.getProposedSets().stream()
                .map(s -> Map.of("team1Games", s.getTeam1Games(), "team2Games", s.getTeam2Games()))
                .collect(Collectors.toList());

        Dispute dispute = Dispute.builder()
                .match(match)
                .raisedBy(actor)
                .proposedSets(proposed)
                .build();
        disputeRepository.save(dispute);

        match.setStatus("disputed");
        matchRepository.save(match);

        notifyCreator(match, actor, "disputed",
                Map.of("matchId", matchId.toString(), "disputeId", dispute.getId().toString(),
                        "by", actor.getFirstName() + " " + actor.getLastName()));

        return dispute.getId();
    }

    // ---------------------------------------------------------------
    // ACCEPT DISPUTE (creator)
    // ---------------------------------------------------------------

    @Transactional
    public void acceptDispute(UUID matchId, UUID disputeId, User actor) {
        Match match = requireMatch(matchId);
        requireStatus(match, "disputed");
        requireCreator(match, actor);

        Dispute dispute = requireOpenDispute(matchId, disputeId);

        // replace sets with proposed
        match.getSets().clear();
        List<Map<String, Integer>> proposed = dispute.getProposedSets();
        for (int i = 0; i < proposed.size(); i++) {
            Map<String, Integer> s = proposed.get(i);
            match.getSets().add(MatchSet.builder()
                    .match(match)
                    .setNo((short) (i + 1))
                    .team1Games(s.get("team1Games").shortValue())
                    .team2Games(s.get("team2Games").shortValue())
                    .build());
        }

        // recalculate winners from new sets
        long t1Sets = match.getSets().stream().filter(s -> s.getTeam1Games() > s.getTeam2Games()).count();
        long t2Sets = match.getSets().stream().filter(s -> s.getTeam2Games() > s.getTeam1Games()).count();
        boolean team1Wins = t1Sets > t2Sets;
        match.getPlayers().forEach(mp -> mp.setWinner(mp.getTeam() == 1 ? team1Wins : !team1Wins));

        dispute.setState("accepted");
        dispute.setResolvedAt(OffsetDateTime.now());
        disputeRepository.save(dispute);

        confirmToConfirmed(match);
    }

    // ---------------------------------------------------------------
    // REJECT DISPUTE (creator)
    // ---------------------------------------------------------------

    @Transactional
    public void rejectDispute(UUID matchId, UUID disputeId, User actor) {
        Match match = requireMatch(matchId);
        requireStatus(match, "disputed");
        requireCreator(match, actor);

        Dispute dispute = requireOpenDispute(matchId, disputeId);
        dispute.setState("rejected");
        dispute.setResolvedAt(OffsetDateTime.now());
        disputeRepository.save(dispute);
        // match stays disputed — creator must drop or wait for a new correction
    }

    // ---------------------------------------------------------------
    // DROP (creator → expired)
    // ---------------------------------------------------------------

    @Transactional
    public void drop(UUID matchId, User actor) {
        Match match = requireMatch(matchId);
        if (!List.of("pending", "disputed").contains(match.getStatus())) {
            throw new IllegalStateException("Only pending or disputed matches can be dropped");
        }
        requireCreator(match, actor);
        match.setStatus("expired");
        matchRepository.save(match);
    }

    // ---------------------------------------------------------------
    // AUTO-CONFIRM (called by scheduler)
    // ---------------------------------------------------------------

    @Transactional
    public void autoConfirm(Match match) {
        if (!"pending".equals(match.getStatus())) return;
        log.info("Auto-confirming match {}", match.getId());
        confirmToConfirmed(match);
    }

    // ---------------------------------------------------------------
    // Internal helpers
    // ---------------------------------------------------------------

    private void tryAutoConfirm(Match match) {
        List<Confirmation> confs = confirmationRepository.findByMatchId(match.getId());
        boolean allConfirmed = confs.stream().allMatch(c -> "confirmed".equals(c.getState()));
        if (allConfirmed) confirmToConfirmed(match);
    }

    private void confirmToConfirmed(Match match) {
        match.setStatus("confirmed");
        matchRepository.save(match);
        eloRecomputeService.recompute(match);
    }

    private Match requireMatch(UUID matchId) {
        return matchRepository.findById(matchId)
                .orElseThrow(() -> new IllegalArgumentException("Match not found: " + matchId));
    }

    private void requireStatus(Match match, String expected) {
        if (!expected.equals(match.getStatus())) {
            throw new IllegalStateException("Match is " + match.getStatus() + ", expected " + expected);
        }
    }

    private void requireCreator(Match match, User actor) {
        if (!match.getCreatedBy().getId().equals(actor.getId())) {
            throw new IllegalArgumentException("Only the match creator can perform this action");
        }
    }

    private void requireNonCreator(Match match, User actor, String message) {
        if (match.getCreatedBy().getId().equals(actor.getId())) {
            throw new IllegalArgumentException(message);
        }
    }

    private Dispute requireOpenDispute(UUID matchId, UUID disputeId) {
        Dispute dispute = disputeRepository.findById(disputeId)
                .orElseThrow(() -> new IllegalArgumentException("Dispute not found"));
        if (!dispute.getMatch().getId().equals(matchId)) {
            throw new IllegalArgumentException("Dispute does not belong to this match");
        }
        if (!"open".equals(dispute.getState())) {
            throw new IllegalStateException("Dispute is already " + dispute.getState());
        }
        return dispute;
    }

    private void notifyCreator(Match match, User actor, String type, Map<String, Object> payload) {
        notificationRepository.save(Notification.builder()
                .user(match.getCreatedBy())
                .type(type)
                .payload(payload)
                .build());
    }
}
