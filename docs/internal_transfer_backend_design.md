# Internal Transfer Backend Design

## 1. Design Principles

The backend should be:

- dynamic: catalogs and rules come from the database, not app releases
- normalized: avoid storing rate, merchant, and method logic only in nested JSON
- localized: API can serve English and Arabic labels
- auditable: quotes, orders, attachments, and status changes are persisted
- snapshot-safe: orders keep the exact data used at submission time

## 2. API Envelope

The current auth backend already uses `responseCode` and `responseMessage`. To stay consistent with the app, use the same envelope for new transfer APIs.

Recommended success envelope:

```json
{
  "responseCode": "0",
  "responseMessage": "Success",
  "data": {},
  "meta": {
    "requestId": "req_01HS...",
    "timestamp": "2026-04-05T10:30:00Z"
  }
}
```

Recommended validation error:

```json
{
  "responseCode": "422",
  "responseMessage": "Invalid source method for selected route",
  "errors": [
    {
      "field": "fromMethodCode",
      "message": "Method is not valid for the selected route"
    }
  ]
}
```

## 3. Recommended Endpoint Map

### Shared Catalog

- `GET /api/v1/catalog/services`
- `GET /api/v1/catalog/services/{serviceCode}`

### Internal Transfer

- `GET /api/v1/internal-transfers/catalog`
- `GET /api/v1/internal-transfers/routes?fromMethodCode=bankak`
- `GET /api/v1/internal-transfers/merchants?fromMethodCode=bankak&toMethodCode=bravo&amount=150000`
- `POST /api/v1/internal-transfers/quotes`
- `POST /api/v1/internal-transfers/attachments`
- `POST /api/v1/internal-transfers/orders`
- `GET /api/v1/internal-transfers/orders`
- `GET /api/v1/internal-transfers/orders/{orderReference}`

### Notifications

- `GET /api/v1/notifications`
- `POST /api/v1/notifications/{notificationId}/read`

### Optional International Catalog

- `GET /api/v1/international-transfers/catalog`

This last endpoint is included because your sample response is clearly an international transfer configuration payload, not an internal transfer payload.

## 4. Shared Service Catalog Response

`GET /api/v1/catalog/services`

```json
{
  "responseCode": "0",
  "responseMessage": "Success",
  "data": [
    {
      "serviceCode": "local_transfer",
      "serviceName": "Internal Transfer",
      "serviceNameAr": "تحويلات محلية",
      "description": "Transfer between supported banks and wallets.",
      "descriptionAr": "تحويل بين البنوك والمحافظ المدعومة.",
      "isActive": true,
      "entryPoint": "home_card",
      "displayOrder": 1
    },
    {
      "serviceCode": "international_transfer",
      "serviceName": "International Transfer",
      "serviceNameAr": "تحويلات دولية",
      "description": "Receive international remittances through partner exchanges.",
      "descriptionAr": "استلام الحوالات الدولية عبر الصرافات الشريكة.",
      "isActive": true,
      "entryPoint": "home_card",
      "displayOrder": 2
    }
  ]
}
```

## 5. Internal Transfer Catalog

`GET /api/v1/internal-transfers/catalog`

Purpose:

- bootstrap the mobile app with active methods and basic rules
- keep method list dynamic
- avoid hardcoding supported banks and wallets in the client

```json
{
  "responseCode": "0",
  "responseMessage": "Success",
  "data": {
    "serviceCode": "local_transfer",
    "serviceName": "Internal Transfer",
    "serviceNameAr": "تحويلات محلية",
    "quoteTtlSeconds": 300,
    "receiptRequired": true,
    "fromMethods": [
      {
        "methodCode": "bankak",
        "methodName": "Bank of Khartoum",
        "methodNameAr": "بنك الخرطوم",
        "methodType": "bank",
        "currencyCode": "SDG",
        "logoUrl": "https://example.com/logos/bankak.png",
        "detailsHint": "Bank account number",
        "detailsHintAr": "رقم الحساب البنكي"
      },
      {
        "methodCode": "mycash_wallet",
        "methodName": "MyCashi Wallet",
        "methodNameAr": "محفظة ماي كاشي",
        "methodType": "wallet",
        "currencyCode": "SDG",
        "logoUrl": "https://example.com/logos/mycash.png",
        "detailsHint": "Wallet number",
        "detailsHintAr": "رقم المحفظة"
      }
    ]
  }
}
```

## 6. Valid Destination Routes

`GET /api/v1/internal-transfers/routes?fromMethodCode=bankak`

The app should only render destination methods returned by the server for the chosen source method.

```json
{
  "responseCode": "0",
  "responseMessage": "Success",
  "data": {
    "fromMethodCode": "bankak",
    "destinations": [
      {
        "methodCode": "faisal_bank",
        "methodName": "Faisal Islamic Bank",
        "methodNameAr": "بنك فيصل الإسلامي",
        "currencyCode": "SDG",
        "rate": 1,
        "minAmount": 1000,
        "maxAmount": 5000000
      },
      {
        "methodCode": "bravo",
        "methodName": "Bravo Wallet",
        "methodNameAr": "محفظة برافو",
        "currencyCode": "SDG",
        "rate": 1,
        "minAmount": 1000,
        "maxAmount": 1000000
      }
    ]
  }
}
```

## 7. Merchant Discovery

`GET /api/v1/internal-transfers/merchants?fromMethodCode=bankak&toMethodCode=bravo&amount=150000`

```json
{
  "responseCode": "0",
  "responseMessage": "Success",
  "data": [
    {
      "merchantCode": "merchant_rahma",
      "merchantName": "Rahma",
      "merchantNameAr": "رحمة",
      "logoUrl": "https://example.com/merchants/rahma.png",
      "fee": {
        "type": "percentage",
        "value": 1.5,
        "label": "1.5% merchant fee"
      },
      "rating": 4.8,
      "estimatedCompletion": {
        "minMinutes": 3,
        "maxMinutes": 8,
        "label": "3-8 min"
      },
      "paymentAccountPreview": {
        "accountName": "Rahma Sarf",
        "accountNumberMasked": "0912******",
        "institutionName": "Bankak Wallet"
      }
    }
  ]
}
```

## 8. Quote Endpoint

`POST /api/v1/internal-transfers/quotes`

Request:

```json
{
  "serviceCode": "local_transfer",
  "fromMethodCode": "bankak",
  "toMethodCode": "bravo",
  "merchantCode": "merchant_rahma",
  "sendAmount": 150000
}
```

Response:

```json
{
  "responseCode": "0",
  "responseMessage": "Success",
  "data": {
    "quoteId": "qt_01HSB8N9YQ7NQG7D0P9G7F6E2A",
    "expiresAt": "2026-04-05T10:35:00Z",
    "serviceCode": "local_transfer",
    "routeTitle": "Bank of Khartoum to Bravo Wallet",
    "sendAmount": 150000,
    "sendCurrency": "SDG",
    "receiveAmount": 147750,
    "receiveCurrency": "SDG",
    "feeAmount": 2250,
    "feeCurrency": "SDG",
    "rate": 1,
    "rateLabel": "1 SDG = 1 SDG",
    "merchant": {
      "merchantCode": "merchant_rahma",
      "merchantName": "Rahma"
    },
    "merchantAccount": {
      "accountName": "Rahma Sarf",
      "accountNumber": "0912345678",
      "institutionName": "Bankak Wallet",
      "note": "Send exact amount and keep the receipt."
    },
    "paymentSummary": "Pay Rahma through Bankak Wallet / 0912345678",
    "destinationSummary": "Customer will receive on Bravo Wallet"
  }
}
```

## 9. Attachment Upload

`POST /api/v1/internal-transfers/attachments`

Recommended behavior:

- use multipart upload
- upload receipt before order creation
- return an attachment token or id

Response:

```json
{
  "responseCode": "0",
  "responseMessage": "Success",
  "data": {
    "attachmentId": "att_01HSB8RG7JQ5B2A4N1MZ8C6D9E",
    "attachmentType": "receipt",
    "fileName": "bankak_receipt_150000.jpg",
    "contentType": "image/jpeg",
    "fileSizeBytes": 482193,
    "storageKey": "internal-transfer/2026/04/05/att_01HSB8RG7JQ5B2A4N1MZ8C6D9E.jpg",
    "previewUrl": "https://files.example.com/signed/att_01HS..."
  }
}
```

## 10. Create Order

`POST /api/v1/internal-transfers/orders`

Request:

```json
{
  "quoteId": "qt_01HSB8N9YQ7NQG7D0P9G7F6E2A",
  "attachmentIds": [
    "att_01HSB8RG7JQ5B2A4N1MZ8C6D9E"
  ]
}
```

Response:

```json
{
  "responseCode": "0",
  "responseMessage": "Success",
  "data": {
    "orderReference": "TRX-20260405-000123",
    "status": "UNDER_REVIEW",
    "serviceCode": "local_transfer",
    "routeTitle": "Bank of Khartoum to Bravo Wallet",
    "merchantName": "Rahma",
    "sendAmount": 150000,
    "sendCurrency": "SDG",
    "receiveAmount": 147750,
    "receiveCurrency": "SDG",
    "feeAmount": 2250,
    "feeCurrency": "SDG",
    "paymentSummary": "Pay Rahma through Bankak Wallet / 0912345678",
    "destinationSummary": "Customer will receive on Bravo Wallet",
    "createdAt": "2026-04-05T10:31:09Z",
    "attachments": [
      {
        "attachmentId": "att_01HSB8RG7JQ5B2A4N1MZ8C6D9E",
        "label": "Receipt",
        "fileName": "bankak_receipt_150000.jpg",
        "previewUrl": "https://files.example.com/signed/att_01HS..."
      }
    ]
  }
}
```

## 11. Orders List

`GET /api/v1/internal-transfers/orders?status=UNDER_REVIEW&page=1&pageSize=20`

```json
{
  "responseCode": "0",
  "responseMessage": "Success",
  "data": {
    "items": [
      {
        "orderReference": "TRX-20260405-000123",
        "status": "UNDER_REVIEW",
        "serviceCode": "local_transfer",
        "sourceName": "Bank of Khartoum",
        "sourceLogoUrl": "https://example.com/logos/bankak.png",
        "destinationName": "Bravo Wallet",
        "destinationLogoUrl": "https://example.com/logos/bravo.png",
        "receiveAmount": 147750,
        "receiveCurrency": "SDG",
        "createdAt": "2026-04-05T10:31:09Z"
      }
    ],
    "page": 1,
    "pageSize": 20,
    "totalItems": 1
  }
}
```

## 12. Order Detail

`GET /api/v1/internal-transfers/orders/TRX-20260405-000123`

This should return the full order snapshot plus attachments and status history.

## 13. Dynamic Version Of Your Example Response

Your sample is an international transfer configuration payload, but the shape has two problems:

- `transferProviders`, `currencies`, and `receiveMethods` should be arrays, not object blocks
- rates are provider-specific, so currencies should be nested under each provider or returned as a separate `rateCards` array

Recommended dynamic response:

`GET /api/v1/international-transfers/catalog`

```json
{
  "responseCode": "0",
  "responseMessage": "Success",
  "data": {
    "serviceCode": "international_transfer",
    "version": 12,
    "updatedAt": "2026-04-05T09:00:00Z",
    "exchanges": [
      {
        "exchangeCode": "mig",
        "exchangeName": "MIG Exchange",
        "exchangeNameAr": "صرافة MIG",
        "exchangeLogoUrl": "https://scontent.fcai20-6.fna.fb/...",
        "receiveMethods": [
          {
            "methodCode": "bank_transfer",
            "methodName": "Bank transfer",
            "methodNameAr": "تحويل بنكي",
            "methodLogoUrl": "https://example.com/bank_logo.png",
            "note": "Account number and holder name are required."
          },
          {
            "methodCode": "mobile_wallet",
            "methodName": "Mobile wallet",
            "methodNameAr": "محفظة إلكترونية",
            "methodLogoUrl": "https://example.com/wallet_logo.png",
            "note": null
          }
        ],
        "providers": [
          {
            "providerCode": "wistron_transfer",
            "providerName": "Wistron Transfer",
            "providerNameAr": "ويسترون ترانسفير",
            "providerLogoUrl": "https://play-lh.googleusercontent.com/WEI7",
            "note": "Wistron reference number is required for all transfers.",
            "referenceRule": {
              "required": true,
              "label": "Reference number"
            },
            "currencies": [
              {
                "currencyCode": "USD",
                "currencyName": "US Dollar",
                "exchangeRate": 2488,
                "receiveCurrencyCode": "SDG",
                "note": null
              },
              {
                "currencyCode": "SAR",
                "currencyName": "Saudi Riyal",
                "exchangeRate": 663.5,
                "receiveCurrencyCode": "SDG",
                "note": "Rates are updated daily at 12 PM UTC."
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
              "label": "Reference number"
            },
            "currencies": [
              {
                "currencyCode": "USD",
                "currencyName": "US Dollar",
                "exchangeRate": 2480,
                "receiveCurrencyCode": "SDG",
                "note": null
              }
            ]
          }
        ]
      }
    ]
  }
}
```

## 14. Why This Shape Is Better

- the app can render the entire flow dynamically
- provider-specific rate logic stays correct
- adding or disabling providers does not require a mobile release
- exchange houses can have different provider support
- receive methods can vary by exchange
- the response can be cached and versioned
