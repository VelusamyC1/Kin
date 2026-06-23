import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
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
          final initials = '${(data['firstName'] as String? ?? 'U')[0]}${(data['lastName'] as String? ?? '')[0]}';

          return ListView(
            padding: const EdgeInsets.all(28),
            children: [
              // Avatar
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: kLime,
                  child: Text(initials, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: kNavy)),
                ),
              ),
              const SizedBox(height: 16),
              Center(child: Text('${data['firstName']} ${data['lastName']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kWhite))),
              Center(child: Text(data['email'] as String? ?? '', style: TextStyle(color: Colors.white.withOpacity(0.4)))),
              const SizedBox(height: 28),

              // Info rows
              _InfoRow(label: 'Country', value: data['country']?.toString() ?? '—'),
              _InfoRow(label: 'City', value: data['city']?.toString() ?? '—'),
              _InfoRow(label: 'Hand', value: data['hand']?.toString() ?? '—'),
              _InfoRow(label: 'Tournaments', value: data['playsTournaments'] == true ? 'Yes' : 'No'),

              if (rating != null) ...[
                const SizedBox(height: 20),
                Container(height: 1, color: Colors.white.withOpacity(0.08)),
                const SizedBox(height: 20),
                Text('RATING', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _InfoRow(label: 'Elo', value: '${rating['elo']}', valueColor: kLime),
                _InfoRow(label: 'Level', value: '${rating['level']}'),
                _InfoRow(label: 'Tier', value: '${rating['tier']}'),
                _InfoRow(label: 'Matches', value: '${rating['matchesConfirmed']}'),
                _InfoRow(label: 'Status', value: rating['isProvisional'] == true ? 'Provisional' : 'Established'),
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
        loading: () => const Center(child: CircularProgressIndicator(color: kLime)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4))),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor ?? kWhite)),
        ],
      ),
    );
  }
}
