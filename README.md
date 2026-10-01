# AjoPlus mobile

AjoPlus is a Flutter client for Nigerian rotating savings groups. Accounts, groups, contributions, payout schedules, transactions, and in-app notifications come from the companion Laravel API. Money is transferred as integer kobo in API requests and responses; the UI formats naira for display.

## Setup

1. Start the Laravel backend in `/Users/mac/Sites/ajoplus-backend` and apply its migrations.
2. Run `flutter pub get`.
3. Run the app with a backend URL ending in `/api/v1/`:

```sh
# iOS simulator
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1/

# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1/
```

Use an HTTPS API URL on physical devices and in release builds. Android permits local HTTP only in debug builds. The release client rejects HTTP and invalid API URLs. Never put a Paystack key or MySQL credential in the Flutter project or a `--dart-define` value.

## Payments and payouts

The app requests a Paystack test checkout from Laravel, opens the hosted checkout in the device browser, and asks Laravel to verify the outcome when the app resumes or the user taps **Check payment status**. A contribution becomes paid only after the backend verifies Paystack's reference, amount in kobo, currency, customer, and test domain. The backend also accepts signed Paystack webhooks. Paystack's test secret belongs only in the backend `.env`.

Once every member has paid, the organizer can prepare a payout. It remains **pending** until the organizer records an external transfer reference after manually settling the recipient. This records the organizer's statement; the app does not initiate a bank transfer.

## Data and security

- Sanctum access and rotating refresh tokens are held in platform secure storage. Unauthorized responses trigger one refresh and one retry; an invalid refresh signs the user out.
- The app does not store group or account data in Hive. On the first upgraded launch, it clears all legacy Hive boxes, including old local users and demo records.
- SharedPreferences holds only device preferences such as theme, onboarding, and reminder choice.
- GET requests retry transient failures. Writes are not automatically repeated. Loading, empty, validation, timeout, network, and malformed-response states are handled at the UI or API boundary.

## Structure

```text
lib/models/       Typed API/domain records
lib/providers/    Shared account and group state
lib/screens/      Feature screens
lib/services/     Authenticated API, parsing, reminders, local preferences
lib/widgets/      Reusable UI
lib/utils/        Money formatting and form validation
test/             API and widget integration tests
```

The Flutter coding standard is [`.codex/skills/anti-slop-flutter/SKILL.md`](.codex/skills/anti-slop-flutter/SKILL.md). [`AGENTS.md`](AGENTS.md) instructs future sessions to read it.

Run `flutter analyze` and `flutter test` before merging changes. A real Paystack checkout requires a configured Paystack test account and an accessible backend webhook URL.
