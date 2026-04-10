class Transaction {
  final String transactionId;
  final String tranDescription;
  final double amount;
  final String tranDate;
  final String tranTime;

  const Transaction({
    required this.transactionId,
    required this.tranDescription,
    required this.amount,
    required this.tranDate,
    required this.tranTime,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      transactionId: json['transactionId']?.toString() ?? '',
      tranDescription: json['tranDescription']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      tranDate: json['tranDate']?.toString() ?? '',
      tranTime: json['tranTime']?.toString() ?? '',
    );
  }
}
