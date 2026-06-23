import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _pass.text.isEmpty) return;
    setState(() => _loading = true);
    final ok = await ref.read(authProvider.notifier).login(_email.text.trim(), _pass.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email or password'), backgroundColor: Colors.red),
      );
    }
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
                'Welcome\nback',
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

              // Email
              Text('EMAIL', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: kWhite),
                decoration: const InputDecoration(hintText: 'you@email.com'),
              ),
              const SizedBox(height: 16),

              // Password
              Text('PASSWORD', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _pass,
                obscureText: _obscure,
                style: const TextStyle(color: kWhite),
                decoration: InputDecoration(
                  hintText: 'Your password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Sign in
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kNavy))
                    : const Text('Log in'),
              ),
              const SizedBox(height: 24),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  GestureDetector(
                    onTap: () => context.go('/signup'),
                    child: const Text('Sign up', style: TextStyle(color: kLime, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
