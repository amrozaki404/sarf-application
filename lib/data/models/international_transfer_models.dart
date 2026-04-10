// ── Catalog ───────────────────────────────────────────────────────────────────

class ExchangeOption {
  final String code;
  final String name;
  final String? logoUrl;

  const ExchangeOption({
    required this.code,
    required this.name,
    this.logoUrl,
  });

  factory ExchangeOption.fromJson(Map<String, dynamic> json) {
    return ExchangeOption(
      code: json['code'] as String,
      name: json['name'] as String,
      logoUrl: json['logoUrl'] as String?,
    );
  }
}

class ProviderOption {
  final String code;
  final String name;
  final String? logoUrl;
  final String? notes;
  final bool referenceRequired;
  final String fieldType; // 'text' or 'number'
  final String? referenceLabelEn;
  final String? referenceLabelAr;
  final String? referenceHelpEn;
  final String? referenceHelpAr;

  const ProviderOption({
    required this.code,
    required this.name,
    this.logoUrl,
    this.notes,
    required this.referenceRequired,
    this.fieldType = 'text',
    this.referenceLabelEn,
    this.referenceLabelAr,
    this.referenceHelpEn,
    this.referenceHelpAr,
  });

  factory ProviderOption.fromJson(Map<String, dynamic> json) {
    return ProviderOption(
      code: json['code'] as String,
      name: json['name'] as String,
      logoUrl: json['logoUrl'] as String?,
      notes: json['notes'] as String?,
      referenceRequired: json['referenceRequired'] as bool? ?? false,
      fieldType: json['fieldType'] as String? ?? 'text',
      referenceLabelEn: json['referenceLabelEn'] as String?,
      referenceLabelAr: json['referenceLabelAr'] as String?,
      referenceHelpEn: json['referenceHelpEn'] as String?,
      referenceHelpAr: json['referenceHelpAr'] as String?,
    );
  }
}

class CurrencyOption {
  final String code;
  final String nameEn;
  final String nameAr;

  const CurrencyOption({
    required this.code,
    required this.nameEn,
    required this.nameAr,
  });

  String name(bool isAr) => isAr ? nameAr : nameEn;

  factory CurrencyOption.fromJson(Map<String, dynamic> json) {
    final code = json['code'] as String;
    return CurrencyOption(
      code: code,
      nameEn: json['nameEn'] as String? ?? code,
      nameAr: json['nameAr'] as String? ?? code,
    );
  }
}

class ReceiveMethodOption {
  final String code;
  final String nameEn;
  final String nameAr;
  final String? logoUrl;

  const ReceiveMethodOption({
    required this.code,
    required this.nameEn,
    required this.nameAr,
    this.logoUrl,
  });

  String name(bool isAr) => isAr ? nameAr : nameEn;

  factory ReceiveMethodOption.fromJson(Map<String, dynamic> json) {
    return ReceiveMethodOption(
      code: json['code'] as String,
      nameEn: json['nameEn'] as String,
      nameAr: json['nameAr'] as String,
      logoUrl: json['logoUrl'] as String?,
    );
  }
}

class TransferService {
  final String code;
  final String name;
  final String? description;
  final String? logoUrl;
  final String routeType;

  const TransferService({
    required this.code,
    required this.name,
    this.description,
    this.logoUrl,
    required this.routeType,
  });

  factory TransferService.fromJson(Map<String, dynamic> json) {
    return TransferService(
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      routeType: json['routeType'] as String? ?? 'COMING_SOON',
    );
  }
}

// ── Rate ──────────────────────────────────────────────────────────────────────

class RateInfo {
  final String sendCurrencyCode;
  final String receiveCurrencyCode;
  final double rate;
  final String? noteEn;
  final String? noteAr;
  final double? estimatedReceiveAmount;

  const RateInfo({
    required this.sendCurrencyCode,
    required this.receiveCurrencyCode,
    required this.rate,
    this.noteEn,
    this.noteAr,
    this.estimatedReceiveAmount,
  });

  factory RateInfo.fromJson(Map<String, dynamic> json) {
    return RateInfo(
      sendCurrencyCode: json['sendCurrencyCode'] as String,
      receiveCurrencyCode: json['receiveCurrencyCode'] as String,
      rate: (json['rate'] as num).toDouble(),
      noteEn: json['noteEn'] as String?,
      noteAr: json['noteAr'] as String?,
      estimatedReceiveAmount:
          (json['estimatedReceiveAmount'] as num?)?.toDouble(),
    );
  }
}

// ── Order ─────────────────────────────────────────────────────────────────────

class IntlOrderRequest {
  final String exchangeCode;
  final String providerCode;
  final String? providerReference;
  final String sendCurrencyCode;
  final double sendAmount;
  final String senderName;
  final String receiverName;
  final String receiveMethodCode;
  final String destinationAccountNumber;
  final String destinationAccountHolder;

  const IntlOrderRequest({
    required this.exchangeCode,
    required this.providerCode,
    this.providerReference,
    required this.sendCurrencyCode,
    required this.sendAmount,
    required this.senderName,
    required this.receiverName,
    required this.receiveMethodCode,
    required this.destinationAccountNumber,
    required this.destinationAccountHolder,
  });

  Map<String, String> toFormFields() => {
        'exchangeCode': exchangeCode,
        'providerCode': providerCode,
        if (providerReference != null && providerReference!.isNotEmpty)
          'providerReference': providerReference!,
        'sendCurrencyCode': sendCurrencyCode,
        'sendAmount': sendAmount.toStringAsFixed(2),
        'senderName': senderName,
        'receiverName': receiverName,
        'receiveMethodCode': receiveMethodCode,
        'destinationAccountNumber': destinationAccountNumber,
        'destinationAccountHolder': destinationAccountHolder,
      };
}

class IntlOrder {
  final String uuid;
  final String orderReference;
  final String serviceCode;
  final String status;
  final String? exchangeCode;
  final String? exchangeName;
  final String? providerCode;
  final String? providerName;
  final String? providerReference;
  final String? senderName;
  final String? receiverName;
  final String? receiveMethodCode;
  final String? receiveMethodName;
  final String? destinationAccountNumber;
  final String? destinationAccountHolder;
  final double sendAmount;
  final String sendCurrencyCode;
  final double receiveAmount;
  final String receiveCurrencyCode;
  final double appliedRate;
  final double feeAmount;
  final String feeCurrencyCode;
  final String? createdAt;
  final int attachmentCount;

  const IntlOrder({
    required this.uuid,
    required this.orderReference,
    required this.serviceCode,
    required this.status,
    this.exchangeCode,
    this.exchangeName,
    this.providerCode,
    this.providerName,
    this.providerReference,
    this.senderName,
    this.receiverName,
    this.receiveMethodCode,
    this.receiveMethodName,
    this.destinationAccountNumber,
    this.destinationAccountHolder,
    required this.sendAmount,
    required this.sendCurrencyCode,
    required this.receiveAmount,
    required this.receiveCurrencyCode,
    required this.appliedRate,
    required this.feeAmount,
    required this.feeCurrencyCode,
    this.createdAt,
    this.attachmentCount = 0,
  });

  factory IntlOrder.fromJson(Map<String, dynamic> json) {
    return IntlOrder(
      uuid: json['uuid'] as String,
      orderReference: json['orderReference'] as String,
      serviceCode: json['serviceCode'] as String,
      status: json['status'] as String,
      exchangeCode: json['exchangeCode'] as String?,
      exchangeName: json['exchangeName'] as String?,
      providerCode: json['providerCode'] as String?,
      providerName: json['providerName'] as String?,
      providerReference: json['providerReference'] as String?,
      senderName: json['senderName'] as String?,
      receiverName: json['receiverName'] as String?,
      receiveMethodCode: json['receiveMethodCode'] as String?,
      receiveMethodName: json['receiveMethodName'] as String?,
      destinationAccountNumber: json['destinationAccountNumber'] as String?,
      destinationAccountHolder: json['destinationAccountHolder'] as String?,
      sendAmount: (json['sendAmount'] as num).toDouble(),
      sendCurrencyCode: json['sendCurrencyCode'] as String,
      receiveAmount: (json['receiveAmount'] as num).toDouble(),
      receiveCurrencyCode: json['receiveCurrencyCode'] as String,
      appliedRate: (json['appliedRate'] as num).toDouble(),
      feeAmount: (json['feeAmount'] as num).toDouble(),
      feeCurrencyCode: json['feeCurrencyCode'] as String,
      createdAt: json['createdAt'] as String?,
      attachmentCount: (json['attachmentCount'] as num?)?.toInt() ?? 0,
    );
  }
}
