import 'dart:io';

import '../models/p2p_models.dart';

class P2PService {
  // Mock transfer configuration used until the real API is connected.
  static const String serviceCurrencyConversion = 'currency_conversion';
  static const String serviceLocalTransfer = 'local_transfer';
  static const String serviceInternationalTransfer = 'international_transfer';

  static const List<P2PServiceOption> services = [
    P2PServiceOption(
      code: serviceLocalTransfer,
      title: 'Customer P2P Transfer',
      description:
          'Choose what the customer has, what they want, then complete the deal with a merchant.',
      isAvailable: true,
    ),
    P2PServiceOption(
        code: serviceInternationalTransfer,
        title: 'International Transfer',
        description:
            'Receive international transfers in Sudanese bank accounts through partner exchange houses.',
        isAvailable: true),
  ];

  static String titleFor(String serviceCode, {required bool isArabic}) {
    switch (serviceCode) {
      case serviceInternationalTransfer:
        return isArabic ? 'تحويلات دولية' : 'International Transfer';
      case serviceLocalTransfer:
      // 'Sudanese P2P'
        return isArabic ?  'تحويلات محلية' : ' Internal Transfer';
      default:
        return '';
    }
  }

  static String descriptionFor(String serviceCode, {required bool isArabic}) {
    switch (serviceCode) {
      case serviceInternationalTransfer:
        return isArabic
            ? 'استلم الحوالات الدولية في حسابك البنكي داخل السودان عبر الصرافات الشريكة.'
            : 'Receive international transfers in your Sudanese bank account through partner exchange houses.';
      case serviceLocalTransfer:
        return isArabic
            ? 'اختر ما يملكه العميل وما يريد استلامه ثم حدّد التاجر لإتمام الطلب.'
            : 'Choose what the customer has, what they want, then complete the deal with a merchant.';
      default:
        return '';
    }
  }

  static String submissionMessage(
    String serviceCode, {
    required bool isArabic,
  }) {
    switch (serviceCode) {
      case serviceInternationalTransfer:
        return isArabic
            ? 'تم إرسال طلب استلام الحوالة الدولية.'
            : 'International payout request submitted.';
      case serviceLocalTransfer:
        return isArabic ? 'تم إرسال طلب P2P.' : 'P2P request submitted.';
      default:
        return isArabic ? 'تم إرسال الطلب.' : 'Request submitted.';
    }
  }

  static const List<P2PMethodOption> methods = [
    P2PMethodOption(
      id: 'bankak',
      serviceCode: serviceLocalTransfer,
      name: 'Bank of khartoum',
      type: 'bank',
      currency: 'SDG',
      logoUrl:
          'https://play-lh.googleusercontent.com/6ycub52gYLRnYtuE0t-1UC4KsHGaXR84ol0RoezDg7U_ZFkSmSrtig9170O1TXZJQg=w240-h480-rw',
      detailsHint: 'Bank account number',
    ),
    P2PMethodOption(
      id: 'faisal_bank',
      serviceCode: serviceLocalTransfer,
      name: 'Faisal Islamic Bank',
      type: 'bank',
      currency: 'SDG',
      logoUrl:
          'https://play-lh.googleusercontent.com/7bsURUTHfGgC-QTloAmioSQFQ7228gUyXdWC2udbZ65Rc_KEJCcW6EPSrPxKM2mr6A=w240-h480-rw',
      detailsHint: 'Bank account number',
    ),
    P2PMethodOption(
      id: 'onb_bank',
      serviceCode: serviceLocalTransfer,
      name: 'Omdurman National Bank',
      type: 'bank',
      currency: 'SDG',
      logoUrl:
          'https://play-lh.googleusercontent.com/MwYw9utW4Glhq8IJVdPd9UEsRxA1MyyyASJRvdX9NirZEKOgL1Ej_NAuA74VVZSQi3ft=w240-h480-rw',
      detailsHint: 'Bank account number',
    ),
    P2PMethodOption(
      id: 'mycash_wallet',
      serviceCode: serviceLocalTransfer,
      name: 'MyCashi Wallet',
      type: 'wallet',
      currency: 'SDG',
      logoUrl:
          'https://play-lh.googleusercontent.com/7QAPoLBAxwG9bzSNU7xbeV8oJpZV5a1rbaEgFGbXsStcH9R0VpuxliVYkxeOfo3-U4Q=w240-h480-rw',
      detailsHint: 'Wallet number',
    ),
    P2PMethodOption(
      id: 'bravo',
      serviceCode: serviceLocalTransfer,
      name: 'Bravo Wallet',
      type: 'wallet',
      currency: 'SDG',
      logoUrl:
          'https://play-lh.googleusercontent.com/91_DqxreQmGuLkKU_C5DgltW1birjjr91U1NUpz835P3X9B7CaCZB6xmsXo6hr-GvaE=w240-h480-rw',
      detailsHint: 'Wallet number',
    ),
    P2PMethodOption(
      id: 'instapay_usd',
      serviceCode: serviceInternationalTransfer,
      name: 'InstaPay USD',
      type: 'international',
      currency: 'USD',
      logoUrl:
          'https://play-lh.googleusercontent.com/nvP_b6mN1nSk-5X2c1wYb9TifQpm5pQx2qk4z6cQ0hJ6a2xI6QXH6n8EG3mR7P-lGg=w240-h480-rw',
      detailsHint: 'InstaPay handle',
    ),
    P2PMethodOption(
      id: 'wise_usd',
      serviceCode: serviceInternationalTransfer,
      name: 'Wise USD',
      type: 'international',
      currency: 'USD',
      logoUrl:
          'https://play-lh.googleusercontent.com/rm9L4qGqUQq_90V5ZQ6mPO4xU9w7K2pW8xV-3psW4G7j5dTQ63F4m08eM0mMN5Q8hA=w240-h480-rw',
      detailsHint: 'Wise transfer reference',
    ),
    P2PMethodOption(
      id: 'western_union_usd',
      serviceCode: serviceInternationalTransfer,
      name: 'Western Union USD',
      type: 'international',
      currency: 'USD',
      logoUrl:
          'https://play-lh.googleusercontent.com/ZM0lP5f7Zml7YV7Q5T9r5m5R5i5sJYQw0nKxJ7Yx5g9n1gV7u1k2s9V4hR8v2Q2rQw=w240-h480-rw',
      detailsHint: 'MTCN or sender reference',
    ),
  ];

  static const List<P2PRouteOption> routes = [
    P2PRouteOption(
      serviceCode: serviceLocalTransfer,
      fromMethodId: 'bankak',
      toMethodId: 'faisal_bank',
      rate: 1,
    ),
    P2PRouteOption(
      serviceCode: serviceLocalTransfer,
      fromMethodId: 'bankak',
      toMethodId: 'onb_bank',
      rate: 1,
    ),
    P2PRouteOption(
      serviceCode: serviceLocalTransfer,
      fromMethodId: 'faisal_bank',
      toMethodId: 'bankak',
      rate: 1,
    ),
    P2PRouteOption(
      serviceCode: serviceLocalTransfer,
      fromMethodId: 'faisal_bank',
      toMethodId: 'mycash_wallet',
      rate: 1,
    ),
    P2PRouteOption(
      serviceCode: serviceLocalTransfer,
      fromMethodId: 'faisal_bank',
      toMethodId: 'bravo',
      rate: 1,
    ),
    P2PRouteOption(
      serviceCode: serviceLocalTransfer,
      fromMethodId: 'onb_bank',
      toMethodId: 'bankak',
      rate: 1,
    ),
    P2PRouteOption(
      serviceCode: serviceLocalTransfer,
      fromMethodId: 'mycash_wallet',
      toMethodId: 'onb_bank',
      rate: 1,
    ),
    P2PRouteOption(
      serviceCode: serviceLocalTransfer,
      fromMethodId: 'bravo',
      toMethodId: 'onb_bank',
      rate: 1,
    ),
    P2PRouteOption(
      serviceCode: serviceInternationalTransfer,
      fromMethodId: 'instapay_usd',
      toMethodId: 'bankak_receive',
      rate: 2495,
    ),
    P2PRouteOption(
      serviceCode: serviceInternationalTransfer,
      fromMethodId: 'instapay_usd',
      toMethodId: 'faisal_receive',
      rate: 2495,
    ),
    P2PRouteOption(
      serviceCode: serviceInternationalTransfer,
      fromMethodId: 'wise_usd',
      toMethodId: 'bankak_receive',
      rate: 2505,
    ),
    P2PRouteOption(
      serviceCode: serviceInternationalTransfer,
      fromMethodId: 'wise_usd',
      toMethodId: 'onb_receive',
      rate: 2505,
    ),
    P2PRouteOption(
      serviceCode: serviceInternationalTransfer,
      fromMethodId: 'western_union_usd',
      toMethodId: 'bankak_receive',
      rate: 2480,
    ),
    P2PRouteOption(
      serviceCode: serviceInternationalTransfer,
      fromMethodId: 'western_union_usd',
      toMethodId: 'faisal_receive',
      rate: 2480,
    ),
  ];

  static const List<P2PMerchantOption> merchants = [
    P2PMerchantOption(
      id: 'merchant_rahma',
      name: 'Rahma',
      feeType: 'percentage',
      feeValue: 1.5,
      accounts: [
        P2PMerchantAccount(
          methodId: 'bankak',
          accountName: 'Rahma Sarf',
          accountNumber: '0912345678',
          bankName: 'Bankak Wallet',
          note: 'Send exact amount and keep the receipt.',
        ),
        P2PMerchantAccount(
          methodId: 'faisal_bank',
          accountName: 'Rahma Sarf',
          accountNumber: '220011445566',
          bankName: 'Faisal Islamic Bank',
          note: 'Manual review happens after receipt upload.',
        ),
        P2PMerchantAccount(
          methodId: 'onb_bank',
          accountName: 'Rahma Sarf',
          accountNumber: '998877665544',
          bankName: 'Omdurman National Bank',
          note: 'Use your transfer reference as payment note if possible.',
        ),
        P2PMerchantAccount(
          methodId: 'mycash_wallet',
          accountName: 'Rahma Sarf',
          accountNumber: '0998877665',
          bankName: 'MyCash Wallet',
          note: 'Wallet transfers are handled manually.',
        ),
        P2PMerchantAccount(
          methodId: 'bravo',
          accountName: 'Rahma Sarf',
          accountNumber: '0998877665',
          bankName: 'Bravo Wallet',
          note: 'Wallet transfers are handled manually.',
        ),
        P2PMerchantAccount(
          methodId: 'instapay_usd',
          accountName: 'Rahma Sarf',
          accountNumber: 'rahma.sarf@instapay',
          bankName: 'InstaPay USD',
          note: 'Share your payment proof after transfer.',
        ),
        P2PMerchantAccount(
          methodId: 'wise_usd',
          accountName: 'Rahma Sarf',
          accountNumber: 'wise-rahma-001',
          bankName: 'Wise USD',
          note: 'Use the merchant name as beneficiary.',
        ),
        P2PMerchantAccount(
          methodId: 'western_union_usd',
          accountName: 'Rahma Sarf',
          accountNumber: 'WU-448-909',
          bankName: 'Western Union USD',
          note: 'Upload the transfer receipt or MTCN proof.',
        ),
      ],
    ),
    P2PMerchantOption(
      id: 'merchant_sondos',
      name: 'Sondos',
      feeType: 'percentage',
      feeValue: 1.2,
      accounts: [
        P2PMerchantAccount(
          methodId: 'bankak',
          accountName: 'Sondos Exchange',
          accountNumber: '0922233344',
          bankName: 'Bankak Wallet',
          note: 'Transfers are usually reviewed within a few minutes.',
        ),
        P2PMerchantAccount(
          methodId: 'faisal_bank',
          accountName: 'Sondos Exchange',
          accountNumber: '220011998877',
          bankName: 'Faisal Islamic Bank',
          note: 'Use your transfer reference when available.',
        ),
        P2PMerchantAccount(
          methodId: 'onb_bank',
          accountName: 'Sondos Exchange',
          accountNumber: '776655443322',
          bankName: 'Omdurman National Bank',
          note: 'Send exact amount and keep the receipt.',
        ),
        P2PMerchantAccount(
          methodId: 'mycash_wallet',
          accountName: 'Sondos Exchange',
          accountNumber: '0990011223',
          bankName: 'MyCash Wallet',
          note: 'Wallet transfers are confirmed manually.',
        ),
        P2PMerchantAccount(
          methodId: 'bravo',
          accountName: 'Sondos Exchange',
          accountNumber: '0990011223',
          bankName: 'Bravo Wallet',
          note: 'Wallet transfers are confirmed manually.',
        ),
        P2PMerchantAccount(
          methodId: 'instapay_usd',
          accountName: 'Sondos Exchange',
          accountNumber: 'sondos.sarf@instapay',
          bankName: 'InstaPay USD',
          note: 'Share your payment screenshot after transfer.',
        ),
        P2PMerchantAccount(
          methodId: 'wise_usd',
          accountName: 'Sondos Exchange',
          accountNumber: 'wise-sondos-101',
          bankName: 'Wise USD',
          note: 'Use the merchant name as beneficiary.',
        ),
        P2PMerchantAccount(
          methodId: 'western_union_usd',
          accountName: 'Sondos Exchange',
          accountNumber: 'WU-883-201',
          bankName: 'Western Union USD',
          note: 'Upload MTCN proof after payment.',
        ),
      ],
    ),
    P2PMerchantOption(
      id: 'merchant_moez',
      name: 'Moez',
      feeType: 'percentage',
      feeValue: 1.8,
      accounts: [
        P2PMerchantAccount(
          methodId: 'bankak',
          accountName: 'Moez Transfer',
          accountNumber: '0933300044',
          bankName: 'Bankak Wallet',
          note: 'Large transfers may take a little longer to verify.',
        ),
        P2PMerchantAccount(
          methodId: 'faisal_bank',
          accountName: 'Moez Transfer',
          accountNumber: '110022334455',
          bankName: 'Faisal Islamic Bank',
          note: 'Use your transfer reference when available.',
        ),
        P2PMerchantAccount(
          methodId: 'onb_bank',
          accountName: 'Moez Transfer',
          accountNumber: '554433221100',
          bankName: 'Omdurman National Bank',
          note: 'Keep the payment proof until completion.',
        ),
        P2PMerchantAccount(
          methodId: 'mycash_wallet',
          accountName: 'Moez Transfer',
          accountNumber: '0994455667',
          bankName: 'MyCash Wallet',
          note: 'Wallet transfers are processed sequentially.',
        ),
        P2PMerchantAccount(
          methodId: 'bravo',
          accountName: 'Moez Transfer',
          accountNumber: '0994455667',
          bankName: 'Bravo Wallet',
          note: 'Wallet transfers are processed sequentially.',
        ),
        P2PMerchantAccount(
          methodId: 'instapay_usd',
          accountName: 'Moez Transfer',
          accountNumber: 'moez.exchange@instapay',
          bankName: 'InstaPay USD',
          note: 'Upload your receipt after transfer.',
        ),
        P2PMerchantAccount(
          methodId: 'wise_usd',
          accountName: 'Moez Transfer',
          accountNumber: 'wise-moez-202',
          bankName: 'Wise USD',
          note: 'Use the merchant name as beneficiary.',
        ),
        P2PMerchantAccount(
          methodId: 'western_union_usd',
          accountName: 'Moez Transfer',
          accountNumber: 'WU-553-440',
          bankName: 'Western Union USD',
          note: 'Upload MTCN proof after payment.',
        ),
      ],
    ),
  ];

  static final List<P2POrder> _orders = [
    const P2POrder(
      orderReference: 'TRX-20260329-101',
      serviceCode: serviceInternationalTransfer,
      serviceTitle: 'International Transfer',
      routeTitle: 'Wistron Transfer to MIG Exchange',
      status: 'UNDER_REVIEW',
      merchantName: 'MIG Exchange',
      sendAmount: 120,
      sendCurrency: 'USD',
      receiveAmount: 296014.50,
      receiveCurrency: 'SDG',
      feeAmount: 4590,
      feeCurrency: 'SDG',
      rate: 2505,
      paymentSummary: 'Reference WS-448-909 / customer KYC verified',
      destinationSummary: 'Payout will be completed by MIG Exchange',
      customerReceiptName: 'wise_receipt_120usd.jpg',
      createdAt: '2026-03-29 12:45',
      sourceName: 'Wistron Transfer',
      sourceLogoUrl:
          'https://play-lh.googleusercontent.com/WEI7eaROMpsxYSAWCLGhmJdlTiw94MiS57vpHHOQmBShd25mOi22x6ImBkb3bNiFL7Y=w240-h480-rw',
      destinationName: 'MIG Exchange',
      destinationLogoUrl:
          'https://scontent.fcai20-6.fna.fbcdn.net/v/t39.30808-6/462913065_554762910465058_8315845462438786345_n.jpg?_nc_cat=103&ccb=1-7&_nc_sid=1d70fc&_nc_ohc=31Kr6xSkK6AQ7kNvwGYe_HW&_nc_oc=AdoShJJBa6wwVZsVc893ch2DijgSDipFcDijqZzp3GD5hf4kOtcfmrpXwlnc7q4u8iE&_nc_zt=23&_nc_ht=scontent.fcai20-6.fna&_nc_gid=TSLErbY3GBROMjsGwMvJSg&_nc_ss=7a389&oh=00_Af27bwlSubKLdHpa5ojH4PXczqKhCqDIk30EdV24SprbSg&oe=69D4A9E1',
      attachments: [
        P2POrderAttachment(
          label: 'Transfer proof',
          name: 'wise_receipt_120usd.jpg',
          previewSource:
              'https://dummyimage.com/900x1200/f4f7f8/18424f&text=Wise+Receipt',
        ),
        P2POrderAttachment(
          label: 'Customer ID',
          name: 'customer_id_front.jpg',
          previewSource:
              'https://dummyimage.com/900x1200/f8fbfc/4c5f68&text=Customer+ID',
        ),
      ],
    ),
    const P2POrder(
      orderReference: 'TRX-20260328-088',
      serviceCode: serviceLocalTransfer,
      serviceTitle: 'Customer P2P',
      routeTitle: 'Bank of khartoum to Bravo Wallet',
      status: 'COMPLETED',
      merchantName: 'Rahma',
      sendAmount: 150000,
      sendCurrency: 'SDG',
      receiveAmount: 147750,
      receiveCurrency: 'SDG',
      feeAmount: 2250,
      feeCurrency: 'SDG',
      rate: 1,
      paymentSummary: 'Pay Rahma through Bankak Wallet / 0912345678',
      destinationSummary: 'Customer will receive on Bravo Wallet',
      customerReceiptName: 'bankak_receipt_150000.jpg',
      createdAt: '2026-03-28 16:20',
      sourceName: 'Bank of khartoum',
      sourceLogoUrl:
          'https://play-lh.googleusercontent.com/6ycub52gYLRnYtuE0t-1UC4KsHGaXR84ol0RoezDg7U_ZFkSmSrtig9170O1TXZJQg=w240-h480-rw',
      destinationName: 'Bravo Wallet',
      destinationLogoUrl:
          'https://play-lh.googleusercontent.com/91_DqxreQmGuLkKU_C5DgltW1birjjr91U1NUpz835P3X9B7CaCZB6xmsXo6hr-GvaE=w240-h480-rw',
      attachments: [
        P2POrderAttachment(
          label: 'Receipt',
          name: 'bankak_receipt_150000.jpg',
          previewSource:
              'https://dummyimage.com/900x1200/f5f8fb/23414f&text=Bankak+Receipt',
        ),
      ],
    ),
    const P2POrder(
      orderReference: 'TRX-20260327-071',
      serviceCode: serviceLocalTransfer,
      serviceTitle: 'Customer P2P',
      routeTitle: 'Faisal Islamic Bank to MyCashi Wallet',
      status: 'UNDER_REVIEW',
      merchantName: 'Sondos',
      sendAmount: 85000,
      sendCurrency: 'SDG',
      receiveAmount: 83980,
      receiveCurrency: 'SDG',
      feeAmount: 1020,
      feeCurrency: 'SDG',
      rate: 1,
      paymentSummary: 'Pay Sondos through Faisal Islamic Bank / 220011445566',
      destinationSummary: 'Customer will receive on MyCashi Wallet',
      customerReceiptName: 'faisal_receipt_85000.jpg',
      createdAt: '2026-03-27 09:10',
      sourceName: 'Faisal Islamic Bank',
      sourceLogoUrl:
          'https://play-lh.googleusercontent.com/7bsURUTHfGgC-QTloAmioSQFQ7228gUyXdWC2udbZ65Rc_KEJCcW6EPSrPxKM2mr6A=w240-h480-rw',
      destinationName: 'MyCashi Wallet',
      destinationLogoUrl:
          'https://play-lh.googleusercontent.com/7QAPoLBAxwG9bzSNU7xbeV8oJpZV5a1rbaEgFGbXsStcH9R0VpuxliVYkxeOfo3-U4Q=w240-h480-rw',
      attachments: [
        P2POrderAttachment(
          label: 'Receipt',
          name: 'faisal_receipt_85000.jpg',
          previewSource:
              'https://dummyimage.com/900x1200/f7f9fb/38515f&text=Faisal+Receipt',
        ),
      ],
    ),
  ];

  static List<P2POrder> get orders => List<P2POrder>.from(_orders);

  static Future<List<P2PServiceOption>> getServiceOptions() async => services;

  static Future<List<P2PMethodOption>> getMethods(String serviceCode) async {
    return methods.where((item) => item.serviceCode == serviceCode).toList();
  }

  static Future<List<P2PMethodOption>> getFromMethods(
      String serviceCode) async {
    final fromIds = routes
        .where((item) => item.serviceCode == serviceCode)
        .map((item) => item.fromMethodId)
        .toSet();
    return methods.where((item) => fromIds.contains(item.id)).toList();
  }

  static Future<List<P2PMethodOption>> getToMethods({
    required String serviceCode,
    required String fromMethodId,
  }) async {
    final selectableIds = routes
        .where((item) => item.serviceCode == serviceCode)
        .map((item) => item.fromMethodId)
        .toSet();
    return methods
        .where(
          (item) => selectableIds.contains(item.id) && item.id != fromMethodId,
        )
        .toList();
  }

  static Future<List<P2PMerchantOption>> getMerchants({
    required String serviceCode,
    required String fromMethodId,
  }) async {
    final routeExists = routes.any(
      (item) =>
          item.serviceCode == serviceCode && item.fromMethodId == fromMethodId,
    );
    if (!routeExists) return [];
    return merchants
        .where(
          (merchant) => merchant.accounts
              .any((account) => account.methodId == fromMethodId),
        )
        .toList();
  }

  static P2PMethodOption getMethodById(String methodId) {
    return methods.firstWhere((item) => item.id == methodId);
  }

  static P2PMerchantOption getMerchantById(String merchantId) {
    return merchants.firstWhere((item) => item.id == merchantId);
  }

  static P2PMerchantAccount getMerchantAccount({
    required String merchantId,
    required String methodId,
  }) {
    final merchant = getMerchantById(merchantId);
    return merchant.accounts.firstWhere((item) => item.methodId == methodId);
  }

  static Future<P2PQuote> getQuote(P2PQuoteRequest request) async {
    final service =
        services.firstWhere((item) => item.code == request.serviceCode);
    final fromMethod = getMethodById(request.fromMethodId);
    final toMethod = getMethodById(request.toMethodId);
    final merchant = getMerchantById(request.merchantId);
    final account = getMerchantAccount(
      merchantId: merchant.id,
      methodId: fromMethod.id,
    );
    final route = routes.firstWhere(
      (item) =>
          item.serviceCode == request.serviceCode &&
          item.fromMethodId == request.fromMethodId &&
          item.toMethodId == request.toMethodId,
    );

    final grossReceive = request.sendAmount * route.rate;
    final feeAmount = _calculateFee(
      merchant: merchant,
      amount: request.sendAmount,
      serviceCode: request.serviceCode,
      rate: route.rate,
    );
    final receiveAmount = route.rate == 1
        ? request.sendAmount - feeAmount
        : grossReceive - feeAmount;

    return P2PQuote(
      serviceCode: service.code,
      serviceTitle: service.title,
      routeTitle: '${fromMethod.name} to ${toMethod.name}',
      sendAmount: request.sendAmount,
      sendCurrency: fromMethod.currency,
      receiveAmount: receiveAmount,
      receiveCurrency: toMethod.currency,
      feeAmount: feeAmount,
      feeCurrency: toMethod.currency,
      rate: route.rate,
      rateLabel: route.rate == 1
          ? '1 ${fromMethod.currency} = 1 ${toMethod.currency}'
          : '1 ${fromMethod.currency} = ${_fmt(route.rate)} ${toMethod.currency}',
      merchantName: merchant.name,
      merchantFeeLabel: _merchantFeeLabel(merchant),
      paymentSummary:
          'Pay ${merchant.name} through ${account.bankName} / ${account.accountNumber}',
      destinationSummary: 'Customer will receive on ${toMethod.name}',
    );
  }

  static Future<P2POrder> createOrder({
    required P2PQuoteRequest request,
    required String receiptName,
    String? receiptPreviewSource,
  }) async {
    final quote = await getQuote(request);
    final fromMethod = getMethodById(request.fromMethodId);
    final toMethod = getMethodById(request.toMethodId);
    final order = P2POrder(
      orderReference: 'TRX-${DateTime.now().millisecondsSinceEpoch}',
      serviceCode: quote.serviceCode,
      serviceTitle: quote.serviceTitle,
      routeTitle: quote.routeTitle,
      status: 'UNDER_REVIEW',
      merchantName: quote.merchantName,
      sendAmount: quote.sendAmount,
      sendCurrency: quote.sendCurrency,
      receiveAmount: quote.receiveAmount,
      receiveCurrency: quote.receiveCurrency,
      feeAmount: quote.feeAmount,
      feeCurrency: quote.feeCurrency,
      rate: quote.rate,
      paymentSummary: quote.paymentSummary,
      destinationSummary: quote.destinationSummary,
      customerReceiptName: receiptName,
      createdAt: DateTime.now().toString().split('.').first,
      sourceName: fromMethod.name,
      sourceLogoUrl: fromMethod.logoUrl,
      destinationName: toMethod.name,
      destinationLogoUrl: toMethod.logoUrl,
      attachments: [
        P2POrderAttachment(
          label: 'Receipt',
          name: receiptName,
          previewSource: receiptPreviewSource,
        ),
      ],
    );
    _orders.insert(0, order);
    return order;
  }

  static Future<P2POrder> createManualOrder({
    required String serviceCode,
    required String serviceTitle,
    required String routeTitle,
    required String status,
    required String merchantName,
    required double sendAmount,
    required String sendCurrency,
    required double receiveAmount,
    required String receiveCurrency,
    required double feeAmount,
    required String feeCurrency,
    required double rate,
    required String paymentSummary,
    required String destinationSummary,
    required String receiptName,
    String? sourceName,
    String? sourceLogoUrl,
    String? destinationName,
    String? destinationLogoUrl,
    List<P2POrderAttachment> attachments = const [],
  }) async {
    final order = P2POrder(
      orderReference: 'TRX-${DateTime.now().millisecondsSinceEpoch}',
      serviceCode: serviceCode,
      serviceTitle: serviceTitle,
      routeTitle: routeTitle,
      status: status,
      merchantName: merchantName,
      sendAmount: sendAmount,
      sendCurrency: sendCurrency,
      receiveAmount: receiveAmount,
      receiveCurrency: receiveCurrency,
      feeAmount: feeAmount,
      feeCurrency: feeCurrency,
      rate: rate,
      paymentSummary: paymentSummary,
      destinationSummary: destinationSummary,
      customerReceiptName: receiptName,
      createdAt: DateTime.now().toString().split('.').first,
      sourceName: sourceName,
      sourceLogoUrl: sourceLogoUrl,
      destinationName: destinationName,
      destinationLogoUrl: destinationLogoUrl,
      attachments: attachments,
    );
    _orders.insert(0, order);
    return order;
  }

  static Future<bool> uploadReceipt(File file) async {
    return file.path.trim().isNotEmpty;
  }

  static Future<P2POrder?> getLastOrder() async {
    return _orders.isEmpty ? null : _orders.first;
  }

  static Future<List<P2POrder>> getOrders() async =>
      List<P2POrder>.from(_orders);

  static double _calculateFee({
    required P2PMerchantOption merchant,
    required double amount,
    required String serviceCode,
    required double rate,
  }) {
    if (merchant.feeType == 'fixed') {
      return merchant.feeValue;
    }
    final baseAmount =
        serviceCode == serviceLocalTransfer ? amount : amount * rate;
    return baseAmount * (merchant.feeValue / 100);
  }

  static String _merchantFeeLabel(P2PMerchantOption merchant) {
    if (merchant.feeType == 'fixed') {
      return 'Fixed ${_fmt(merchant.feeValue)} SDG';
    }
    return '${merchant.feeValue.toStringAsFixed(1)}% merchant fee';
  }

  static String fmtAmount(double value) => _fmt(value);

  static String _fmt(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '$whole.${parts.last}';
  }
}
