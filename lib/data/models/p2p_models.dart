class P2PServiceOption {
  final String code;
  final String title;
  final String description;
  final bool isAvailable;

  const P2PServiceOption({
    required this.code,
    required this.title,
    required this.description,
    required this.isAvailable
  });
}

class P2PMethodOption {
  final String id;
  final String serviceCode;
  final String name;
  final String type;
  final String currency;
  final String? logoUrl;
  final String detailsHint;

  const P2PMethodOption({
    required this.id,
    required this.serviceCode,
    required this.name,
    required this.type,
    required this.currency,
    this.logoUrl,
    required this.detailsHint,
  });
}

class P2PRouteOption {
  final String serviceCode;
  final String fromMethodId;
  final String toMethodId;
  final double rate;

  const P2PRouteOption({
    required this.serviceCode,
    required this.fromMethodId,
    required this.toMethodId,
    required this.rate,
  });
}

class P2PMerchantAccount {
  final String methodId;
  final String accountName;
  final String accountNumber;
  final String bankName;
  final String note;

  const P2PMerchantAccount({
    required this.methodId,
    required this.accountName,
    required this.accountNumber,
    required this.bankName,
    required this.note,
  });
}

class P2PMerchantOption {
  final String id;
  final String name;
  final String feeType;
  final double feeValue;
  final List<P2PMerchantAccount> accounts;

  const P2PMerchantOption({
    required this.id,
    required this.name,
    required this.feeType,
    required this.feeValue,
    required this.accounts,
  });
}

class P2PQuoteRequest {
  final String serviceCode;
  final String fromMethodId;
  final String toMethodId;
  final String merchantId;
  final double sendAmount;

  const P2PQuoteRequest({
    required this.serviceCode,
    required this.fromMethodId,
    required this.toMethodId,
    required this.merchantId,
    required this.sendAmount,
  });
}

class P2PQuote {
  final String serviceCode;
  final String serviceTitle;
  final String routeTitle;
  final double sendAmount;
  final String sendCurrency;
  final double receiveAmount;
  final String receiveCurrency;
  final double feeAmount;
  final String feeCurrency;
  final double rate;
  final String rateLabel;
  final String merchantName;
  final String merchantFeeLabel;
  final String paymentSummary;
  final String destinationSummary;

  const P2PQuote({
    required this.serviceCode,
    required this.serviceTitle,
    required this.routeTitle,
    required this.sendAmount,
    required this.sendCurrency,
    required this.receiveAmount,
    required this.receiveCurrency,
    required this.feeAmount,
    required this.feeCurrency,
    required this.rate,
    required this.rateLabel,
    required this.merchantName,
    required this.merchantFeeLabel,
    required this.paymentSummary,
    required this.destinationSummary,
  });
}

class P2POrderAttachment {
  final String label;
  final String name;
  final String? previewSource;

  const P2POrderAttachment({
    required this.label,
    required this.name,
    this.previewSource,
  });
}

class P2POrder {
  final String orderReference;
  final String serviceCode;
  final String serviceTitle;
  final String routeTitle;
  final String status;
  final String merchantName;
  final double sendAmount;
  final String sendCurrency;
  final double receiveAmount;
  final String receiveCurrency;
  final double feeAmount;
  final String feeCurrency;
  final double rate;
  final String paymentSummary;
  final String destinationSummary;
  final String customerReceiptName;
  final String createdAt;
  final String? sourceName;
  final String? sourceLogoUrl;
  final String? destinationName;
  final String? destinationLogoUrl;
  final List<P2POrderAttachment>? _attachments;

  List<P2POrderAttachment> get attachments => _attachments ?? const [];

  const P2POrder({
    required this.orderReference,
    required this.serviceCode,
    required this.serviceTitle,
    required this.routeTitle,
    required this.status,
    required this.merchantName,
    required this.sendAmount,
    required this.sendCurrency,
    required this.receiveAmount,
    required this.receiveCurrency,
    required this.feeAmount,
    required this.feeCurrency,
    required this.rate,
    required this.paymentSummary,
    required this.destinationSummary,
    required this.customerReceiptName,
    required this.createdAt,
    this.sourceName,
    this.sourceLogoUrl,
    this.destinationName,
    this.destinationLogoUrl,
    List<P2POrderAttachment>? attachments,
  }) : _attachments = attachments;
}
