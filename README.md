# AjoPlus Mobile App

AjoPlus is a Flutter application for managing Nigerian **ajo/esusu** rotating-savings groups. It lets members create and join groups, track contributions, follow payout rotations, review activity, and receive contribution reminders.

This repository contains the mobile client. The companion Laravel API is maintained separately.

> **Current status:** the app is an offline demo. Data, authentication, and payment outcomes are stored or simulated locally; it does not yet call the backend or move real money.

Monetary records are stored as integer kobo. Naira formatting happens only in the UI. Existing local Hive records are migrated on startup.

## Features

- Local sign-up, sign-in, session restore, and onboarding
- Create or join rotating-savings groups using invite codes
- Daily, weekly, biweekly, and monthly contribution schedules
- Calendar-based due dates: daily today, weekly on Monday, and monthly on the first day of the month
- Contribution tracking, simulated payment results, payouts, and transaction history
- In-app and device reminder support where the platform permits it
- Light, dark, and system theme settings

## Tech stack

- [Flutter](https://flutter.dev/) and Dart
- Provider for application state
- Hive for on-device records
- SharedPreferences for small device settings and session state
- `flutter_local_notifications` for reminder scheduling
- `cryptography` for salted local password hashes

## Prerequisites

- Flutter SDK compatible with Dart `^3.11.0`
- Xcode for iOS builds and/or Android Studio with an Android SDK for Android builds

## Getting started

```sh
git clone https://github.com/habeebolamide/ajoplus.git
cd ajoplus
flutter pub get
flutter run
```

Run code-quality checks with:

```sh
flutter analyze
flutter test
```

## Demo data

On the first launch, AjoPlus creates local demo data. Sign in with:

```text
Email:    demo@ajoplus.local
Password: password123
```

Demo records are seeded once by `StorageService` and persisted in local Hive boxes. Existing plaintext demo credentials are migrated to password hashes on startup. To generate fresh demo data, clear the app's local data or reinstall it.

The app uses sample groups such as **Campus Savers**, **Market Circle**, and **Family Goals**. All payments are simulated and are safe to explore.

## Project structure

```text
lib/
  config/       Theme and app configuration
  models/       Persisted domain models
  providers/    Application state and group workflows
  screens/      Feature-organized Flutter screens
  services/     Local persistence, auth, payments, reminders, and scheduling
  widgets/      Reusable UI components
  utils/        Formatting, validation, and identifier helpers
test/           Unit and widget tests
```

## Coding standard

The complete Flutter Anti-Slop skill is installed at [`.codex/skills/anti-slop-flutter/SKILL.md`](.codex/skills/anti-slop-flutter/SKILL.md). Future Codex sessions should read it before Flutter or Dart changes; [`AGENTS.md`](AGENTS.md) makes that requirement explicit for this repository.

## Contribution scheduling

Contribution due dates are derived from the selected frequency rather than the date demo data was first created:

| Frequency | Due date |
| --- | --- |
| Daily | Today; tomorrow after today's contribution is paid |
| Weekly | Monday; the following Monday after a Monday contribution is paid |
| Biweekly | Every 14 days from the selected group start date |
| Monthly | The first of the month; the following first after that payment is paid |

Payout progression still requires the group organizer to complete a cycle once every member has paid.

## Backend integration

The companion Laravel API is a separate project. This Flutter demo does not yet call it. Keep API URLs, secrets, tokens, and payment-provider credentials out of this repository. Use local environment files (for example, `.env`) that are ignored by Git.

## Security and data handling

- Do not commit `.env` files, signing keys, certificates, or service-account credentials.
- Do not treat the demo authentication or simulated payments as production-ready.
- Replace local-only authentication and payment simulation with audited backend integrations before production use.

## License

No license has been selected yet. Add a `LICENSE` file before distributing or accepting external contributions.
