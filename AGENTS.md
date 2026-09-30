# AjoPlus Flutter coding standard

For every Flutter or Dart change, read and apply the repository skill at `.codex/skills/anti-slop-flutter/SKILL.md`. It is the complete user-provided Flutter Anti-Slop skill, stored alongside this project. The rules below summarize its core requirements; the skill is authoritative when more detail is needed.

- Trace the complete affected flow before editing: storage, models, state owner, widgets, navigation, lifecycle, and tests.
- Parse Hive or future API data once at the boundary. Reject malformed required fields instead of coercing them to empty strings or current dates. Keep application code strongly typed.
- Store and calculate money as integer kobo. Display naira only through the `money(int amountKobo)` formatter. Preserve the legacy Hive migration when changing stored models.
- Keep credentials out of domain models and store only salted password hashes. Keep security and platform-specific checks even when simplifying code.
- Use local widget state for ephemeral controls and Provider for data shared across screens. Avoid pass-through layers, generic helpers, unnecessary packages, and one-line widget abstractions.
- Own and dispose controllers where they are created. Keep side effects out of `build`, await important operations, and check `mounted` after genuine asynchronous gaps.
- Preserve behavior and existing app conventions. Add focused tests for behavior changes, run `dart format`, `flutter analyze`, and `flutter test`, then review the diff for unnecessary complexity.

The Laravel backend is a separate project; apply its Laravel conventions there. This file governs the Flutter repository.
