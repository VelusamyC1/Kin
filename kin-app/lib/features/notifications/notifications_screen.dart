import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

final _notificationsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/notifications');
  return (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(_notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notifs.when(
        data: (items) => items.isEmpty
            ? Center(child: Text('No notifications yet', style: TextStyle(color: Colors.white.withOpacity(0.4))))
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final n = items[i];
                  final isRead = n['readAt'] != null;
                  final type = n['type'] as String? ?? '';

                  return Dismissible(
                    key: Key(n['id'].toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(color: kLime.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.done, color: kLime),
                    ),
                    onDismissed: (_) async {
                      final dio = ref.read(dioProvider);
                      await dio.post('/notifications/${n['id']}/read');
                      ref.invalidate(_notificationsProvider);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: kDarkCard, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isRead ? Colors.white.withOpacity(0.05) : kLime.withOpacity(0.15),
                            ),
                            child: Icon(_iconFor(type), size: 18, color: isRead ? Colors.white.withOpacity(0.3) : kLime),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _titleFor(type),
                                  style: TextStyle(
                                    color: kWhite,
                                    fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(n['createdAt']?.toString().split('T').first ?? '', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                              ],
                            ),
                          ),
                          if (!isRead)
                            Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: kLime)),
                        ],
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator(color: kLime)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  IconData _iconFor(String type) => switch (type) {
        'ranking_updated' => Icons.leaderboard,
        'match_confirmed' => Icons.check_circle,
        'match_disputed'  => Icons.gavel,
        _                 => Icons.notifications,
      };

  String _titleFor(String type) => switch (type) {
        'ranking_updated' => 'Your Elo ranking was updated',
        'match_confirmed' => 'Match confirmed',
        'match_disputed'  => 'Match disputed',
        _                 => type,
      };
}
