import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

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
            ? const Center(child: Text('No notifications yet.'))
            : ListView.builder(
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
                      color: Colors.blue,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.done, color: Colors.white),
                    ),
                    onDismissed: (_) async {
                      final dio = ref.read(dioProvider);
                      await dio.post('/notifications/${n['id']}/read');
                      ref.invalidate(_notificationsProvider);
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isRead ? Colors.grey.shade100 : Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          _iconFor(type),
                          size: 20,
                          color: isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        _titleFor(type),
                        style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                      ),
                      subtitle: Text(n['createdAt']?.toString().split('T').first ?? ''),
                      trailing: isRead ? null : const Icon(Icons.circle, size: 8, color: Colors.blue),
                      onTap: () async {
                        if (!isRead) {
                          final dio = ref.read(dioProvider);
                          await dio.post('/notifications/${n['id']}/read');
                          ref.invalidate(_notificationsProvider);
                        }
                      },
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
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
