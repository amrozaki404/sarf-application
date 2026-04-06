# Sarf Product Overview

## 1. Product Summary

Sarf is a bilingual Flutter mobile app for transfer intake, payout tracking, and customer account access. The current product is centered around two transfer products:

- `International Transfer`
- `Internal Transfer`

The app already includes authentication, a home dashboard, transfer initiation flows, transaction history, notifications, and account/profile access. A large part of the transfer and notification data is still mock-based, so the next backend phase should move service catalogs, quotes, orders, attachments, and notifications to real APIs.

## 2. Current User-Facing Modules

### Authentication and Session

Current implemented capabilities:

- Phone login with password
- OTP-based registration
- Google sign-in
- Device registration data sent to backend:
  - `deviceId`
  - `deviceName`
  - `fcmToken`
- Session persistence with secure storage
- Splash screen that routes the user either to login or the main shell

Current auth endpoints already wired in the app:

- `POST /api/auth/login`
- `POST /api/auth/google`
- `POST /api/registration/request-otp`
- `POST /api/registration/confirm-otp`
- `POST /api/registration/submit`

### Main Shell

The active shell now has 3 tabs only:

- `Home`
- `History`
- `More`

Removed from the active shell:

- Rates
- Calculator
- Standalone Services tab

### Home

Home is the primary action hub. It currently includes:

- App brand mark and user avatar
- Notifications shortcut with unread badge
- Two service entry cards:
  - `International Transfer`
  - `Internal Transfer`
- `Last transactions` preview card
- `View all` shortcut into full transaction history

### Internal Transfer Product

Current internal transfer flow in the app:

1. User selects what the customer has
2. User selects what the customer wants
3. User enters amount
4. User continues to merchant selection
5. User selects a merchant
6. User sees merchant payment details
7. User uploads receipt
8. Order is submitted

Current product characteristics:

- Source and destination methods are catalog-driven
- Merchants are shown after route selection
- Merchant account details vary by source method
- Merchant fee can be percentage-based or fixed
- Receipt upload is mandatory before submission
- Submitted orders appear in history with status tracking

Examples of current method types in mock data:

- Sudanese banks
- Wallets

Examples of current internal transfer methods in mock data:

- `bankak`
- `faisal_bank`
- `onb_bank`
- `mycash_wallet`
- `bravo`

### International Transfer Product

Current international transfer flow in the app:

1. Choose exchange house
2. Choose transfer provider
3. Enter reference number
4. Enter amount and source currency
5. Review estimated payout
6. Complete KYC:
  - sender name
  - receiver name
  - ID document upload
7. Enter receive details:
  - receive method
  - account number
  - account holder name
8. Review
9. Submit payout request

Current product characteristics:

- Exchange selection happens first
- Available providers and currencies depend on the chosen exchange
- Exchange rate is provider-specific
- Receive methods currently reuse the local bank/wallet method catalog
- KYC document is required before submission

Current mock examples:

- Exchange house: `MIG Exchange`
- Providers: `Wistron Transfer`, `MoneyGram`
- Source currencies: `USD`, `SAR`
- Receive currency: `SDG`

### Transaction History

Current capabilities:

- Dedicated history screen
- Reachable from bottom navigation and home `View all`
- Compact transaction cards
- Clickable cards that open bottom-sheet details
- Attachment preview from a second bottom sheet
- Current statuses shown in UI:
  - `UNDER_REVIEW`
  - `COMPLETED`

History data is built around shared order fields:

- service
- source and destination names/logos
- send and receive amounts
- fee
- status
- merchant/exchange name
- created time
- attachments

### Notifications

Current capabilities:

- Dedicated notifications screen
- Two tabs:
  - `Unread`
  - `Read`
- Counts shown in tabs
- Home badge shows unread count
- Notification detail bottom sheet

Current notification categories in mock data:

- `transfer`
- `account`
- `security`
- `promotion`

### More and Account

Current visible items in the More page:

- Language
- Account
- Logout

Account page currently shows:

- account number
- registration type
- first name
- last name
- phone number when available

### Localization

Current state:

- English and Arabic supported
- `easy_localization` is already wired
- Translation JSON files already exist
- Some active screens still use inline bilingual strings

Backend implication:

- service names
- method names
- merchant notes
- notification content
- validation messages

should all eventually come from API-ready localized fields instead of hardcoded widget strings.

## 3. Core Domain Objects

The Sarf backend should treat these as first-class domains:

- `User`
- `UserDevice`
- `TransferService`
- `TransferMethod`
- `TransferRoute`
- `Merchant`
- `MerchantAccount`
- `Quote`
- `Order`
- `OrderAttachment`
- `OrderStatusEvent`
- `Notification`

For international transfer, add:

- `ExchangeHouse`
- `TransferProvider`
- `ProviderRate`
- `ReceiveMethodAvailability`

## 4. What The Backend Must Own Next

The app is already shaped for a backend-driven model. The next phase should move these concerns out of mock services and into APIs:

- service catalog availability
- source and destination method catalogs
- route validation
- merchant availability
- merchant payment accounts
- fee rules
- quote calculation
- order creation
- attachment upload and storage
- transaction history
- notification feed
- localized dynamic content
- partner logos and metadata

## 5. Current Constraints and Gaps

Important product realities from the current codebase:

- transfer catalogs are still mock-based
- history is still backed by in-memory mock orders
- notifications are still mock-based
- international flow has no backend contract yet
- internal transfer flow has no backend contract yet
- not all visible strings are fully JSON-localized yet

## 6. Legacy or Non-Primary Modules Still In Code

These modules still exist in the repository but are no longer first-class in the main app shell:

- market rates
- exchange calculator
- marketplace-style merchant workspace

They should be treated as secondary or legacy unless product direction brings them back into active navigation.

## 7. Recommended Backend-First Work Sequence

Recommended order of execution:

1. Finalize product requirements for `Internal Transfer`
2. Freeze the dynamic service catalog model
3. Define API contracts for:
   - catalog
   - quote
   - create order
   - upload attachment
   - order history
   - notifications
4. Create database schema for transfer domain
5. Integrate internal transfer first
6. Apply the same catalog pattern to international transfer
