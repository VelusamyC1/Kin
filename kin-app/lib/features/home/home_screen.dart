import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';
import 'home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    final matches = ref.watch(myMatchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('kin', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -1)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => context.push('/notifications')),
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () => context.push('/profile')),
        ],
      ),
      body: RefreshIndicator(
        color: kLime,
        onRefresh: () async {
          ref.invalidate(meProvider);
          ref.invalidate(myMatchesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Rating card
            me.when(
              data: (data) {
                final rating = data['rating'] as Map?;
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: kDarkCard, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data['firstName']} ${data['lastName']}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kWhite),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data['city'] ?? ''}, ${data['country'] ?? ''}',
                        style: TextStyle(color: Colors.white.withOpacity(0.4)),
                      ),
                      const SizedBox(height: 20),
                      if (rating != null) ...[
                        Row(
                          children: [
                            _StatBlock(label: 'ELO', value: '${rating['elo']}'),
                            const SizedBox(width: 24),
                            _StatBlock(label: 'LEVEL', value: '${rating['level']}'),
                            const SizedBox(width: 24),
                            _StatBlock(label: 'TIER', value: '${rating['tier']}'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${rating['matchesConfirmed']} confirmed matches',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3)),
                        ),
                      ] else
                        const Text('No rating yet — log your first match!', style: TextStyle(color: kLime)),
                    ],
                  ),
                );
              },
              loading: () => Container(
                height: 140,
                decoration: BoxDecoration(color: kDarkCard, borderRadius: BorderRadius.circular(20)),
                child: const Center(child: CircularProgressIndicator(color: kLime)),
              ),
              error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 20),

            // Quick actions
            Row(
              children: [
                Expanded(child: _ActionTile(icon: Icons.add_circle_outline, label: 'Log Match', onTap: () => context.push('/log-match'))),
                const SizedBox(width: 12),
                Expanded(child: _ActionTile(icon: Icons.leaderboard_outlined, label: 'Leaderboard', onTap: () => context.push('/leaderboard'))),
                const SizedBox(width: 12),
                Expanded(child: _ActionTile(icon: Icons.show_chart, label: 'History', onTap: () => context.push('/history'))),
              ],
            ),
            const SizedBox(height: 28),

            // Recent matches
            const Text('Recent matches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kWhite)),
            const SizedBox(height: 12),
            matches.when(
              data: (list) => list.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('No matches yet', style: TextStyle(color: Colors.white.withOpacity(0.4)))),
                    )
                  : Column(children: list.take(10).map((m) => _MatchCard(match: m)).toList()),
              loading: () => const Center(child: CircularProgressIndicator(color: kLime)),
              error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/log-match'),
        backgroundColor: kLime,
        foregroundColor: kNavy,
        icon: const Icon(Icons.add),
        label: const Text('Log Match', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: Colors.white.withOpacity(0.4))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kWhite)),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: kDarkCard, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(icon, color: kLime, size: 26),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: kWhite, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});
  final Map<String, dynamic> match;

  @override
  Widget build(BuildContext context) {
    final status = match['status'] as String? ?? '';
    final statusColor = switch (status) {
      'confirmed' => Colors.green,
      'disputed'  => Colors.orange,
      'expired'   => Colors.grey,
      _           => kLime,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => context.push('/match/${match['id']}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: kDarkCard, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Match · ${match['id'].toString().substring(0, 8)}...', style: const TextStyle(color: kWhite, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(match['loggedAt']?.toString().split('T').first ?? '', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
