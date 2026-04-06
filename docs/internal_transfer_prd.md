# Internal Transfer PRD

## 1. Product Name

`Internal Transfer`

Current aliases in the codebase:

- `local_transfer`
- `Customer P2P Transfer`
- `Internal Transfer`

For backend and product documents, use `internal_transfer` as the canonical product name and keep `local_transfer` as the current client service code until the mobile app is updated.

## 2. Problem Statement

Sarf needs a reliable internal transfer product that lets an authenticated user submit a local transfer request between supported banks and wallets, route that request to an available merchant, upload proof of payment, and track fulfillment until completion.

Today this flow exists only as a mock experience in the app. The catalogs, merchants, quote logic, and order lifecycle must become backend-driven so the product can operate with real partners and auditable state.

## 3. Product Goal

Allow a Sarf user to:

- select a valid local transfer route
- see which merchants can fulfill that route
- receive a fee-aware quote
- pay the selected merchant using the correct source method account
- upload payment proof
- monitor the request until completion

## 4. Non-Goals For Phase 1

- real-time merchant bidding marketplace
- automated bank or wallet reconciliation
- customer-to-customer chat
- automatic payout from Sarf wallet balance
- dispute workflow UI in the mobile app
- multi-step approval workflows for back office

These can be added later, but they should not block the first production API.

## 5. Primary Actors

### Sarf User

The authenticated app user who initiates and tracks the transfer.

### Merchant

A partner who receives the user's payment on a supported source method and fulfills the destination payout.

### Operations Agent

A Sarf back-office or admin actor who reviews receipts, updates statuses, and resolves exceptions.

## 6. Current Mobile Flow To Preserve

The backend must support the flow already implemented in the app:

1. Choose source method
2. Choose destination method
3. Enter amount
4. Load available merchants
5. Show merchant ranking cards
6. Select one merchant
7. Generate quote and payment instructions
8. Show merchant account details for the selected source method
9. Require receipt upload
10. Submit order
11. Show order in history
12. Send notifications as status changes

## 7. Functional Requirements

### 7.1 Service Catalog

The system must provide a dynamic internal transfer catalog that defines:

- active service availability
- source methods
- destination methods
- valid routes
- merchant availability by route
- merchant fee rules

The mobile app must not hardcode which methods or merchants exist in production.

### 7.2 Route Selection

The system must:

- return only valid destination methods for a selected source method
- enforce amount limits per route if configured
- reject invalid route combinations server-side even if a client bypass occurs

### 7.3 Merchant Discovery

For a selected route and amount, the system must return merchants that:

- are active
- support the selected source method
- support the selected route
- are allowed to process the requested amount

Merchant response should include:

- merchant name
- logo
- fee model
- estimated completion window
- rating or quality score if used
- merchant payment account details or a separate endpoint to fetch them

### 7.4 Quote Generation

The quote engine must calculate:

- send amount
- receive amount
- fee amount
- fee currency
- exchange or transfer rate
- payment summary
- destination summary
- quote expiration

For phase 1 internal transfer, the default route rate can be `1:1` when both sides are `SDG`, but the schema should still support route-specific rates in case spreads are introduced later.

### 7.5 Order Submission

The system must allow the user to create an order only after:

- a valid quote exists
- the selected merchant is still eligible
- the quote is not expired
- required receipt upload is complete

Order creation must persist:

- user
- service code
- route
- merchant
- merchant account snapshot
- quote snapshot
- amount snapshot
- uploaded receipt
- current status

### 7.6 Receipt Upload

Receipt upload is mandatory for internal transfer phase 1.

The system must support:

- image upload
- attachment storage metadata
- attachment preview URL or signed URL generation
- attachment type classification

### 7.7 Order Tracking

The system must allow the app to list and view orders with:

- reference number
- status
- created time
- source method
- destination method
- send amount
- receive amount
- fee
- merchant
- receipt attachment

### 7.8 Notifications

Users should receive app notifications for meaningful order events such as:

- order submitted
- order under review
- more info required
- order completed
- order rejected or cancelled

### 7.9 Auditability

Every status transition must be recorded with:

- previous status
- new status
- actor type
- actor id
- note or reason
- timestamp

## 8. Recommended Order Status Model

The current UI only shows a limited subset, but the backend should support a fuller lifecycle.

Recommended status set:

- `DRAFT`
- `QUOTE_READY`
- `PAYMENT_PENDING`
- `RECEIPT_UPLOADED`
- `UNDER_REVIEW`
- `MORE_INFO_REQUIRED`
- `APPROVED`
- `COMPLETED`
- `CANCELLED`
- `REJECTED`
- `EXPIRED`

Mobile phase 1 can map these into simpler display states if needed.

## 9. Business Rules

### Required Rules

- source method and destination method must be a valid active route
- merchant must support the selected source method
- merchant must be active and available
- quote must expire after a configurable TTL
- order amounts must be stored as immutable snapshots
- merchant account details used during checkout must be snapshotted into the order
- receipt upload is required before final submission

### Configurable Rules

- minimum amount
- maximum amount
- fixed fee
- percentage fee
- merchant availability windows
- method availability windows
- per-route activation
- merchant SLA target

## 10. UX Requirements Implied By The Current App

The backend response must support the exact UI building blocks already present:

- method cards with names and logos
- merchant cards with fee text
- merchant completion time labels
- quote summary panel
- merchant payment details section
- receipt upload step
- transaction history cards
- order detail bottom sheet
- notification unread counts

## 11. Success Metrics

Phase 1 suggested product metrics:

- quote-to-order conversion rate
- order completion rate
- average time from submission to completion
- receipt rejection rate
- merchant acceptance or completion rate
- failed order creation rate
- number of support cases per 100 orders

## 12. Operational Requirements

- all catalog changes should be manageable without app release
- status changes should be idempotent and auditable
- attachment storage must support secure retrieval
- admin tools must be able to search by order reference, phone, method, and merchant
- notification sending should be asynchronous and retryable

## 13. Phase 1 API Dependencies

Minimum required backend endpoints:

- internal transfer catalog
- merchant list for route
- quote generation
- attachment upload
- order creation
- order list
- order detail
- notification list

## 14. Open Questions

These need product decisions before production launch:

1. Is the app used by end customers directly, by Sarf agents, or both?
2. Can one merchant support only a source method, or must support be route-specific?
3. Are fees configured per merchant, per route, or both?
4. Do merchants have working-hour availability and temporary pause states?
5. What are the hard amount limits by method and merchant?
6. Is cancellation allowed after receipt upload?
7. Which statuses should trigger push notifications versus in-app only notifications?
8. Does the business require payout confirmation from the recipient?

## 15. Recommended Phase Sequence

### Phase 1

- dynamic catalog
- quote
- receipt upload
- order creation
- order history
- notifications

### Phase 2

- admin review console
- more info required flow
- dispute handling
- merchant performance scoring

### Phase 3

- reconciliation
- payout confirmation
- SLA monitoring dashboards
