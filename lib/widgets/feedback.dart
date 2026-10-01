import 'package:flutter/material.dart';
import '../services/api_client.dart';

enum FeedbackKind { success, error, warning, info }

String feedbackMessage(Object error) => error is ApiException
    ? error.message
    : error is StateError
    ? error.message
    : 'Something went wrong. Please try again.';

void showError(BuildContext context, Object error) {
  showFeedback(context, feedbackMessage(error), kind: FeedbackKind.error);
}

void showInfo(
  BuildContext context,
  String message, {
  FeedbackKind kind = FeedbackKind.info,
}) {
  showFeedback(context, message, kind: kind);
}

void showFeedback(
  BuildContext context,
  String message, {
  required FeedbackKind kind,
}) {
  final scheme = Theme.of(context).colorScheme;
  final (background, foreground, icon) = switch (kind) {
    FeedbackKind.success => (
      const Color(0xFF166534),
      Colors.white,
      Icons.check_circle_rounded,
    ),
    FeedbackKind.error => (scheme.error, scheme.onError, Icons.error_rounded),
    FeedbackKind.warning => (
      const Color(0xFFFDE68A),
      const Color(0xFF422006),
      Icons.warning_rounded,
    ),
    FeedbackKind.info => (scheme.primary, scheme.onPrimary, Icons.info_rounded),
  };

  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 6,
        duration: const Duration(seconds: 4),
      ),
    );
}

class InlineFormError extends StatelessWidget {
  const InlineFormError({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.error.withValues(alpha: .25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: scheme.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
