import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final firstName = extra?['firstName'] as String? ?? 'Player';
    final level = extra?['level'] as int? ?? 3;
    final provisionalLevel = (level * 0.75).toStringAsFixed(2);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset('assets/images/splash_bg.jpg', fit: BoxFit.cover),

          // Dark overlay
          Container(color: kNavy.withOpacity(0.75)),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Heading
                  Text(
                    "$firstName,\nyou're in!",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: kWhite, height: 1.2),
                  ),
                  const SizedBox(height: 40),

                  // Level circle
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CustomPaint(
                      painter: _LevelArcPainter(level / 7.0),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              provisionalLevel,
                              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: kWhite),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PROVISIONAL LEVEL',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.5), letterSpacing: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Body text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      "Now it's time to build your real ranking. Log matches, confirm results and become part of the fastest-growing padel community.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, height: 1.6),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Enter button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Enter Kin'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelArcPainter extends CustomPainter {
  _LevelArcPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      math.pi * 1.5,
      false,
      bgPaint,
    );

    // Progress arc
    final fgPaint = Paint()
      ..color = kLime
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      math.pi * 1.5 * progress,
      false,
      fgPaint,
    );

    // Dots along the arc
    final dotPaint = Paint()..color = kLime.withOpacity(0.3);
    final dotCount = 24;
    for (int i = 0; i <= dotCount; i++) {
      final angle = -math.pi * 0.75 + (math.pi * 1.5 * i / dotCount);
      final dx = center.dx + radius * math.cos(angle);
      final dy = center.dy + radius * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), 1.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LevelArcPainter old) => old.progress != progress;
}
