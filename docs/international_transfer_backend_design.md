# International Transfer Backend Design

## 1. Design Objective

The international transfer backend should let the mobile app render the entire payout request flow dynamically from server data instead of local mock constants.

The design must support:

- exchange houses
- provider support by exchange
- provider-specific rates
- provider-specific reference rules
- configurable KYC requirements
- configurable payout receive methods
- auditable payout requests

## 2. Important Product Assumption

Based on the current app, `international_transfer` is modeled as a payout-intake request:

- the user is not selecting a merchant and uploading a payment receipt
- the user is declaring an incoming remittance and requesting local payout
- the user must submit reference and KYC
- the exchange house executes the payout

This is why the API differs from `internal_transfer`.

## 3. API Envelope

Use the same response envelope style already used by auth:

```json
{
  "responseCode": "0",
  "responseMessage": "Success",
  "data": {},
  "meta": {
    "requestId": "req_01HS...",
    "timestamp": "2026-04-05T11:00:00Z"
  }
}
```

## 4. Recommended Endpoint Map

### Catalog

- `GET /api/v1/international-transfers/catalog`
- `GET /api/v1/international-transfers/exchanges/{exchangeCode}`

### Estimate And Submission

- `POST /api/v1/international-transfers/quotes`
- `POST /api/v1/international-transfers/attachments`
- `POST /api/v1/international-transfers/orders`

### Orders

- `GET /api/v1/international-transfers/orders`
- `GET /api/v1/international-transfers/orders/{orderReference}`

### Notifications

- `GET /api/v1/notifications`
- `POST /api/v1/notifications/{notificationId}/read`

## 5. Dynamic Catalog Response

This is the corrected dynamic version of the international transfer configuration model.

`GET /api/v1/international-transfers/catalog`

```json
{
  "responseCode": "0",
  "responseMessage": "Success",
  "data": {
    "serviceCode": "international_transfer",
    "serviceName": "International Transfer",
    "serviceNameAr": "تحويلات دولية",
    "catalogVersion": 12,
    "quoteTtlSeconds": 300,
    "exchanges": [
      {
        "exchangeCode": "mig",
        "exchangeName": "MIG Exchange",
        "exchangeNameAr": "صرافة MIG",
        "exchangeLogoUrl": "https://scontent.fcai20-6.fna.fb/...",
        "note": null,
        "providers": [
          {
            "providerCode": "wistron_transfer",
            "providerName": "Wistron Transfer",
            "providerNameAr": "ويسترون ترانسفير",
            "providerLogoUrl": "https://play-lh.googleusercontent.com/WEI7",
            "note": "Wistron reference number is required for all transfers.",
            "referenceRule": {
              "required": true,
              "label": "Reference number",
              "labelAr": "رقم المرجع",
              "pattern": null,
              "helpText": "Enter the transfer reference from Wistron."
            },
            "currencies": [
              {
                "currencyCode": "USD",
                "currencyName": "US Dollar",
                "currencyNameAr": "الدولار الأمريكي",
                "receiveCurrencyCode": "SDG",
                "exchangeRate": 2488,
                "note": null,
                "updatedAt": "2026-04-05T09:00:00Z"
              },
              {
                "currencyCode": "SAR",
                "currencyName": "Saudi Riyal",
                "currencyNameAr": "الريال السعودي",
                "receiveCurrencyCode": "SDG",
                "exchangeRate": 663.5,
                "note": "Rates are updated daily at 12 PM UTC.",
                "updatedAt": "2026-04-05T09:00:00Z"
              }
            ]
          },
          {
            "providerCode": "moneygram",
            "providerName": "MoneyGram",
            "providerNameAr": "موني جرام",
            "providerLogoUrl": "https://play-lh.googleusercontent.com/uoo6Vd...",
            "note": "No reference number is needed for MoneyGram transfers.",
            "referenceRule": {
              "required": false,
              "label": "Reference number",
              "labelAr": "رقم المرجع",
              "pattern": null,
              "helpText": "Reference is optional for this provider."
            },
            "currencies": [
              {
                "currencyCode": "USD",
                "currencyName": "US Dollar",
                "currencyNameAr": "الدولار الأمريكي",
                "receiveCurrencyCode": "SDG",
                "exchangeRate": 2480,
                "note": null,
                "updatedAt": "2026-04-05T09:00:00Z"
              }
            ]
          }
        ],
        "receiveMethods": [
          {
            "methodCode": "bank_transfer",
            "methodName": "Bank transfer",
            "methodNameAr": "تحويل بنكي",
            "methodLogoUrl": "https://example.com/bank_logo.png",
            "note": "Account number and holder name are required.",
            "requiredFields": [
              "accountNumber",
              "accountHolderName"
            ]
          },
          {
            "methodCode": "mobile_wallet",
            "methodName": "Mobile wallet",
            "methodNameAr": "محفظة إلكترونية",
            "methodLogoUrl": "https://example.com/wallet_logo.png",
            "note": null,
            "requiredFields": [
              "accountNumber",
              "accountHolderName"
            ]
          }
        ],
        "kycRequirements": [
          {
            "fieldCode": "senderFullName",
            "label": "Sender full name",
            "labelAr": "الاسم الكامل للمرسل",
            "fieldType": "text",
            "required": true
          },
          {
            "fieldCode": "receiverFullName",
            "label": "Receiver full name",
            "labelAr": "الاسم الكامل للمستلم",
            "fieldType": "text",
            "required": true
          },
          {
            "fieldCode": "idDocument",
            "label": "ID document",
            "labelAr": "وثيقة الهوية",
            "fieldType": "attachment",
            "required": true,
            "allowedMimeTypes": [
              "image/jpeg",
              "image/png",
              "application/pdf"
            ]
          }
        ]
      }
    ]
  }
}
```

## 6. Why This Response Shape Is Correct

This shape fixes the issues in the raw example:

- `providers` is an array
- `currencies` is an array under each provider
- `receiveMethods` is an array
- reference rules are first-class instead of implied in a free-text note
- KYC requirements are dynamic

That lets the mobile app change behavior without a release.

## 7. Quote Endpoint

`POST /api/v1/international-transfers/quotes`

Request:

```json
{
  "exchangeCode": "mig",
  "providerCode": "wistron_transfer",
  "sendCurrencyCode": "USD",
  "sendAmount": 120,
  "receiveMethodCode": "bank_transfer"
}
```

Response:

```json
{
  "responseCode": "0",
  "responseMessage": "Success",
  "data": {
    "quoteId": "qt_01HSBR10X3Z4E6P5S1Q9M2N7AA",
    "expiresAt": "2026-04-05T11:05:00Z",
    "exchange": {
      "exchangeCode": "mig",
      "exchangeName": "MIG Exchange"
    },
    "provider": {
      "providerCode": "wistron_transfer",
      "providerName": "Wistron Transfer"
    },
    "sendAmount": 120,
    "sendCurrencyCode": "USD",
    "receiveAmount": 298560,
    "receiveCurrencyCode": "SDG",
    "exchangeRate": 2488,
    "rateLabel": "1 USD = 2,488.00 SDG",
    "receiveMethodCode": "bank_transfer",
    "feeAmount": 0,
    "feeCurrencyCode": "SDG",
    "estimateOnly": true
  }
}
```

## 8. Attachment Upload

`POST /api/v1/international-transfers/attachments`

Use multipart upload for KYC documents.

Response:

```json
{
  "responseCode": "0",
  "responseMessage": "Success",
  "data": {
    "attachmentId": "att_01HSBR6S64D8W0N8A4H9H4YBXY",
    "attachmentType": "kyc_document",
    "fileName": "customer_id_front.jpg",
    "contentType": "image/jpeg",
    "fileSizeBytes": 542111,
    "storageKey": "international-transfer/2026/04/05/att_01HSBR6S64D8W0N8A4H9H4YBXY.jpg",
    "previewUrl": "https://files.example.com/signed/att_01HS..."
  }
}
```

## 9. Create Order

`POST /api/v1/international-transfers/orders`

Request:

```json
{
  "quoteId": "qt_01HSBR10X3Z4E6P5S1Q9M2N7AA",
  "providerReference": "WS-448-909",
  "senderFullName": "Ahmed Ali",
  "receiverFullName": "Mohamed Hassan",
  "receiveMethodCode": "bank_transfer",
  "receiveDetails": {
    "accountNumber": "0912345678",
    "accountHolderName": "Mohamed Hassan"
  },
  "attachmentIds": [
    "att_01HSBR6S64D8W0N8A4H9H4YBXY"
  ]
}
```

Response:

```json
{
  "responseCode": "0",
  "responseMessage": "Success",
  "data": {
    "orderReference": "TRX-20260405-000124",
    "status": "UNDER_REVIEW",
    "serviceCode": "international_transfer",
    "exchangeName": "MIG Exchange",
    "providerName": "Wistron Transfer",
    "providerReference": "WS-448-909",
    "sendAmount": 120,
    "sendCurrencyCode": "USD",
    "receiveAmount": 298560,
    "receiveCurrencyCode": "SDG",
    "exchangeRate": 2488,
    "receiveMethod": {
      "methodCode": "bank_transfer",
      "methodName": "Bank transfer"
    },
    "destinationSummary": "Bank transfer / 0912345678 / Mohamed Hassan",
    "createdAt": "2026-04-05T11:02:00Z",
    "attachments": [
      {
        "attachmentId": "att_01HSBR6S64D8W0N8A4H9H4YBXY",
        "label": "ID document",
        "fileName": "customer_id_front.jpg",
        "previewUrl": "https://files.example.com/signed/att_01HS..."
      }
    ]
  }
}
```

## 10. Orders List

`GET /api/v1/international-transfers/orders?page=1&pageSize=20`

```json
{
  "responseCode": "0",
  "responseMessage": "Success",
  "data": {
    "items": [
      {
        "orderReference": "TRX-20260405-000124",
        "status": "UNDER_REVIEW",
        "serviceCode": "international_transfer",
        "sourceName": "Wistron Transfer",
        "sourceLogoUrl": "https://play-lh.googleusercontent.com/WEI7",
        "destinationName": "MIG Exchange",
        "destinationLogoUrl": "https://scontent.fcai20-6.fna.fb/...",
        "receiveAmount": 298560,
        "receiveCurrencyCode": "SDG",
        "createdAt": "2026-04-05T11:02:00Z"
      }
    ],
    "page": 1,
    "pageSize": 20,
    "totalItems": 1
  }
}
```

## 11. Order Detail

`GET /api/v1/international-transfers/orders/{orderReference}`

This should return:

- order snapshot
- exchange and provider metadata
- reference and KYC snapshot
- receive details snapshot
- attachment list
- status history

## 12. Validation Rules

Server-side validation should enforce:

- exchange exists and is active
- provider is enabled for exchange
- currency is enabled for exchange-provider pair
- amount is within configured limits
- provider reference satisfies rule
- required KYC fields are present
- required attachments are present
- receive method is valid for exchange

## 13. Recommended Notification Events

- `international_transfer_submitted`
- `international_transfer_under_review`
- `international_transfer_more_info_required`
- `international_transfer_ready_for_payout`
- `international_transfer_completed`
- `international_transfer_rejected`

## 14. Recommended Implementation Order

1. catalog endpoint
2. quote endpoint
3. attachment upload
4. order creation
5. order list and detail
6. notifications
7. operator tooling
