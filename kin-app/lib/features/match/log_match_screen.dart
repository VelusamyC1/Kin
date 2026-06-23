import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

class LogMatchScreen extends ConsumerStatefulWidget {
  const LogMatchScreen({super.key});

  @override
  ConsumerState<LogMatchScreen> createState() => _LogMatchScreenState();
}

class _LogMatchScreenState extends ConsumerState<LogMatchScreen> {
  final _emails = List.generate(4, (_) => TextEditingController());
  final _sets = <List<TextEditingController>>[
    [TextEditingController(text: '6'), TextEditingController(text: '4')],
  ];
  bool _loading = false;
  Map<String, dynamic>? _preview;

  @override
  void dispose() {
    for (final c in _emails) c.dispose();
    for (final s in _sets) { s[0].dispose(); s[1].dispose(); }
    super.dispose();
  }

  void _addSet() {
    if (_sets.length >= 3) return;
    setState(() => _sets.add([TextEditingController(text: '6'), TextEditingController(text: '4')]));
  }

  void _removeSet(int i) {
    if (_sets.length <= 1) return;
    setState(() { _sets[i][0].dispose(); _sets[i][1].dispose(); _sets.removeAt(i); });
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
      final sets = _sets.map((s) => {'team1Games': int.tryParse(s[0].text) ?? 0, 'team2Games': int.tryParse(s[1].text) ?? 0}).toList();
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Match')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionLabel('TEAM 1', kLime),
            const SizedBox(height: 8),
            _emailField(_emails[0], 'Player 1 email'),
            const SizedBox(height: 10),
            _emailField(_emails[1], 'Player 2 email'),
            const SizedBox(height: 24),

            _sectionLabel('TEAM 2', Colors.orangeAccent),
            const SizedBox(height: 8),
            _emailField(_emails[2], 'Player 3 email'),
            const SizedBox(height: 10),
            _emailField(_emails[3], 'Player 4 email'),
            const SizedBox(height: 28),

            Row(
              children: [
                const Expanded(child: Text('SETS', style: TextStyle(color: kLime, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5))),
                if (_sets.length < 3)
                  GestureDetector(
                    onTap: _addSet,
                    child: const Row(children: [Icon(Icons.add, color: kLime, size: 16), SizedBox(width: 4), Text('Add set', style: TextStyle(color: kLime, fontSize: 13))]),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ..._sets.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text('Set ${i + 1}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w500)),
                    const SizedBox(width: 16),
                    Expanded(child: _gamesField(s[0], 'T1')),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('–', style: TextStyle(fontSize: 22, color: Colors.white.withOpacity(0.3))),
                    ),
                    Expanded(child: _gamesField(s[1], 'T2')),
                    IconButton(icon: Icon(Icons.remove_circle_outline, color: Colors.white.withOpacity(0.3), size: 20), onPressed: () => _removeSet(i)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 28),

            if (_preview != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: kLime.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: kLime.withOpacity(0.3))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [Icon(Icons.check_circle, color: kLime, size: 20), SizedBox(width: 8), Text('Match logged', style: TextStyle(color: kLime, fontWeight: FontWeight.w700))]),
                    const SizedBox(height: 12),
                    Text('Predicted Elo: ${(_preview!['predictedEloChange'] as num) > 0 ? '+' : ''}${_preview!['predictedEloChange']}', style: const TextStyle(color: kWhite)),
                    const SizedBox(height: 4),
                    Text('Status: ${_preview!['status']}', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: () => context.go('/home'), child: const Text('Back to home')),
                  ],
                ),
              )
            else
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kNavy))
                    : const Text('Log Match'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) => Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5));

  Widget _emailField(TextEditingController c, String hint) => TextField(
    controller: c,
    keyboardType: TextInputType.emailAddress,
    style: const TextStyle(color: kWhite),
    decoration: InputDecoration(hintText: hint),
  );

  Widget _gamesField(TextEditingController c, String hint) => TextField(
    controller: c,
    keyboardType: TextInputType.number,
    textAlign: TextAlign.center,
    style: const TextStyle(color: kWhite, fontSize: 18, fontWeight: FontWeight.w700),
    decoration: InputDecoration(hintText: hint, contentPadding: const EdgeInsets.symmetric(vertical: 14)),
  );
}
