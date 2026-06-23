import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  bool _loading = false;

  // Step 1 — Name
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();

  // Step 2 — Gender
  String? _gender;

  // Step 3 — Padel level
  int? _levelIndex;
  static const _levels = [
    {'label': 'Beginner', 'range': 'Level 0-1', 'value': 1},
    {'label': 'Beginner Intermediate', 'range': 'Level 1-2', 'value': 2},
    {'label': 'Intermediate', 'range': 'Level 2-3', 'value': 3},
    {'label': 'Intermediate Advanced', 'range': 'Level 3-4', 'value': 4},
    {'label': 'Advanced', 'range': 'Level 4-5', 'value': 5},
    {'label': 'Advanced High', 'range': 'Level 5-6', 'value': 6},
    {'label': 'Elite Professional', 'range': 'Level 6-7', 'value': 7},
  ];

  // Step 4 — Tournament frequency
  String? _tournament;

  // Step 5 — Prior racket sports
  final Set<String> _priorSports = {};

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  bool get _canContinue {
    return switch (_step) {
      0 => _firstName.text.trim().isNotEmpty && _lastName.text.trim().isNotEmpty,
      1 => _gender != null,
      2 => _levelIndex != null,
      3 => _tournament != null,
      4 => _priorSports.isNotEmpty,
      _ => false,
    };
  }

  Future<void> _next() async {
    if (_step < 4) {
      setState(() => _step++);
      return;
    }

    // Final step — submit
    setState(() => _loading = true);
    try {
      final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
      final email = extra?['email'] as String? ?? '';
      final password = extra?['password'] as String? ?? '';

      // 1. Sign up
      final ok = await ref.read(authProvider.notifier).signup(
        email,
        password,
        _firstName.text.trim(),
        _lastName.text.trim(),
      );
      if (!ok || !mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign up failed. Email may already be in use.'), backgroundColor: Colors.red),
        );
        return;
      }

      // 2. Onboard
      final dio = ref.read(dioProvider);
      final levelValue = _levels[_levelIndex!]['value'] as int;
      final playsTournaments = _tournament == 'Yes' || _tournament == 'Sometimes';

      await dio.post('/me/onboard', data: {
        'country': 'Spain',
        'city': 'Madrid',
        'hand': 'RIGHT',
        'playsTournaments': playsTournaments,
        'selfLevel': levelValue,
      });

      if (!mounted) return;

      // Navigate to welcome with the level value
      context.go('/welcome', extra: {
        'firstName': _firstName.text.trim(),
        'level': levelValue,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Progress bar + step counter
              Row(
                children: [
                  Expanded(child: _ProgressBar(current: _step, total: 5)),
                  const SizedBox(width: 12),
                  Text('${_step + 1} / 5', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                ],
              ),
              const SizedBox(height: 32),

              // Step content
              Expanded(
                child: SingleChildScrollView(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildStep(),
                  ),
                ),
              ),

              // Continue / Submit button
              ElevatedButton(
                onPressed: (_canContinue && !_loading) ? _next : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canContinue ? kLime : kLime.withOpacity(0.3),
                  foregroundColor: kNavy,
                ),
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kNavy))
                    : Text(_step == 4 ? 'Submit' : 'Continue'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => _buildNameStep(),
      1 => _buildGenderStep(),
      2 => _buildLevelStep(),
      3 => _buildTournamentStep(),
      4 => _buildSportsStep(),
      _ => const SizedBox(),
    };
  }

  // ─── Step 1: Name ───
  Widget _buildNameStep() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("What's your name?", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kWhite)),
        const SizedBox(height: 10),
        Text('This is how your friends can find you on Kin.', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
        const SizedBox(height: 32),
        Text('FIRST NAME', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _firstName,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: kWhite),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        Text('LAST NAME', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _lastName,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: kWhite),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),
        Text('Your profile is public by default.', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
      ],
    );
  }

  // ─── Step 2: Gender ───
  Widget _buildGenderStep() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("What's your gender?", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kWhite)),
        const SizedBox(height: 10),
        Text(
          "We'll use this to determine which leaderboards you appear on and to help plan mixed doubles.",
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 32),
        ..._buildPillOptions(
          options: ['Man', 'Woman', 'Prefer not to say'],
          selected: _gender,
          onSelect: (v) => setState(() => _gender = v),
        ),
        const SizedBox(height: 24),
        Text('Your gender will not appear on your profile.', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
      ],
    );
  }

  // ─── Step 3: Padel Level ───
  Widget _buildLevelStep() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Let's find out\nyour level!", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kWhite, height: 1.2)),
        const SizedBox(height: 10),
        Text('How would you describe your current padel level?', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
        const SizedBox(height: 4),
        Text("Kin's levels range from 0 – 7 (Pro).", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
        const SizedBox(height: 24),
        ...List.generate(_levels.length, (i) {
          final level = _levels[i];
          final selected = _levelIndex == i;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PillOption(
              label: '${level['label']}',
              subtitle: '${level['range']}',
              selected: selected,
              onTap: () => setState(() => _levelIndex = i),
            ),
          );
        }),
      ],
    );
  }

  // ─── Step 4: Tournament ───
  Widget _buildTournamentStep() {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Do you play competitive\ntournaments regularly?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kWhite, height: 1.2)),
        const SizedBox(height: 32),
        ..._buildPillOptions(
          options: ['Not yet', 'Sometimes', 'Yes'],
          selected: _tournament,
          onSelect: (v) => setState(() => _tournament = v),
        ),
      ],
    );
  }

  // ─── Step 5: Prior Sports ───
  Widget _buildSportsStep() {
    final sports = ['Tennis · club or competitive level', 'Squash', 'Badminton', 'None of the above'];
    return Column(
      key: const ValueKey(4),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Have you played\nthese before?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kWhite, height: 1.2)),
        const SizedBox(height: 32),
        ...sports.map((s) {
          final selected = _priorSports.contains(s);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PillOption(
              label: s,
              selected: selected,
              onTap: () {
                setState(() {
                  if (s == 'None of the above') {
                    _priorSports.clear();
                    _priorSports.add(s);
                  } else {
                    _priorSports.remove('None of the above');
                    selected ? _priorSports.remove(s) : _priorSports.add(s);
                  }
                });
              },
            ),
          );
        }),
      ],
    );
  }

  List<Widget> _buildPillOptions({
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    return options.map((o) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _PillOption(
        label: o,
        selected: o == selected,
        onTap: () => onSelect(o),
      ),
    )).toList();
  }
}

// ─── Reusable widgets ───

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) => Expanded(
        child: Container(
          height: 4,
          margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
          decoration: BoxDecoration(
            color: i <= current ? kLime : Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      )),
    );
  }
}

class _PillOption extends StatelessWidget {
  const _PillOption({required this.label, this.subtitle, required this.selected, required this.onTap});
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? kWhite : kDarkCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? kNavy : kWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: selected ? kNavy.withOpacity(0.5) : Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: kNavy),
                child: const Icon(Icons.check, color: kWhite, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}
