# Project Memory

## Current Product State

- Main shell now uses 3 tabs only: `Home`, `History`, `More`
- `Rates`, `Calculator`, and the old standalone `Services` tab are removed from the main app shell
- Transfer entry points are now the two cards on the home page:
  - `International Transfer`
  - `Internal Transfer`
- `Transaction history` is the dedicated history page and is reachable from:
  - bottom navigation
  - `View all` in home `Last transactions`

## Home Page

- Home page is now the primary action hub
- The service section shows only 2 cards:
  - International transfer
  - Internal transfer
- `Last transactions` replaces the old `Exchange houses & merchants` block
- Current `Last transactions` design:
  - outer soft card with border and shadow
  - compact transaction rows
  - logo + title + date/time grouped together
  - amount + status grouped on the opposite side
  - amount/status box stays LTR internally even in Arabic
  - small overall row padding
- Home `View all` opens the dedicated transaction history page
- Home top bar includes notifications with unread red badge

## Transfer Module

- Transfer module is still mock-based and structured for later API integration
- Dedicated `Services` tab was removed from navigation, but the internal service selector screen still exists in code
- When transfer flows are opened from home, `P2PExchangePage` is entered with `initialServiceCode` and immediately opens the selected flow

### International Transfer

- Current step order:
  1. Exchange
  2. Details
  3. KYC
  4. Receive
  5. Review
- Current behavior:
  - user chooses exchange first
  - then transfer provider
  - then reference, amount, and currency
  - system calculates estimated payout from mock rates
  - KYC step currently requires sender name, receiver name, and ID document
  - receive step currently requires receive method, account number, and account holder name
  - account holder defaults to receiver name when advancing from KYC

### Local / Internal Transfer

- Local transfer flow remains active and continues to use the merchant-selection flow
- Current local flow path:
  1. choose source method
  2. choose destination method
  3. enter amount
  4. continue to merchants
  5. choose merchant
  6. upload receipt and submit

## Transaction History

- Dedicated history page exists for both local and international transfers
- History top bar follows the same custom app bar family used on home
- Transaction cards were redesigned to match the compact home `Last transactions` style
- Cards remain clickable and open a bottom-sheet details view
- Attachments still support preview in a second bottom sheet
- History is designed around shared order data:
  - source name/logo
  - destination name/logo
  - amounts
  - status
  - attachments

## Notifications

- Dedicated notifications page exists
- Notifications page uses:
  - custom home-style top bar
  - two top tabs: `Unread` and `Read`
  - unread/read counts in the tabs
  - notification cards with title and content
  - bottom-sheet detail view on tap
- Unread count is currently surfaced on home via the top-bar notification badge
- Count color was changed to red
- Notification data is currently mock-based through:
  - `lib/data/models/notification_models.dart`
  - `lib/data/services/notification_service.dart`

## More Page

- More page was redesigned to match the newer top-bar style
- Visible More page items are currently:
  - Language
  - Account
  - Logout
- `About app` and `Contact us` were removed from the visible More page UI
- Some older helper methods still remain in code and should be cleaned later if no longer needed

## Account / Wallet

- Account summary colors were updated to the app brand palette
- Wallet/account overview uses the new brand blue gradient instead of the older teal direction

## Sign-In Page

- Sign-in screen keeps the custom branded header
- Biometric sign-in is no longer a detached bottom footer
- Current biometric UI sits directly under the login card inside the same scroll flow
- Version text is shown in the biometric area
- App version is stored in `lib/core/constants/app_constants.dart`

## Branding And Logos

- Visible app branding uses the current app icon in the header/brand marks
- Transaction, provider, exchange, bank, and wallet visuals now follow this rule:
  - use `logoUrl` when present and loadable
  - fallback to the app icon when missing or failing
- Android launcher/splash icon is expected to come from `assets/images/app_icon.png`

## Localization Status

- Project already has JSON translations under:
  - `assets/translations/en.json`
  - `assets/translations/ar.json`
- `easy_localization` is already wired in `lib/main.dart`
- Auth register/OTP/details already rely more on localization keys
- A large part of the active app still uses direct `_t(en, ar)` strings
- The requested full conversion to JSON-backed localization is still pending and should cover:
  - home
  - history
  - more
  - notifications
  - login
  - transfer flows
  - shared mock services/models that still store direct bilingual text

## Mock Data Direction

- Still mock for now, but should become API-driven later for:
  - transfer services
  - providers
  - exchanges
  - methods
  - rates
  - merchants
  - transaction history
  - notifications
  - receipts / attachments
  - logos

## Important Files

- `lib/presentation/home/home_page.dart`
- `lib/presentation/pages/main_shell_page.dart`
- `lib/presentation/pages/p2p_history_page.dart`
- `lib/presentation/pages/notifications_page.dart`
- `lib/presentation/pages/p2p_exchange_page.dart`
- `lib/presentation/auth/login_page.dart`
- `lib/presentation/home/wallet_page.dart`
- `lib/data/services/p2p_service.dart`
- `lib/data/services/notification_service.dart`
- `lib/data/models/p2p_models.dart`
- `lib/data/models/notification_models.dart`
- `lib/core/constants/app_constants.dart`

## Next Likely Work

- Finish full JSON-based localization and remove direct visible strings from code
- Clean dead helpers left behind in `More`, `Home`, and `Notifications`
- Verify remaining RTL/LTR edge cases after the newer UI changes
- Clean and verify analyzer/build issues after the accumulated screen updates
- Replace more mock labels/data with API-ready models when backend contracts are ready
