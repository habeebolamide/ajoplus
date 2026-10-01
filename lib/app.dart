import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/providers.dart';
import 'screens/splash/splash_screen.dart';

class AjoPlusApp extends StatelessWidget {
  const AjoPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().mode;
    final generation = context.watch<AuthProvider>().sessionGeneration;
    return MaterialApp(
      key: ValueKey(generation),
      title: 'AjoPlus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.createTheme(Brightness.light),
      darkTheme: AppTheme.createTheme(Brightness.dark),
      themeMode: theme,
      home: const SplashScreen(),
    );
  }
}
