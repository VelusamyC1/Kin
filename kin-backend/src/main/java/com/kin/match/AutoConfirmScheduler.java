package com.kin.match;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.OffsetDateTime;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class AutoConfirmScheduler {

    private final MatchRepository matchRepository;
    private final MatchStateService matchStateService;

    @Scheduled(fixedDelay = 300_000) // every 5 minutes
    public void autoConfirmExpired() {
        List<Match> due = matchRepository.findPendingAutoConfirm(OffsetDateTime.now());
        if (due.isEmpty()) return;
        log.info("Auto-confirming {} pending match(es)", due.size());
        due.forEach(matchStateService::autoConfirm);
    }
}
