import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

final _matchDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/matches/$id');
  return Map<String, dynamic>.from(res.data as Map);
});

class MatchDetailScreen extends ConsumerStatefulWidget {
  const MatchDetailScreen({super.key, required this.matchId});
  final String matchId;

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  bool _actioning = false;

  Future<void> _confirm() async {
    setState(() => _actioning = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/matches/${widget.matchId}/confirm');
      ref.invalidate(_matchDetailProvider(widget.matchId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _actioning = false);
    }
  }

  Future<void> _dispute() async {
    final sets = await _showDisputeDialog();
    if (sets == null) return;
    setState(() => _actioning = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/matches/${widget.matchId}/dispute', data: {'proposedSets': sets, 'reason': 'Score incorrect'});
      ref.invalidate(_matchDetailProvider(widget.matchId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _actioning = false);
    }
  }

  Future<List<Map<String, int>>?> _showDisputeDialog() async {
    final t1 = TextEditingController(text: '7');
    final t2 = TextEditingController(text: '5');
    return showDialog<List<Map<String, int>>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Propose corrected score'),
        content: Row(children: [
          Expanded(child: TextField(controller: t1, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Team 1'))),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('–')),
          Expanded(child: TextField(controller: t2, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Team 2'))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, [
              {'team1Games': int.tryParse(t1.text) ?? 7, 'team2Games': int.tryParse(t2.text) ?? 5}
            ]),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(_matchDetailProvider(widget.matchId));

    return Scaffold(
      appBar: AppBar(title: const Text('Match Detail')),
      body: detail.when(
        data: (match) {
          final status = match['status'] as String? ?? '';
          final sets = match['sets'] as List? ?? [];
          final players = match['players'] as List? ?? [];
          final statusColor = switch (status) {
            'confirmed' => Colors.green,
            'disputed'  => Colors.orange,
            'expired'   => Colors.grey,
            _           => Colors.blue,
          };

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status chip
              Center(
                child: Chip(
                  label: Text(status.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: statusColor.withOpacity(0.15),
                  labelStyle: TextStyle(color: statusColor),
                ),
              ),
              const SizedBox(height: 16),

              // Sets
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Score', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...sets.asMap().entries.map((e) {
                        final s = e.value as Map;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text('Set ${e.key + 1}  ', style: const TextStyle(color: Colors.grey)),
                              Text('${s['team1Games']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const Text(' – ', style: TextStyle(fontSize: 20)),
                              Text('${s['team2Games']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Players
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Players', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...players.map((p) {
                        final pm = p as Map;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('Team ${pm['teamNumber']}'),
                          subtitle: Text('${pm['userId']}'),
                          trailing: pm['confirmed'] == true
                              ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                              : const Icon(Icons.pending, color: Colors.orange, size: 18),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              if (status == 'pending') ...[
                FilledButton.icon(
                  onPressed: _actioning ? null : _confirm,
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm Result'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _actioning ? null : _dispute,
                  icon: const Icon(Icons.gavel),
                  label: const Text('Dispute Score'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                ),
              ],
              if (status == 'disputed') ...[
                OutlinedButton.icon(
                  onPressed: _actioning ? null : _dispute,
                  icon: const Icon(Icons.gavel),
                  label: const Text('Submit New Dispute'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
