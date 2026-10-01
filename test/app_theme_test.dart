import 'package:ajoplus/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('evergreen accents stay consistent and readable in both themes', () {
    for (final brightness in Brightness.values) {
      final scheme = AppTheme.createTheme(brightness).colorScheme;

      expect(
        scheme.primary,
        brightness == Brightness.dark
            ? const Color(0xFF78C7A7)
            : const Color(0xFF176B52),
      );
      expect(
        scheme.onPrimary,
        brightness == Brightness.dark ? const Color(0xFF10231C) : Colors.white,
      );
      expect(
        scheme.secondary,
        brightness == Brightness.dark
            ? const Color(0xFFFFC76A)
            : const Color(0xFF96540F),
      );
      expect(
        _contrast(scheme.primary, scheme.onPrimary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(scheme.secondary, scheme.onSecondary),
        greaterThanOrEqualTo(4.5),
      );
    }
  });
}

double _contrast(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
