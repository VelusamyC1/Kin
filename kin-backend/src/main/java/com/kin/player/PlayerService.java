package com.kin.player;

import com.kin.rating.EloUtils;
import com.kin.user.User;
import com.kin.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PlayerService {

    private final UserRepository userRepository;
    private final PlayerRatingRepository playerRatingRepository;

    public List<PlayerResponse> search(String query, int limit, int offset, UUID excludeUserId) {
        int safeLimit = Math.min(limit, 50);
        PageRequest page = PageRequest.of(0, safeLimit + offset);

        List<User> users = (query == null || query.isBlank())
                ? userRepository.findAllByOrderByFirstNameAsc(page)
                : userRepository.findByNameContaining(query.trim(), page);

        return users.stream()
                .filter(u -> !u.getId().equals(excludeUserId))
                .skip(offset)
                .limit(safeLimit)
                .map(u -> {
                    var rating = playerRatingRepository.findByUserId(u.getId()).orElse(null);
                    return new PlayerResponse(
                            u.getId(),
                            u.getFirstName(),
                            u.getLastName(),
                            u.getCity(),
                            u.getCountry(),
                            rating != null ? rating.getElo() : null,
                            rating != null ? rating.getLevel() : null,
                            rating != null ? EloUtils.tierFromMatches(rating.getMatchesConfirmed()) : null
                    );
                })
                .toList();
    }
}
