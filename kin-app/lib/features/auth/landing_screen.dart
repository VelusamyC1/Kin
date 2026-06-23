import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset('assets/images/splash_bg.jpg', fit: BoxFit.cover),

          // Dark gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  kNavy.withOpacity(0.6),
                  kNavy.withOpacity(0.95),
                ],
                stops: const [0.3, 0.65, 1.0],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 5),

                  // Logo
                  const Text(
                    'kin',
                    style: TextStyle(fontSize: 72, fontWeight: FontWeight.w800, color: kWhite, letterSpacing: -3),
                  ),
                  const SizedBox(height: 12),

                  // Tagline pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: kLime,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'play. rank. rise.',
                      style: TextStyle(color: kNavy, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 3),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    'The global ranking & player network\nfor amateur padel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kWhite.withOpacity(0.85), fontSize: 15, height: 1.5),
                  ),

                  const Spacer(flex: 2),

                  // Join button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/signup'),
                      child: const Text('Join for free'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Log in button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Log in'),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Page indicator dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == 0 ? kWhite : kWhite.withOpacity(0.3),
                      ),
                    )),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
