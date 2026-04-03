class RateItem {
  final String target;
  final String targetName;
  final double price;
  final String? tranTime;

  const RateItem({
    required this.target,
    required this.targetName,
    required this.price,
    this.tranTime,
  });

  factory RateItem.fromJson(Map<String, dynamic> json) => RateItem(
        target: (json['target'] ?? json['fiat'])?.toString() ?? '',
        targetName: json['targetName']?.toString() ?? '',
        price:
            (json['price'] as num? ?? json['rate'] as num? ?? 0.0).toDouble(),
        tranTime: json['tranTime']?.toString(),
      );
}

class MetalPrices {
  final double? gold24kPerGramSDG;
  final double? gold21kPerGramSDG;
  final double? silverPerGramSDG;

  const MetalPrices({
    this.gold24kPerGramSDG,
    this.gold21kPerGramSDG,
    this.silverPerGramSDG,
  });

  factory MetalPrices.fromJson(Map<String, dynamic> json) => MetalPrices(
        gold24kPerGramSDG: (json['gold24kPerGramSDG'] as num?)?.toDouble(),
        gold21kPerGramSDG: (json['gold21kPerGramSDG'] as num?)?.toDouble(),
        silverPerGramSDG: (json['silverPerGramSDG'] as num?)?.toDouble(),
      );
}

class PricesResponse {
  final List<RateItem> rates;
  final MetalPrices? metals;

  const PricesResponse({
    required this.rates,
    this.metals,
  });

  factory PricesResponse.fromJson(Map<String, dynamic> json) => PricesResponse(
        rates: (json['rates'] as List<dynamic>? ?? [])
            .map((e) => RateItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        metals: json['metals'] != null
            ? MetalPrices.fromJson(json['metals'] as Map<String, dynamic>)
            : null,
      );
}
