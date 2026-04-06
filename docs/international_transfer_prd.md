# International Transfer PRD

## 1. Product Name

`International Transfer`

Current alias in the codebase:

- `international_transfer`

## 2. Product Definition

Sarf `International Transfer` is a payout-intake product. The user submits a request to receive an incoming international remittance through a supported provider and exchange house, completes KYC, selects how the payout should be received locally, and tracks the request until completion.

This is different from `Internal Transfer`:

- internal transfer is a merchant-routed local transfer flow
- international transfer is a remittance payout request flow tied to exchange houses, providers, rates, and KYC

## 3. Problem Statement

Sarf needs a structured way to process international remittance payouts without hardcoding exchanges, providers, rates, reference rules, or KYC requirements in the mobile app.

Today the app has a working mock flow, but all core configuration is local to the client. To launch a production-ready product, Sarf needs:

- dynamic exchange and provider catalogs
- provider-specific rate configuration
- provider-specific reference rules
- configurable KYC requirements
- payout destination rules
- auditable order lifecycle and attachments

## 4. Product Goal

Allow an authenticated Sarf user to:

- choose an exchange house
- choose a transfer provider supported by that exchange
- select the transfer currency
- view the estimated local payout using current configured rates
- submit provider reference and KYC details
- choose a local payout method
- track the payout request to completion

## 5. Non-Goals For Phase 1

- direct provider API integrations for live payout confirmation
- automated sanction screening
- OCR-based document extraction
- payout recipient biometric verification
- multi-recipient transfers
- user self-service dispute management

These can be added later, but they should not block the first production API.

## 6. Primary Actors

### Sarf User

The authenticated user requesting payout of an incoming international remittance.

### Exchange House

A Sarf partner that validates the request and executes the payout.

### Transfer Provider

The external remittance source, such as `Wistron Transfer` or `MoneyGram`.

### Operations Agent

A Sarf or partner back-office actor who reviews KYC, verifies references, and updates order status.

## 7. Current Mobile Flow To Preserve

The backend must support the current implemented flow:

1. User chooses exchange house
2. User chooses transfer provider
3. User enters provider reference number
4. User selects source currency
5. User enters transfer amount
6. App shows estimated payout using configured rate
7. User completes KYC:
   - sender full name
   - receiver full name
   - ID document upload
8. User chooses local receive method
9. User enters payout account number
10. User enters payout account holder name
11. User reviews the request
12. User submits payout request
13. Request appears in transaction history

## 8. Functional Requirements

### 8.1 Dynamic Catalog

The system must provide a dynamic catalog for international transfer containing:

- exchange houses
- provider support per exchange
- send currencies per provider and exchange
- exchange rates
- receive methods
- reference rules
- KYC requirements

The mobile app must not hardcode these in production.

### 8.2 Exchange House Selection

The system must return active exchange houses with:

- code
- English and Arabic names
- logo
- notes
- supported providers
- supported receive methods

### 8.3 Provider Selection

The system must allow different providers per exchange house.

Each provider configuration should support:

- provider code
- localized provider name
- logo
- note
- reference requirement
- supported currencies

### 8.4 Rate Discovery

For a chosen exchange house and provider, the system must return:

- supported source currencies
- receive currency
- exchange rate
- update time
- optional note

Rates must be dynamic and versionable.

### 8.5 Reference Rules

Reference behavior must be configurable. The backend should support:

- required or optional reference
- field label
- validation regex if needed
- provider-specific help text

This is necessary because your current sample already shows provider-specific differences.

### 8.6 KYC Requirements

The system must support configurable KYC requirements for international transfer.

Phase 1 minimum requirements from the app:

- sender full name
- receiver full name
- ID document attachment

The schema and API should support future additions such as:

- document type
- document number
- expiry date
- nationality
- sender country

### 8.7 Payout Method Selection

The backend must return payout receive methods with:

- method code
- localized name
- logo
- note
- required input fields

Phase 1 local receive details in the app:

- account number
- account holder name

### 8.8 Quote Or Estimate

The system must produce an estimate or quote that includes:

- send amount
- send currency
- estimated receive amount
- receive currency
- rate
- quote expiry
- exchange house
- provider

### 8.9 Order Submission

The user must be able to submit an international transfer request only after:

- exchange house is selected
- provider is selected
- currency is selected
- amount is valid
- provider reference rules are satisfied
- KYC requirements are satisfied
- payout destination details are complete

### 8.10 Order Tracking

The system must store and expose:

- order reference
- exchange house
- provider
- reference number
- KYC data snapshot
- payout destination snapshot
- rate snapshot
- estimated receive amount
- attachments
- status
- timestamps

### 8.11 Notifications

Users should receive status notifications for events such as:

- request submitted
- under review
- more information required
- ready for payout
- completed
- rejected

### 8.12 Auditability

Every verification step and status transition must be recorded with:

- actor type
- actor id
- previous status
- new status
- reason or note
- timestamp

## 9. Recommended Status Model

The UI currently shows only a subset, but the backend should support a more complete lifecycle.

Recommended statuses:

- `SUBMITTED`
- `UNDER_REVIEW`
- `KYC_PENDING`
- `MORE_INFO_REQUIRED`
- `REFERENCE_VERIFIED`
- `READY_FOR_PAYOUT`
- `PAYOUT_IN_PROGRESS`
- `COMPLETED`
- `REJECTED`
- `CANCELLED`
- `EXPIRED`

The mobile client can collapse these into fewer labels if needed.

## 10. Business Rules

### Required Rules

- exchange house must be active
- provider must be supported by the chosen exchange
- selected currency must be supported by the exchange-provider pair
- amount must be greater than zero
- provider reference must satisfy provider rule
- KYC attachments must exist before submission
- receive method must be supported by the chosen exchange
- order must snapshot the applied rate and payout destination

### Configurable Rules

- amount limits by provider or exchange
- receive methods per exchange
- KYC fields per provider or corridor
- fee policy
- quote TTL
- provider reference regex
- operational SLA per exchange

## 11. UX Requirements Implied By The Current App

The backend response must support these UI blocks:

- exchange selector
- provider selector
- currency selector
- rate and estimated payout card
- KYC document upload card
- receive method selector
- review screen
- history cards with source and destination logos
- detail sheet with attachments

## 12. Success Metrics

Phase 1 suggested metrics:

- submission completion rate
- KYC rejection rate
- average review time
- payout completion time
- request abandonment after rate view
- provider-specific failure rate
- exchange-specific SLA compliance

## 13. Operational Requirements

- exchange and provider catalogs must be editable without app release
- rates must be updateable on a schedule or manually
- attachment storage must be secure
- operators must be able to search by reference number, provider, exchange, phone, and order reference
- notification sending should be asynchronous and retryable

## 14. Open Questions

These need product decisions before production launch:

1. Is the provider reference always unique?
2. Does every provider require the same KYC fields?
3. Is the payout fee always embedded in the rate, or shown separately?
4. Are exchange houses allowed to support different receive methods?
5. Can one request have multiple KYC attachments?
6. Does the exchange need to upload payout proof before completion?
7. Should completion mean payout executed, or recipient confirmed?
8. Are there corridor-specific compliance requirements by country and currency?

## 15. Recommended Phase Sequence

### Phase 1

- dynamic exchange and provider catalog
- dynamic rates
- provider reference rules
- KYC attachment upload
- payout request creation
- order history and detail
- notifications

### Phase 2

- operator review console
- more info required flow
- payout proof upload
- SLA monitoring

### Phase 3

- direct provider integrations
- automated verification checks
- reconciliation and compliance reporting
