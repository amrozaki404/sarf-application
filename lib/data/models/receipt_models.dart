class TransactionReceipt {
  final String? tranDate;
  final String? tranTime;
  final String? amount;
  final String? currency;
  final String? tranType;
  final String? feeAmount;
  final bool? isCredit;
  final bool? showReceipt;
  final String? beneficiaryName;
  final String? tranDescription;
  final String? beneficiaryValue;
  final String? transactionStatus;
  final String? transactionId;
  final List<TransactionReceiptField> transactionFields;

  const TransactionReceipt({
    this.tranDate,
    this.tranTime,
    this.amount,
    this.currency,
    this.tranType,
    this.feeAmount,
    this.isCredit,
    this.showReceipt,
    this.beneficiaryName,
    this.tranDescription,
    this.beneficiaryValue,
    this.transactionStatus,
    this.transactionId,
    this.transactionFields = const [],
  });

  bool get shouldShow => showReceipt != false;

  String get uniqueKey {
    final parts = [
      transactionId,
      tranDate,
      tranTime,
      amount,
      currency,
      tranDescription,
      transactionStatus,
    ].whereType<String>().where((value) => value.trim().isNotEmpty);
    return parts.join('|');
  }

  String get amountWithCurrency {
    final amountText = amount?.trim() ?? '';
    final currencyText = currency?.trim() ?? '';
    if (amountText.isEmpty) return currencyText;
    if (currencyText.isEmpty) return amountText;
    return '$amountText $currencyText';
  }

  factory TransactionReceipt.fromJson(Map<String, dynamic> json) {
    return TransactionReceipt(
      tranDate: _asText(json['tranDate']),
      tranTime: _asText(json['tranTime']),
      amount: _asText(json['amount']),
      currency: _asText(json['currency']),
      tranType: _asText(json['tranType']),
      feeAmount: _asText(json['feeAmount']),
      isCredit: _asBool(json['isCredit']),
      showReceipt: _asBool(json['showReceipt']),
      beneficiaryName: _asText(json['beneficiaryName']),
      tranDescription: _asText(json['tranDescription']),
      beneficiaryValue: _asText(json['beneficiaryValue']),
      transactionStatus: _asText(json['transactionStatus']),
      transactionId: _asText(json['transactionId']),
      transactionFields: (json['transactionFields'] as List<dynamic>? ?? const [])
          .map((field) => TransactionReceiptField.fromJson(field))
          .where((field) => field.label.isNotEmpty && field.value.isNotEmpty)
          .toList(),
    );
  }

  static TransactionReceipt? maybeFromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    final receipt = TransactionReceipt.fromJson(json);
    if (!receipt.shouldShow) return null;
    final hasContent = receipt.amountWithCurrency.isNotEmpty ||
        (receipt.tranType?.trim().isNotEmpty ?? false) ||
        (receipt.tranDate?.trim().isNotEmpty ?? false) ||
        (receipt.tranTime?.trim().isNotEmpty ?? false) ||
        (receipt.feeAmount?.trim().isNotEmpty ?? false) ||
        (receipt.beneficiaryName?.trim().isNotEmpty ?? false) ||
        (receipt.beneficiaryValue?.trim().isNotEmpty ?? false) ||
        (receipt.tranDescription?.trim().isNotEmpty ?? false) ||
        (receipt.transactionId?.trim().isNotEmpty ?? false) ||
        (receipt.transactionStatus?.trim().isNotEmpty ?? false) ||
        receipt.transactionFields.isNotEmpty;
    return hasContent ? receipt : null;
  }

  static String? _asText(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  static bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
    return null;
  }
}

class TransactionReceiptField {
  final String label;
  final String value;

  const TransactionReceiptField({
    required this.label,
    required this.value,
  });

  factory TransactionReceiptField.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return const TransactionReceiptField(label: '', value: '');
    }

    final label = (json['label'] ??
            json['name'] ??
            json['fieldName'] ??
            json['title'] ??
            '')
        .toString()
        .trim();
    final value =
        (json['value'] ?? json['fieldValue'] ?? json['content'] ?? '')
            .toString()
            .trim();

    return TransactionReceiptField(label: label, value: value);
  }
}
