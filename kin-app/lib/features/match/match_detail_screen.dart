import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

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

  Future<List<Map<String, int>>?> _showDisputeDialog() {
    final t1 = TextEditingController(text: '7');
    final t2 = TextEditingController(text: '5');
    return showDialog<List<Map<String, int>>>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kDarkCard,
        title: const Text('Propose corrected score', style: TextStyle(color: kWhite)),
        content: Row(children: [
          Expanded(child: TextField(controller: t1, keyboardType: TextInputType.number, style: const TextStyle(color: kWhite), decoration: const InputDecoration(labelText: 'Team 1'))),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('–', style: TextStyle(color: kWhite, fontSize: 20))),
          Expanded(child: TextField(controller: t2, keyboardType: TextInputType.number, style: const TextStyle(color: kWhite), decoration: const InputDecoration(labelText: 'Team 2'))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5)))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, [{'team1Games': int.tryParse(t1.text) ?? 7, 'team2Games': int.tryParse(t2.text) ?? 5}]),
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
            _           => kLime,
          };

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 24),

              // Sets
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: kDarkCard, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SCORE', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    ...sets.asMap().entries.map((e) {
                      final s = e.value as Map;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          Text('Set ${e.key + 1}  ', style: TextStyle(color: Colors.white.withOpacity(0.4))),
                          Text('${s['team1Games']}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kWhite)),
                          Text(' – ', style: TextStyle(fontSize: 28, color: Colors.white.withOpacity(0.3))),
                          Text('${s['team2Games']}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kWhite)),
                        ]),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Players
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: kDarkCard, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PLAYERS', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    ...players.map((p) {
                      final pm = p as Map;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          Expanded(child: Text('Team ${pm['teamNumber']}', style: const TextStyle(color: kWhite, fontWeight: FontWeight.w500))),
                          pm['confirmed'] == true
                              ? const Icon(Icons.check_circle, color: kLime, size: 18)
                              : Icon(Icons.pending, color: Colors.white.withOpacity(0.3), size: 18),
                        ]),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              if (status == 'pending' || status == 'disputed') ...[
                if (status == 'pending')
                  ElevatedButton.icon(
                    onPressed: _actioning ? null : _confirm,
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm Result'),
                  ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _actioning ? null : _dispute,
                  icon: const Icon(Icons.gavel, color: Colors.orange),
                  label: const Text('Dispute Score'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange)),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: kLime)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}
