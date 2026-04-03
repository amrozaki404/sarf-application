import 'dart:io';

import '../models/marketplace_models.dart';

class MarketplaceService {
  static const List<ExchangePairOption> pairs = [
    ExchangePairOption(
      id: 'usd_sdg',
      label: 'USD -> SDG',
      sendCurrency: 'USD',
      receiveCurrency: 'SDG',
      description: 'Western Union or MoneyGram transfer paid out in Sudan.',
    ),
    ExchangePairOption(
      id: 'usd_egp',
      label: 'USD -> EGP',
      sendCurrency: 'USD',
      receiveCurrency: 'EGP',
      description: 'USD corridor into Egyptian bank accounts and InstaPay.',
    ),
    ExchangePairOption(
      id: 'sar_sdg',
      label: 'SAR -> SDG',
      sendCurrency: 'SAR',
      receiveCurrency: 'SDG',
      description: 'Saudi remittance corridor with same-day Sudan payout.',
    ),
    ExchangePairOption(
      id: 'eur_egp',
      label: 'EUR -> EGP',
      sendCurrency: 'EUR',
      receiveCurrency: 'EGP',
      description: 'European transfer documents settled into Egypt.',
    ),
  ];

  static const List<ExchangeHouse> exchangeHouses = [
    ExchangeHouse(
      id: 'merchant_nile',
      name: 'Nile Crown Exchange',
      region: 'Cairo Desk',
      isActive: true,
      rating: 4.9,
      completionRate: 98.4,
      avgCompletionMinutes: 14,
      slaMinutes: 35,
      liquidityLabel: 'High liquidity',
      supportWindow: '08:00 - 23:00',
      offers: [
        ExchangeHouseOffer(
          pairId: 'usd_sdg',
          rate: 2490,
          minAmount: 50,
          maxAmount: 5000,
        ),
        ExchangeHouseOffer(
          pairId: 'usd_egp',
          rate: 50.75,
          minAmount: 50,
          maxAmount: 4000,
        ),
        ExchangeHouseOffer(
          pairId: 'sar_sdg',
          rate: 664.50,
          minAmount: 100,
          maxAmount: 15000,
        ),
      ],
      payoutMethods: ['InstaPay', 'Bankak', 'Bank transfer'],
      badges: ['Verified KYC', 'Instant payout', 'Priority desk'],
      verificationNote:
          'Merchant verifies the sender receipt externally before payout.',
    ),
    ExchangeHouse(
      id: 'merchant_mashriq',
      name: 'Mashriq FX House',
      region: 'Khartoum Desk',
      isActive: true,
      rating: 4.7,
      completionRate: 96.9,
      avgCompletionMinutes: 18,
      slaMinutes: 45,
      liquidityLabel: 'Balanced liquidity',
      supportWindow: '09:00 - 22:00',
      offers: [
        ExchangeHouseOffer(
          pairId: 'usd_sdg',
          rate: 2483,
          minAmount: 75,
          maxAmount: 3000,
        ),
        ExchangeHouseOffer(
          pairId: 'sar_sdg',
          rate: 667.10,
          minAmount: 150,
          maxAmount: 12000,
        ),
        ExchangeHouseOffer(
          pairId: 'eur_egp',
          rate: 55.10,
          minAmount: 80,
          maxAmount: 3500,
        ),
      ],
      payoutMethods: ['Bankak', 'Fawry Bank', 'Cash pickup'],
      badges: ['Weekend desk', 'Manual review', 'Sudan corridor'],
      verificationNote:
          'Payout starts only after the transfer is confirmed on the terminal.',
    ),
    ExchangeHouse(
      id: 'merchant_capital',
      name: 'Capital Remit Partners',
      region: 'Nasr City Desk',
      isActive: true,
      rating: 4.8,
      completionRate: 97.5,
      avgCompletionMinutes: 11,
      slaMinutes: 30,
      liquidityLabel: 'Enterprise liquidity',
      supportWindow: '24/7',
      offers: [
        ExchangeHouseOffer(
          pairId: 'usd_sdg',
          rate: 2478,
          minAmount: 100,
          maxAmount: 7000,
        ),
        ExchangeHouseOffer(
          pairId: 'usd_egp',
          rate: 50.40,
          minAmount: 80,
          maxAmount: 5000,
        ),
        ExchangeHouseOffer(
          pairId: 'eur_egp',
          rate: 55.55,
          minAmount: 100,
          maxAmount: 5000,
        ),
      ],
      payoutMethods: ['InstaPay', 'Bank transfer', 'Meeza card'],
      badges: ['Admin monitored', 'Escrow ready', 'Fastest SLA'],
      verificationNote:
          'High-volume desk with mandatory payout receipt upload on completion.',
    ),
    ExchangeHouse(
      id: 'merchant_redsea',
      name: 'Red Sea Exchange',
      region: 'Port Sudan Desk',
      isActive: false,
      rating: 4.3,
      completionRate: 92.1,
      avgCompletionMinutes: 26,
      slaMinutes: 60,
      liquidityLabel: 'Limited liquidity',
      supportWindow: '10:00 - 18:00',
      offers: [
        ExchangeHouseOffer(
          pairId: 'usd_sdg',
          rate: 2465,
          minAmount: 50,
          maxAmount: 1200,
        ),
      ],
      payoutMethods: ['Bankak'],
      badges: ['Offline desk'],
      verificationNote: 'Desk is inactive and hidden from customers.',
    ),
  ];

  static final List<MarketplaceOrder> _orders = [
    MarketplaceOrder(
      id: 'MRK-240402-104',
      merchantId: 'merchant_nile',
      merchantName: 'Nile Crown Exchange',
      customerName: 'Ahmed Mahmoud',
      recipientName: 'Mona Salah',
      pairId: 'usd_sdg',
      pairLabel: 'USD -> SDG',
      sendCurrency: 'USD',
      receiveCurrency: 'SDG',
      sendAmount: 220,
      receiveAmount: 547800,
      rate: 2490,
      payoutMethod: 'Bankak',
      payoutDestination: '0911456677',
      transferReference: 'WU-448812990',
      status: 'UNDER_REVIEW',
      kycFileName: 'ahmed_passport.jpg',
      transferReceiptName: 'wu_220usd.jpg',
      createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
      slaDeadline: DateTime.now().add(const Duration(minutes: 17)),
    ),
    MarketplaceOrder(
      id: 'MRK-240402-101',
      merchantId: 'merchant_mashriq',
      merchantName: 'Mashriq FX House',
      customerName: 'Sara Adel',
      recipientName: 'Omar Nour',
      pairId: 'sar_sdg',
      pairLabel: 'SAR -> SDG',
      sendCurrency: 'SAR',
      receiveCurrency: 'SDG',
      sendAmount: 900,
      receiveAmount: 600390,
      rate: 667.10,
      payoutMethod: 'Bankak',
      payoutDestination: '0998877544',
      transferReference: 'MG-90233118',
      status: 'READY_FOR_PAYOUT',
      kycFileName: 'sara_id_front.jpg',
      transferReceiptName: 'moneygram_900sar.jpg',
      createdAt: DateTime.now().subtract(const Duration(minutes: 42)),
      slaDeadline: DateTime.now().add(const Duration(minutes: 3)),
    ),
    MarketplaceOrder(
      id: 'MRK-240401-086',
      merchantId: 'merchant_capital',
      merchantName: 'Capital Remit Partners',
      customerName: 'Khaled Hamza',
      recipientName: 'Lina Ahmed',
      pairId: 'usd_egp',
      pairLabel: 'USD -> EGP',
      sendCurrency: 'USD',
      receiveCurrency: 'EGP',
      sendAmount: 310,
      receiveAmount: 15624,
      rate: 50.40,
      payoutMethod: 'InstaPay',
      payoutDestination: 'lina@instapay',
      transferReference: 'WU-118220730',
      status: 'COMPLETED',
      kycFileName: 'khaled_passport.jpg',
      transferReceiptName: 'wu_310usd.png',
      payoutReceiptName: 'instapay_15624.jpg',
      createdAt: DateTime.now().subtract(const Duration(hours: 7)),
      slaDeadline: DateTime.now().subtract(const Duration(hours: 6, minutes: 30)),
      completedAt: DateTime.now().subtract(const Duration(hours: 6, minutes: 48)),
    ),
    MarketplaceOrder(
      id: 'MRK-240401-072',
      merchantId: 'merchant_capital',
      merchantName: 'Capital Remit Partners',
      customerName: 'Nour Abdelrahman',
      recipientName: 'Heba Tarek',
      pairId: 'eur_egp',
      pairLabel: 'EUR -> EGP',
      sendCurrency: 'EUR',
      receiveCurrency: 'EGP',
      sendAmount: 180,
      receiveAmount: 9999,
      rate: 55.55,
      payoutMethod: 'InstaPay',
      payoutDestination: 'heba.t@instapay',
      transferReference: 'MG-77188400',
      status: 'LOCKED',
      kycFileName: 'nour_id.jpg',
      transferReceiptName: 'moneygram_180eur.jpg',
      payoutReceiptName: 'capital_instapay_9999.jpg',
      disputeReason: 'Customer reported funds not received after completion.',
      createdAt: DateTime.now().subtract(const Duration(hours: 10)),
      slaDeadline: DateTime.now().subtract(const Duration(hours: 9, minutes: 30)),
      completedAt: DateTime.now().subtract(const Duration(hours: 9, minutes: 43)),
    ),
  ];

  static final List<MarketplaceDisputeCase> _cases = [
    MarketplaceDisputeCase(
      id: 'DSP-240402-014',
      orderId: 'MRK-240401-072',
      merchantId: 'merchant_capital',
      merchantName: 'Capital Remit Partners',
      customerName: 'Nour Abdelrahman',
      reason: 'Customer reported funds not received after completion.',
      status: 'OPEN',
      priority: 'High',
      payoutReceiptName: 'capital_instapay_9999.jpg',
      openedAt: DateTime.now().subtract(const Duration(hours: 9, minutes: 10)),
      reviewDeadline: DateTime.now().add(const Duration(minutes: 22)),
    ),
  ];

  static Future<List<ExchangePairOption>> getPairs() async {
    return pairs;
  }

  static Future<List<ExchangeHouse>> getExchangeHouses({String? pairId}) async {
    final houses = exchangeHouses
        .where((house) => house.isActive)
        .where((house) => pairId == null || house.supportsPair(pairId))
        .toList();

    if (pairId == null) {
      houses.sort((a, b) => a.name.compareTo(b.name));
    } else {
      houses.sort(
        (a, b) => b.offerFor(pairId).rate.compareTo(a.offerFor(pairId).rate),
      );
    }

    return houses;
  }

  static Future<List<MarketplaceOrder>> getOrders() async {
    final items = [..._orders];
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  static Future<MarketplaceOrder> getOrderById(String orderId) async {
    return _orders.firstWhere((order) => order.id == orderId);
  }

  static Future<List<MarketplaceOrder>> getMerchantOrders(
    String merchantId,
  ) async {
    final items = _orders
        .where((order) => order.merchantId == merchantId)
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  static Future<List<MarketplaceDisputeCase>> getDisputeCases() async {
    final items = [..._cases];
    items.sort((a, b) => b.openedAt.compareTo(a.openedAt));
    return items;
  }

  static Future<MarketplaceDisputeCase> getDisputeCaseById(String caseId) async {
    return _cases.firstWhere((item) => item.id == caseId);
  }

  static Future<MarketplaceOverview> getOverview() async {
    final now = DateTime.now();
    final activeMerchants = exchangeHouses.where((house) => house.isActive).length;
    final openDisputes = _cases.where((item) => item.status == 'OPEN').length;
    final lockedTransactions =
        _orders.where((order) => order.status == 'LOCKED').length;
    final slaBreaches = _orders
        .where((order) => order.status != 'COMPLETED')
        .where((order) => order.status != 'LOCKED')
        .where((order) => order.slaDeadline.isBefore(now))
        .length;

    return MarketplaceOverview(
      activeMerchants: activeMerchants,
      openDisputes: openDisputes,
      lockedTransactions: lockedTransactions,
      slaBreaches: slaBreaches,
    );
  }

  static ExchangePairOption getPairById(String pairId) {
    return pairs.firstWhere((pair) => pair.id == pairId);
  }

  static ExchangeHouse getMerchantById(String merchantId) {
    return exchangeHouses.firstWhere((merchant) => merchant.id == merchantId);
  }

  static Future<MarketplaceOrder> submitCustomerOrder({
    required String merchantId,
    required String pairId,
    required String customerName,
    required String recipientName,
    required String payoutMethod,
    required String payoutDestination,
    required String transferReference,
    required double sendAmount,
    required String kycFileName,
    required String transferReceiptName,
  }) async {
    final merchant = getMerchantById(merchantId);
    final pair = getPairById(pairId);
    final offer = merchant.offerFor(pairId);
    final order = MarketplaceOrder(
      id: 'MRK-${DateTime.now().millisecondsSinceEpoch}',
      merchantId: merchant.id,
      merchantName: merchant.name,
      customerName: customerName,
      recipientName: recipientName,
      pairId: pair.id,
      pairLabel: pair.label,
      sendCurrency: pair.sendCurrency,
      receiveCurrency: pair.receiveCurrency,
      sendAmount: sendAmount,
      receiveAmount: sendAmount * offer.rate,
      rate: offer.rate,
      payoutMethod: payoutMethod,
      payoutDestination: payoutDestination,
      transferReference: transferReference,
      status: 'UNDER_REVIEW',
      kycFileName: kycFileName,
      transferReceiptName: transferReceiptName,
      createdAt: DateTime.now(),
      slaDeadline: DateTime.now().add(Duration(minutes: merchant.slaMinutes)),
    );
    _orders.insert(0, order);
    return order;
  }

  static Future<MarketplaceOrder> verifyIncomingTransfer(String orderId) async {
    return _updateOrder(
      orderId,
      (order) => order.copyWith(status: 'READY_FOR_PAYOUT'),
    );
  }

  static Future<MarketplaceOrder> completePayout({
    required String orderId,
    required String payoutReceiptName,
  }) async {
    return _updateOrder(
      orderId,
      (order) => order.copyWith(
        status: 'COMPLETED',
        payoutReceiptName: payoutReceiptName,
        completedAt: DateTime.now(),
      ),
    );
  }

  static Future<MarketplaceOrder> raiseDispute({
    required String orderId,
    required String reason,
  }) async {
    final updatedOrder = await _updateOrder(
      orderId,
      (order) => order.copyWith(status: 'LOCKED', disputeReason: reason),
    );

    final existingIndex = _cases.indexWhere((item) => item.orderId == orderId);
    final newCase = MarketplaceDisputeCase(
      id: existingIndex >= 0
          ? _cases[existingIndex].id
          : 'DSP-${DateTime.now().millisecondsSinceEpoch}',
      orderId: updatedOrder.id,
      merchantId: updatedOrder.merchantId,
      merchantName: updatedOrder.merchantName,
      customerName: updatedOrder.customerName,
      reason: reason,
      status: 'OPEN',
      priority: 'High',
      payoutReceiptName: updatedOrder.payoutReceiptName,
      openedAt: DateTime.now(),
      reviewDeadline: DateTime.now().add(const Duration(minutes: 30)),
    );

    if (existingIndex >= 0) {
      _cases[existingIndex] = newCase;
    } else {
      _cases.insert(0, newCase);
    }

    return updatedOrder;
  }

  static Future<MarketplaceDisputeCase> verifyMerchantProof(
    String caseId,
  ) async {
    final index = _cases.indexWhere((item) => item.id == caseId);
    final item = _cases[index];
    final order = await getOrderById(item.orderId);
    final updated = item.copyWith(
      status: 'RECEIPT_VERIFIED',
      payoutReceiptName: order.payoutReceiptName,
    );
    _cases[index] = updated;
    return updated;
  }

  static Future<MarketplaceDisputeCase> requestMoreEvidence(
    String caseId,
  ) async {
    final index = _cases.indexWhere((item) => item.id == caseId);
    final updated = _cases[index].copyWith(status: 'MORE_INFO_REQUIRED');
    _cases[index] = updated;
    return updated;
  }

  static Future<bool> uploadDocument(File file) async {
    return file.path.trim().isNotEmpty;
  }

  static MarketplaceOrder _replaceOrder(MarketplaceOrder updatedOrder) {
    final index = _orders.indexWhere((order) => order.id == updatedOrder.id);
    _orders[index] = updatedOrder;
    return updatedOrder;
  }

  static Future<MarketplaceOrder> _updateOrder(
    String orderId,
    MarketplaceOrder Function(MarketplaceOrder order) transform,
  ) async {
    final order = _orders.firstWhere((item) => item.id == orderId);
    final updated = transform(order);
    return _replaceOrder(updated);
  }
}
