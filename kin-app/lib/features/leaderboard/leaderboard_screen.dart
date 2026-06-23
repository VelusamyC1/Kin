import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

final _scopeProvider = StateProvider<String>((_) => 'global');

final _leaderboardProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, scope) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/leaderboard', queryParameters: {'scope': scope, 'limit': 50});
  return (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
});

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(_scopeProvider);
    final board = ref.watch(_leaderboardProvider(scope));

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Column(
        children: [
          // Scope selector
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: ['global', 'country', 'city'].map((s) {
                final active = s == scope;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => ref.read(_scopeProvider.notifier).state = s,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: active ? kLime : kDarkCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          s[0].toUpperCase() + s.substring(1),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: active ? kNavy : Colors.white.withOpacity(0.5),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // List
          Expanded(
            child: board.when(
              data: (entries) => entries.isEmpty
                  ? Center(child: Text('No players in this scope', style: TextStyle(color: Colors.white.withOpacity(0.4))))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: entries.length,
                      itemBuilder: (_, i) {
                        final e = entries[i];
                        final rank = e['rank'] as int? ?? i + 1;
                        final isTop3 = rank <= 3;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kDarkCard,
                            borderRadius: BorderRadius.circular(14),
                            border: isTop3 ? Border.all(color: _medalColor(rank).withOpacity(0.3)) : null,
                          ),
                          child: Row(
                            children: [
                              // Rank
                              SizedBox(
                                width: 36,
                                child: isTop3
                                    ? CircleAvatar(radius: 16, backgroundColor: _medalColor(rank), child: Text('$rank', style: const TextStyle(color: kWhite, fontWeight: FontWeight.w800, fontSize: 14)))
                                    : Text('$rank', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 14),
                              // Name
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${e['firstName']} ${e['lastName']}', style: const TextStyle(color: kWhite, fontWeight: FontWeight.w600)),
                                    Text('${e['city'] ?? ''}  ·  ${e['tier'] ?? ''}', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                                  ],
                                ),
                              ),
                              // Elo
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${e['elo']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kLime)),
                                  Text('${e['matchesConfirmed']} matches', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3))),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator(color: kLime)),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }

  Color _medalColor(int rank) => switch (rank) {
        1 => const Color(0xFFFFD700),
        2 => const Color(0xFFC0C0C0),
        _ => const Color(0xFFCD7F32),
      };
}
