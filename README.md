# Sarf Application

Sarf is a Flutter mobile app for transfer and exchange workflows.  
The current product focuses on a simple user flow with clear entry points from the home page, transaction tracking, notifications, account access, and bilingual support for Arabic and English.

## What The App Includes

- Home page with:
  - `International Transfer`
  - `Internal Transfer`
  - `Last transactions`
- Transaction history page with clickable cards and bottom-sheet details
- Notifications page with `Unread` and `Read` tabs
- More page for:
  - language
  - account
  - logout
- Authentication flow:
  - sign in
  - register
  - OTP verification
  - account details

## Current Navigation

The main app shell currently has 3 tabs:

- `Home`
- `History`
- `More`

Removed from the main shell:

- Rates page
- Calculator page
- Old standalone Services tab

Transfers are now opened directly from the home page.

## Transfer Flows

### International Transfer

Current step order:

1. Exchange
2. Details
3. KYC
4. Receive
5. Review

Current behavior:

- user chooses exchange first
- then transfer provider
- then reference, amount, and currency
- system calculates estimated payout from mock exchange rates
- KYC requires sender name, receiver name, and ID document
- receive step requires method, account number, and account holder name

### Internal Transfer

Current behavior:

1. choose source method
2. choose destination method
3. enter amount
4. continue to merchants
5. choose merchant
6. upload receipt and submit

## Current Product Status

- Main UI is active and usable
- Transfer history and notifications are available
- A lot of the transfer and notification data is still mock-based
- The app is being prepared for future API integration
- Localization is already wired, but full cleanup is still in progress

## Localization

The app uses `easy_localization`.

Translation files:

- `assets/translations/en.json`
- `assets/translations/ar.json`

Important rule for future updates:

- add user-facing text to JSON files
- do not add direct hardcoded visible text in widgets

## Branding And Logos

- The app uses `assets/images/app_icon.png` as the brand fallback image
- If a `logoUrl` exists and loads, it is shown
- If a `logoUrl` is missing or fails, the app icon is shown instead

## Tech Stack

- Flutter
- Firebase Core
- Firebase Crashlytics
- Firebase Messaging
- Google Sign-In
- `easy_localization`
- `flutter_secure_storage`
- `shared_preferences`
- `image_picker`

## Project Structure

```text
lib/
  core/          shared theme, constants, localization, widgets, utilities
  data/          models and services
  presentation/  auth, home, pages, and UI flows
```

Important files:

- `lib/main.dart`
- `lib/presentation/home/home_page.dart`
- `lib/presentation/pages/main_shell_page.dart`
- `lib/presentation/pages/p2p_exchange_page.dart`
- `lib/presentation/pages/p2p_history_page.dart`
- `lib/presentation/pages/notifications_page.dart`
- `lib/presentation/auth/login_page.dart`
- `lib/data/services/p2p_service.dart`
- `lib/data/services/notification_service.dart`

## Run The Project

### Requirements

- Flutter SDK installed
- Android Studio or a connected Android device
- A valid Flutter environment

### Commands

```bash
flutter pub get
flutter run
```

## App Icon

If you change the app icon image, regenerate launcher icons with:

```bash
dart run flutter_launcher_icons
```

Main icon asset:

- `assets/images/app_icon.png`

## Mock Data Sources

Current mock data lives mainly in:

- `lib/data/services/p2p_service.dart`
- `lib/data/services/notification_service.dart`

These files should be the first place to replace when real APIs are connected.

## Next Priorities

- finish full JSON-based localization
- remove remaining direct visible strings from code
- replace more mock data with API-backed data
- clean unused helper methods left behind during UI changes
- verify remaining RTL/LTR edge cases
