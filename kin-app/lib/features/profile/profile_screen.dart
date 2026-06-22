import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import '../home/home_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (!context.mounted) return;
              context.go('/login');
            },
          ),
        ],
      ),
      body: me.when(
        data: (data) {
          final rating = data['rating'] as Map?;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  '${(data['firstName'] as String? ?? 'U')[0]}${(data['lastName'] as String? ?? '')[0]}',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '${data['firstName']} ${data['lastName']}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              Center(child: Text(data['email'] as String? ?? '', style: const TextStyle(color: Colors.grey))),
              const SizedBox(height: 24),

              _InfoTile(label: 'Country', value: data['country']?.toString() ?? '—'),
              _InfoTile(label: 'City', value: data['city']?.toString() ?? '—'),
              _InfoTile(label: 'Hand', value: data['hand']?.toString() ?? '—'),
              _InfoTile(label: 'Tournaments', value: data['playsTournaments'] == true ? 'Yes' : 'No'),

              if (rating != null) ...[
                const Divider(height: 32),
                const Text('Rating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _InfoTile(label: 'Elo', value: '${rating['elo']}'),
                _InfoTile(label: 'Level', value: '${rating['level']}'),
                _InfoTile(label: 'Tier', value: '${rating['tier']}'),
                _InfoTile(label: 'Matches Confirmed', value: '${rating['matchesConfirmed']}'),
                _InfoTile(label: 'Status', value: rating['isProvisional'] == true ? 'Provisional (< 5 matches)' : 'Established'),
              ],

              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () => context.push('/history'),
                icon: const Icon(Icons.show_chart),
                label: const Text('View Elo History'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
