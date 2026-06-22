import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

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
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'global', label: Text('Global')),
                ButtonSegment(value: 'country', label: Text('Country')),
                ButtonSegment(value: 'city', label: Text('City')),
              ],
              selected: {scope},
              onSelectionChanged: (s) => ref.read(_scopeProvider.notifier).state = s.first,
            ),
          ),
        ),
      ),
      body: board.when(
        data: (entries) => entries.isEmpty
            ? const Center(child: Text('No players in this scope yet.'))
            : ListView.builder(
                itemCount: entries.length,
                itemBuilder: (_, i) {
                  final e = entries[i];
                  final rank = e['rank'] as int? ?? i + 1;
                  final isTop3 = rank <= 3;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isTop3 ? _medalColor(rank) : null,
                      child: Text('$rank', style: TextStyle(fontWeight: FontWeight.bold, color: isTop3 ? Colors.white : null)),
                    ),
                    title: Text('${e['firstName']} ${e['lastName']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${e['city'] ?? ''}, ${e['country'] ?? ''}  ·  ${e['tier'] ?? ''}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${e['elo']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        Text('${e['matchesConfirmed']} matches', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Color _medalColor(int rank) => switch (rank) {
        1 => const Color(0xFFFFD700),
        2 => const Color(0xFFC0C0C0),
        _ => const Color(0xFFCD7F32),
      };
}
