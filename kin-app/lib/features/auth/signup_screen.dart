import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import 'auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || !_email.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email')),
      );
      return;
    }
    setState(() => _loading = true);
    // Signup happens after onboarding collects name — store email/pass temporarily
    // and navigate to onboarding flow
    if (!mounted) return;
    context.go('/onboarding', extra: {'email': _email.text.trim(), 'password': _pass.text});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              const Text(
                'Create an\naccount',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: kWhite, height: 1.2),
              ),
              const SizedBox(height: 32),

              // Apple button
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.apple, color: kWhite, size: 22),
                label: const Text('Continue with Apple'),
              ),
              const SizedBox(height: 12),

              // Google button
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Text('G', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 24),

              // OR divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
                ],
              ),
              const SizedBox(height: 24),

              // Email label
              Text('EMAIL', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: kWhite),
                decoration: const InputDecoration(hintText: 'you@email.com'),
              ),
              const SizedBox(height: 16),

              // Password label
              Text('PASSWORD', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _pass,
                obscureText: true,
                style: const TextStyle(color: kWhite),
                decoration: const InputDecoration(hintText: 'Min 8 characters'),
              ),
              const SizedBox(height: 28),

              // Sign up button
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kNavy))
                    : const Text('Sign up'),
              ),
              const SizedBox(height: 24),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already on Kin? ', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text('Log in', style: TextStyle(color: kLime, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Legal
              Text(
                'By signing up, you agree to our Terms and Privacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
