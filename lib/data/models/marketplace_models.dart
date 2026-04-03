class ExchangePairOption {
  final String id;
  final String label;
  final String sendCurrency;
  final String receiveCurrency;
  final String description;

  const ExchangePairOption({
    required this.id,
    required this.label,
    required this.sendCurrency,
    required this.receiveCurrency,
    required this.description,
  });
}

class ExchangeHouseOffer {
  final String pairId;
  final double rate;
  final double minAmount;
  final double maxAmount;

  const ExchangeHouseOffer({
    required this.pairId,
    required this.rate,
    required this.minAmount,
    required this.maxAmount,
  });
}

class ExchangeHouse {
  final String id;
  final String name;
  final String region;
  final bool isActive;
  final double rating;
  final double completionRate;
  final int avgCompletionMinutes;
  final int slaMinutes;
  final String liquidityLabel;
  final String supportWindow;
  final List<ExchangeHouseOffer> offers;
  final List<String> payoutMethods;
  final List<String> badges;
  final String verificationNote;

  const ExchangeHouse({
    required this.id,
    required this.name,
    required this.region,
    required this.isActive,
    required this.rating,
    required this.completionRate,
    required this.avgCompletionMinutes,
    required this.slaMinutes,
    required this.liquidityLabel,
    required this.supportWindow,
    required this.offers,
    required this.payoutMethods,
    required this.badges,
    required this.verificationNote,
  });

  bool supportsPair(String pairId) {
    return offers.any((offer) => offer.pairId == pairId);
  }

  ExchangeHouseOffer offerFor(String pairId) {
    return offers.firstWhere((offer) => offer.pairId == pairId);
  }
}

class MarketplaceOrder {
  final String id;
  final String merchantId;
  final String merchantName;
  final String customerName;
  final String recipientName;
  final String pairId;
  final String pairLabel;
  final String sendCurrency;
  final String receiveCurrency;
  final double sendAmount;
  final double receiveAmount;
  final double rate;
  final String payoutMethod;
  final String payoutDestination;
  final String transferReference;
  final String status;
  final String kycFileName;
  final String transferReceiptName;
  final String? payoutReceiptName;
  final String? disputeReason;
  final DateTime createdAt;
  final DateTime slaDeadline;
  final DateTime? completedAt;

  const MarketplaceOrder({
    required this.id,
    required this.merchantId,
    required this.merchantName,
    required this.customerName,
    required this.recipientName,
    required this.pairId,
    required this.pairLabel,
    required this.sendCurrency,
    required this.receiveCurrency,
    required this.sendAmount,
    required this.receiveAmount,
    required this.rate,
    required this.payoutMethod,
    required this.payoutDestination,
    required this.transferReference,
    required this.status,
    required this.kycFileName,
    required this.transferReceiptName,
    required this.createdAt,
    required this.slaDeadline,
    this.payoutReceiptName,
    this.disputeReason,
    this.completedAt,
  });

  MarketplaceOrder copyWith({
    String? status,
    String? payoutReceiptName,
    String? disputeReason,
    DateTime? completedAt,
  }) {
    return MarketplaceOrder(
      id: id,
      merchantId: merchantId,
      merchantName: merchantName,
      customerName: customerName,
      recipientName: recipientName,
      pairId: pairId,
      pairLabel: pairLabel,
      sendCurrency: sendCurrency,
      receiveCurrency: receiveCurrency,
      sendAmount: sendAmount,
      receiveAmount: receiveAmount,
      rate: rate,
      payoutMethod: payoutMethod,
      payoutDestination: payoutDestination,
      transferReference: transferReference,
      status: status ?? this.status,
      kycFileName: kycFileName,
      transferReceiptName: transferReceiptName,
      payoutReceiptName: payoutReceiptName ?? this.payoutReceiptName,
      disputeReason: disputeReason ?? this.disputeReason,
      createdAt: createdAt,
      slaDeadline: slaDeadline,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class MarketplaceDisputeCase {
  final String id;
  final String orderId;
  final String merchantId;
  final String merchantName;
  final String customerName;
  final String reason;
  final String status;
  final String priority;
  final String? payoutReceiptName;
  final DateTime openedAt;
  final DateTime reviewDeadline;

  const MarketplaceDisputeCase({
    required this.id,
    required this.orderId,
    required this.merchantId,
    required this.merchantName,
    required this.customerName,
    required this.reason,
    required this.status,
    required this.priority,
    required this.openedAt,
    required this.reviewDeadline,
    this.payoutReceiptName,
  });

  MarketplaceDisputeCase copyWith({
    String? status,
    String? payoutReceiptName,
  }) {
    return MarketplaceDisputeCase(
      id: id,
      orderId: orderId,
      merchantId: merchantId,
      merchantName: merchantName,
      customerName: customerName,
      reason: reason,
      status: status ?? this.status,
      priority: priority,
      payoutReceiptName: payoutReceiptName ?? this.payoutReceiptName,
      openedAt: openedAt,
      reviewDeadline: reviewDeadline,
    );
  }
}

class MarketplaceOverview {
  final int activeMerchants;
  final int openDisputes;
  final int lockedTransactions;
  final int slaBreaches;

  const MarketplaceOverview({
    required this.activeMerchants,
    required this.openDisputes,
    required this.lockedTransactions,
    required this.slaBreaches,
  });
}
