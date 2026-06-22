import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _form = GlobalKey<FormState>();
  final _country = TextEditingController();
  final _city = TextEditingController();
  String _hand = 'RIGHT';
  bool _playsTournaments = false;
  int _selfLevel = 3;
  bool _loading = false;

  @override
  void dispose() {
    _country.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/me/onboard', data: {
        'country': _country.text.trim(),
        'city': _city.text.trim(),
        'hand': _hand,
        'playsTournaments': _playsTournaments,
        'selfLevel': _selfLevel,
      });
      if (!mounted) return;
      context.go('/home');
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
      appBar: AppBar(title: const Text('Set up your profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Almost there! Tell us a bit about your game.', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _country,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Country'),
                validator: (v) => v != null && v.isNotEmpty ? null : 'Required',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _city,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (v) => v != null && v.isNotEmpty ? null : 'Required',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _hand,
                decoration: const InputDecoration(labelText: 'Dominant hand'),
                items: const [
                  DropdownMenuItem(value: 'RIGHT', child: Text('Right')),
                  DropdownMenuItem(value: 'LEFT', child: Text('Left')),
                  DropdownMenuItem(value: 'BOTH', child: Text('Both')),
                ],
                onChanged: (v) => setState(() => _hand = v!),
              ),
              const SizedBox(height: 24),
              Text('Self-assessed level: $_selfLevel / 7', style: const TextStyle(fontWeight: FontWeight.w500)),
              Slider(
                value: _selfLevel.toDouble(),
                min: 1,
                max: 7,
                divisions: 6,
                label: '$_selfLevel',
                onChanged: (v) => setState(() => _selfLevel = v.round()),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('I play tournaments'),
                value: _playsTournaments,
                onChanged: (v) => setState(() => _playsTournaments = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Let's play"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
