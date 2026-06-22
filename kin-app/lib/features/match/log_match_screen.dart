import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';

class LogMatchScreen extends ConsumerStatefulWidget {
  const LogMatchScreen({super.key});

  @override
  ConsumerState<LogMatchScreen> createState() => _LogMatchScreenState();
}

class _LogMatchScreenState extends ConsumerState<LogMatchScreen> {
  // 4 player emails
  final _emails = List.generate(4, (_) => TextEditingController());
  // Up to 3 sets: each set is [team1Games, team2Games]
  final _sets = <List<TextEditingController>>[
    [TextEditingController(text: '6'), TextEditingController(text: '4')],
  ];
  bool _loading = false;
  Map<String, dynamic>? _preview; // predicted elo changes

  @override
  void dispose() {
    for (final c in _emails) c.dispose();
    for (final s in _sets) {
      s[0].dispose();
      s[1].dispose();
    }
    super.dispose();
  }

  void _addSet() {
    if (_sets.length >= 3) return;
    setState(() => _sets.add([TextEditingController(text: '6'), TextEditingController(text: '4')]));
  }

  void _removeSet(int i) {
    if (_sets.length <= 1) return;
    setState(() {
      _sets[i][0].dispose();
      _sets[i][1].dispose();
      _sets.removeAt(i);
    });
  }

  Future<void> _submit() async {
    for (final c in _emails) {
      if (c.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All 4 player emails required')));
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final sets = _sets.map((s) => {
        'team1Games': int.tryParse(s[0].text) ?? 0,
        'team2Games': int.tryParse(s[1].text) ?? 0,
      }).toList();

      final res = await dio.post('/matches', data: {
        'team1Player1Email': _emails[0].text.trim(),
        'team1Player2Email': _emails[1].text.trim(),
        'team2Player1Email': _emails[2].text.trim(),
        'team2Player2Email': _emails[3].text.trim(),
        'sets': sets,
      });
      if (!mounted) return;
      setState(() => _preview = Map<String, dynamic>.from(res.data as Map));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Match')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Team 1
            _sectionHeader('Team 1', Colors.blue),
            _emailField(_emails[0], 'Player 1 email'),
            const SizedBox(height: 8),
            _emailField(_emails[1], 'Player 2 email'),
            const SizedBox(height: 16),

            // Team 2
            _sectionHeader('Team 2', Colors.red),
            _emailField(_emails[2], 'Player 3 email'),
            const SizedBox(height: 8),
            _emailField(_emails[3], 'Player 4 email'),
            const SizedBox(height: 24),

            // Sets
            Row(
              children: [
                const Expanded(child: Text('Sets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                if (_sets.length < 3)
                  TextButton.icon(icon: const Icon(Icons.add, size: 16), label: const Text('Add set'), onPressed: _addSet),
              ],
            ),
            const SizedBox(height: 8),
            ..._sets.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  Text('Set ${i + 1}  ', style: const TextStyle(fontWeight: FontWeight.w500)),
                  Expanded(child: _gamesField(s[0], 'Team 1')),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('–', style: TextStyle(fontSize: 20))),
                  Expanded(child: _gamesField(s[1], 'Team 2')),
                  IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20), onPressed: () => _removeSet(i)),
                ]),
              );
            }),

            const SizedBox(height: 24),

            if (_preview != null) ...[
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Match logged ✓', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 8),
                      Text('Predicted Elo change: ${_preview!['predictedEloChange'] > 0 ? '+' : ''}${_preview!['predictedEloChange']}'),
                      Text('Match ID: ${_preview!['id'].toString().substring(0, 8)}...'),
                      Text('Status: ${_preview!['status']}'),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: () => context.go('/home'), child: const Text('Back to home')),
                    ],
                  ),
                ),
              ),
            ] else
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Log Match'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String label, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color, letterSpacing: 1)),
      );

  Widget _emailField(TextEditingController c, String hint) => TextFormField(
        controller: c,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(labelText: hint, isDense: true),
      );

  Widget _gamesField(TextEditingController c, String hint) => TextFormField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: hint, isDense: true),
        textAlign: TextAlign.center,
      );
}
