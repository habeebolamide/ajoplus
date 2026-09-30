# AjoPlus Mobile App — Agent Guide

## Purpose

This repository contains the Flutter client for AjoPlus, a rotating-savings (ajo/esusu) application. It currently operates as an offline demonstration using local persistence and simulated payments.

## Commands

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Run `flutter analyze` and the relevant tests after changing Dart code. Prefer targeted tests during iteration, then run the full test suite when practical.

## Architecture

- `lib/models/`: Serializable domain entities.
- `lib/services/`: Local Hive/SharedPreferences access, simulated auth and payment behavior, notification handling, and group schedule helpers.
- `lib/providers/`: `ChangeNotifier` application state and business workflows.
- `lib/screens/`: Feature-organized user interfaces.
- `lib/widgets/`: Reusable visual components.
- `test/`: Unit and widget tests.

`StorageService` initializes Hive boxes and seeds demo records once. Keep persistence formats backward-compatible when possible.

## Scheduling rules

Use `GroupService.nextContributionDate` for user-facing contribution due dates:

- Daily: today, or tomorrow after today's contribution is paid.
- Weekly: Monday.
- Biweekly: every 14 days from `startDate`.
- Monthly: the first day of the month.

`cycleDate` remains the cycle/payout schedule helper. Do not reintroduce logic that derives contribution due dates solely from the old demo seed date.

## Coding conventions

- Use null-safe Dart and keep analyzer warnings at zero.
- Preserve the existing separation of models, services, providers, screens, and widgets.
- Keep UI copy concise and user-oriented.
- Add or update tests for business-rule changes.
- Never hard-code production credentials, API tokens, signing keys, or payment secrets.

## Git hygiene

Generated Flutter output, IDE metadata, local secrets, signing files, and platform build products belong in `.gitignore`. Commit source, tests, configuration templates, and lockfiles needed for reproducible builds.
