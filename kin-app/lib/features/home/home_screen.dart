import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import 'home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    final matches = ref.watch(myMatchesProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KIN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => context.push('/notifications')),
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () => context.push('/profile')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(meProvider);
          ref.invalidate(myMatchesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Rating card
            me.when(
              data: (data) {
                final rating = data['rating'] as Map?;
                return Card(
                  color: cs.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${data['firstName']} ${data['lastName']}',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
                        Text('${data['city'] ?? ''}, ${data['country'] ?? ''}',
                            style: TextStyle(color: cs.onPrimaryContainer.withOpacity(0.7))),
                        const SizedBox(height: 16),
                        if (rating != null) ...[
                          Row(children: [
                            _StatChip(label: 'ELO', value: '${rating['elo']}'),
                            const SizedBox(width: 12),
                            _StatChip(label: 'LEVEL', value: '${rating['level']}'),
                            const SizedBox(width: 12),
                            _StatChip(label: 'TIER', value: '${rating['tier']}'),
                          ]),
                          const SizedBox(height: 8),
                          Text('${rating['matchesConfirmed']} confirmed matches',
                              style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer.withOpacity(0.6))),
                        ] else
                          const Text('No rating yet — log your first match!'),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Card(child: Padding(padding: EdgeInsets.all(20), child: LinearProgressIndicator())),
              error: (e, _) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Text('Error: $e'))),
            ),
            const SizedBox(height: 16),

            // Quick actions
            Row(children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.add_circle_outline,
                  label: 'Log Match',
                  onTap: () => context.push('/log-match'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.leaderboard_outlined,
                  label: 'Leaderboard',
                  onTap: () => context.push('/leaderboard'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.show_chart,
                  label: 'History',
                  onTap: () => context.push('/history'),
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // Recent matches
            Text('Recent matches', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            matches.when(
              data: (list) => list.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('No matches yet. Log your first one!')),
                    )
                  : Column(
                      children: list.take(10).map((m) => _MatchTile(match: m)).toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/log-match'),
        icon: const Icon(Icons.add),
        label: const Text('Log Match'),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchTile extends ConsumerWidget {
  const _MatchTile({required this.match});
  final Map<String, dynamic> match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = match['status'] as String? ?? '';
    final statusColor = switch (status) {
      'confirmed' => Colors.green,
      'disputed'  => Colors.orange,
      'expired'   => Colors.grey,
      _           => Colors.blue,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.push('/match/${match['id']}'),
        title: Text('Match · ${match['id'].toString().substring(0, 8)}...'),
        subtitle: Text(match['loggedAt']?.toString().split('T').first ?? ''),
        trailing: Chip(
          label: Text(status.toUpperCase(), style: const TextStyle(fontSize: 11)),
          backgroundColor: statusColor.withOpacity(0.15),
          labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
