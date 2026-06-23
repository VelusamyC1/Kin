import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    if (!mounted) return;
    context.go(token != null ? '/home' : '/landing');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: kNavy,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('kin', style: TextStyle(fontSize: 64, fontWeight: FontWeight.w800, color: kWhite, letterSpacing: -2)),
            SizedBox(height: 8),
            Text('play. rank. rise.', style: TextStyle(fontSize: 14, color: kLime, letterSpacing: 3, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
