class CurrencyItem {
  final String code;
  final String name;

  const CurrencyItem({
    required this.code,
    required this.name,
  });

  factory CurrencyItem.fromJson(Map<String, dynamic> json) => CurrencyItem(
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
      );
}

class RateItem {
  final String target;
  final String targetName;
  final double price;

  const RateItem({
    required this.target,
    required this.targetName,
    required this.price,
  });

  factory RateItem.fromJson(Map<String, dynamic> json) => RateItem(
        target: json['target']?.toString() ?? '',
        targetName: json['targetName']?.toString() ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
      );
}
