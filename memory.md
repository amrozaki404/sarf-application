# Project Memory

## Current Focus

- Transfer module inside `Sarf-App`
- Keep `Local Transfer` flow and logic working
- Build `International Transfer` as a guided multi-step flow
- Keep everything mock-based for now, but structure it for future API integration

## International Transfer Flow

Current step order:

1. Exchange
2. Details
3. KYC
4. Receive
5. Review

Current behavior:

- User chooses exchange first
- Then chooses transfer provider
- Then enters transfer reference, amount, and currency
- System calculates received amount from mock exchange rates
- KYC step currently requires:
  - sender full name
  - receiver full name
  - ID document
- Receive step currently requires:
  - receive method
  - account number
  - account holder name
- Account holder name defaults to receiver name if empty when moving from KYC to Receive

## Transaction History

- Dedicated history page exists for transactions
- Designed to work for both local and international transfers without explicitly showing transfer type as a headline
- Uses shared order data structure for:
  - source name/logo
  - destination name/logo
  - amounts
  - status
  - attachments
- Supports bottom-sheet details
- Supports image preview for attachments

## Mock Data Direction

Still mock for now, but should become API-driven later for:

- exchanges
- transfer providers
- currencies
- rates
- receive methods
- transaction history
- receipts / attachments
- logos

## Important UI Direction

- Use bottom sheets instead of dropdowns where possible
- Show logos for providers, exchanges, banks, and wallets
- Keep compact first-level transaction cards with only primary information
- Put deeper details inside bottom-sheet detail views
- Reuse image-preview behavior anywhere receipts or documents appear

## Files Involved

- `lib/presentation/pages/p2p_exchange_page.dart`
- `lib/presentation/pages/p2p_history_page.dart`
- `lib/data/models/p2p_models.dart`
- `lib/data/services/p2p_service.dart`

## Next Likely Work

- Replace remaining mock labels/data with API-ready models
- Clean and verify analyzer issues after flow changes
- Refine transaction details layout if needed
- Add stronger receive-method handling for international payouts
