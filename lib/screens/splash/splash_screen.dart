import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../onboarding/onboarding_screen.dart';
import '../auth/login_screen.dart';
import '../main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final onboarded = StorageService.prefs.getBool('onboarded') ?? false;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => !onboarded
              ? const OnboardingScreen()
              : auth.user == null
              ? const LoginScreen()
              : const MainShell(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.savings_rounded, size: 70, color: color),
            const SizedBox(height: 16),
            Text(
              'AjoPlus',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text('Save together. Grow together.'),
          ],
        ),
      ),
    );
  }
}
