# AjoPlus mobile

AjoPlus is a Flutter client for Nigerian rotating and fixed-period savings groups. Accounts, groups, contributions, payout schedules, transactions, and in-app notifications come from the companion Laravel API. Money is transferred as integer kobo in API requests and responses; the UI formats naira for display.

## Setup

1. Start the Laravel backend in `/Users/mac/Sites/ajoplus-backend` and apply its migrations.
2. Set the backend URL in [`lib/config/api_config.dart`](lib/config/api_config.dart). Keep the URL ending in `/api/v1/`.
3. Run `flutter pub get`, then launch the app normally from your IDE or with `flutter run`. You can override the file URL per build with `--dart-define=API_BASE_URL=https://your-api.example/api/v1/`.

The default is `http://ajoplus-backend.test/api/v1/`, suitable when the local `.test` domain resolves from the simulator/device. If you use `php artisan serve`, set `http://127.0.0.1:8000/api/v1/` for the iOS simulator or `http://10.0.2.2:8000/api/v1/` for the Android emulator. Use an HTTPS URL for physical devices and release builds. The app permits HTTP only in debug builds. Never put a Paystack key or MySQL credential in the Flutter project.

## Payments and payouts

The app requests a Paystack test checkout from Laravel, opens the hosted checkout in the device browser, and asks Laravel to verify the outcome when the app resumes or the user taps **Check payment status**. A contribution becomes paid only after the backend verifies Paystack's reference, amount in kobo, currency, customer, and test domain. The backend also accepts signed Paystack webhooks. Paystack's test secret belongs only in the backend `.env`.

Group creation offers **Rotating Ajo** and **Savings Ajo**. Existing groups remain rotating.

- **Rotating Ajo:** one member receives the collected pool each cycle. The number of cycles equals the number of members.
- **Savings Ajo:** choose 1–365 contribution periods independently of the member count. The organizer completes each fully paid cycle without releasing funds. Repayment becomes available after the chosen number of full periods from the start date (six monthly contributions means repayment six months after the start date). Each member receives their own accumulated contributions, and the group completes only after every repayment is recorded.

For rotating groups, once every member has paid, the organizer can prepare a payout. It remains **pending** until the organizer records an external transfer reference after manually settling the recipient. Savings repayments also require a separate external transfer reference for each member. This records the organizer's statement; the app does not initiate a bank transfer.

## Data and security

- Sanctum access and rotating refresh tokens are held in platform secure storage. Unauthorized responses trigger one refresh and one retry; an invalid refresh signs the user out.
- The app reads group and account data from the API. Legacy Hive records are left intact on existing installations but are never loaded into the live UI. The old local session is removed on upgrade.
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
