import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Hex → Color helper
// ─────────────────────────────────────────────────────────────────────────────

Color _hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

// ─────────────────────────────────────────────────────────────────────────────
// Category
// ─────────────────────────────────────────────────────────────────────────────

class LikeCardCategory {
  final String id;
  final String nameEn;
  final String nameAr;
  final String colorHex;
  final String? iconUrl;
  final int productCount;

  const LikeCardCategory({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.colorHex,
    this.iconUrl,
    required this.productCount,
  });

  /// Parsed brand color — keeps existing page code working unchanged.
  Color get color => _hexToColor(colorHex);

  factory LikeCardCategory.fromJson(Map<String, dynamic> json) {
    return LikeCardCategory(
      id: json['id'] as String,
      nameEn: json['nameEn'] as String,
      nameAr: json['nameAr'] as String,
      colorHex: json['colorHex'] as String? ?? '#006BFF',
      iconUrl: json['iconUrl'] as String?,
      productCount: (json['productCount'] as num?)?.toInt() ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product
// ─────────────────────────────────────────────────────────────────────────────

class LikeCardProduct {
  final String id;
  final String categoryId;
  final String nameEn;
  final String nameAr;
  final String colorHex;
  final String initial;
  final String? imageUrl;
  final String? descEn;
  final String? descAr;
  final bool isPopular;
  final List<LikeCardDenomination> denominations;

  const LikeCardProduct({
    required this.id,
    required this.categoryId,
    required this.nameEn,
    required this.nameAr,
    required this.colorHex,
    required this.initial,
    this.imageUrl,
    this.descEn,
    this.descAr,
    this.isPopular = false,
    required this.denominations,
  });

  /// Parsed brand color — keeps existing page code working unchanged.
  Color get brandColor => _hexToColor(colorHex);

  double get minPriceSDG =>
      denominations.map((d) => d.priceSDG).reduce((a, b) => a < b ? a : b);

  double get maxPriceSDG =>
      denominations.map((d) => d.priceSDG).reduce((a, b) => a > b ? a : b);

  factory LikeCardProduct.fromJson(Map<String, dynamic> json) {
    return LikeCardProduct(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      nameEn: json['nameEn'] as String,
      nameAr: json['nameAr'] as String,
      colorHex: json['colorHex'] as String? ?? '#006BFF',
      initial: json['initial'] as String? ?? '?',
      imageUrl: json['imageUrl'] as String?,
      descEn: json['descEn'] as String?,
      descAr: json['descAr'] as String?,
      isPopular: json['popular'] as bool? ?? false,
      denominations: (json['denominations'] as List? ?? [])
          .map((e) => LikeCardDenomination.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Denomination
// ─────────────────────────────────────────────────────────────────────────────

class LikeCardDenomination {
  final String id;
  final String label;
  final double priceSDG;

  const LikeCardDenomination({
    required this.id,
    required this.label,
    required this.priceSDG,
  });

  factory LikeCardDenomination.fromJson(Map<String, dynamic> json) {
    return LikeCardDenomination(
      id: json['id'] as String,
      label: json['label'] as String,
      priceSDG: (json['priceSDG'] as num).toDouble(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gift Card Order
// ─────────────────────────────────────────────────────────────────────────────

class LikeCardOrder {
  final String orderReference;
  final String productId;
  final String productNameEn;
  final String productNameAr;
  final String productInitial;
  final String productColorHex;
  final String? productImageUrl;
  final String categoryId;
  final String denominationLabel;
  final double priceSDG;
  final String cardCode;
  final String? recipient;
  final String status;
  final String? createdAt;

  const LikeCardOrder({
    required this.orderReference,
    required this.productId,
    required this.productNameEn,
    required this.productNameAr,
    required this.productInitial,
    required this.productColorHex,
    this.productImageUrl,
    required this.categoryId,
    required this.denominationLabel,
    required this.priceSDG,
    required this.cardCode,
    this.recipient,
    required this.status,
    this.createdAt,
  });

  Color get productColor => _hexToColor(productColorHex);

  factory LikeCardOrder.fromJson(Map<String, dynamic> json) {
    return LikeCardOrder(
      orderReference: json['orderReference'] as String,
      productId: json['productId'] as String,
      productNameEn: json['productNameEn'] as String,
      productNameAr: json['productNameAr'] as String,
      productInitial: json['productInitial'] as String? ?? '?',
      productColorHex: json['productColorHex'] as String? ?? '#006BFF',
      productImageUrl: json['productImageUrl'] as String?,
      categoryId: json['categoryId'] as String? ?? '',
      denominationLabel: json['denominationLabel'] as String,
      priceSDG: (json['priceSDG'] as num).toDouble(),
      cardCode: json['cardCode'] as String,
      recipient: json['recipient'] as String?,
      status: json['status'] as String? ?? 'COMPLETED',
      createdAt: json['createdAt'] as String?,
    );
  }
}