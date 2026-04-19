import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Color helpers
// ─────────────────────────────────────────────────────────────────────────────

const _kBrandPalette = [
  Color(0xFF6C5CE7), Color(0xFFE17055), Color(0xFF00B894),
  Color(0xFF0984E3), Color(0xFFFD9644), Color(0xFF00CEC9),
  Color(0xFFD63031), Color(0xFF6D4C41), Color(0xFF00897B),
  Color(0xFF8E24AA), Color(0xFF1E88E5), Color(0xFF43A047),
];

Color _colorFromInitial(String initial) {
  final code = initial.isEmpty ? 65 : initial.codeUnitAt(0);
  return _kBrandPalette[code % _kBrandPalette.length];
}

// ─────────────────────────────────────────────────────────────────────────────
// Category
// ─────────────────────────────────────────────────────────────────────────────

class LikeCardCategory {
  final String id;
  final String nameEn;
  final String nameAr;
  final String? iconUrl;
  final int productCount;

  const LikeCardCategory({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.iconUrl,
    required this.productCount,
  });

  Color get color => _colorFromInitial(nameEn);

  factory LikeCardCategory.fromJson(Map<String, dynamic> json) {
    return LikeCardCategory(
      id: json['id'] as String,
      nameEn: json['nameEn'] as String,
      nameAr: json['nameAr'] as String,
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
  final String initial;
  final String? imageUrl;
  final String? descEn;
  final String? descAr;
  final String? activationInstructionsEn;
  final String? activationInstructionsAr;
  final bool isPopular;
  final double rating;
  final int reviewCount;
  final int purchaseCount;
  final List<LikeCardDenomination> denominations;

  const LikeCardProduct({
    required this.id,
    required this.categoryId,
    required this.nameEn,
    required this.nameAr,
    required this.initial,
    this.imageUrl,
    this.descEn,
    this.descAr,
    this.activationInstructionsEn,
    this.activationInstructionsAr,
    this.isPopular = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.purchaseCount = 0,
    required this.denominations,
  });

  Color get brandColor => _colorFromInitial(initial);

  double get minPriceSDG => denominations.isEmpty
      ? 0
      : denominations.map((d) => d.priceSDG).reduce((a, b) => a < b ? a : b);

  double get maxPriceSDG => denominations.isEmpty
      ? 0
      : denominations.map((d) => d.priceSDG).reduce((a, b) => a > b ? a : b);

  factory LikeCardProduct.fromJson(Map<String, dynamic> json) {
    return LikeCardProduct(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      nameEn: json['nameEn'] as String,
      nameAr: json['nameAr'] as String,
      initial: json['initial'] as String? ?? '?',
      imageUrl: json['imageUrl'] as String?,
      descEn: json['descEn'] as String?,
      descAr: json['descAr'] as String?,
      activationInstructionsEn: json['activationInstructionsEn'] as String?,
      activationInstructionsAr: json['activationInstructionsAr'] as String?,
      isPopular: json['popular'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      purchaseCount: (json['purchaseCount'] as num?)?.toInt() ?? 0,
      denominations: (json['denominations'] as List? ?? [])
          .map((e) => LikeCardDenomination.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gift Card Review
// ─────────────────────────────────────────────────────────────────────────────

class GiftCardReview {
  final String authorName;
  final double rating;
  final String comment;
  final String date;

  const GiftCardReview({
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory GiftCardReview.fromJson(Map<String, dynamic> json) {
    return GiftCardReview(
      authorName: json['authorName'] as String? ?? 'Anonymous',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String? ?? '',
      date: json['date'] as String? ?? '',
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
    this.productImageUrl,
    required this.categoryId,
    required this.denominationLabel,
    required this.priceSDG,
    required this.cardCode,
    this.recipient,
    required this.status,
    this.createdAt,
  });

  Color get productColor => _colorFromInitial(productInitial);

  factory LikeCardOrder.fromJson(Map<String, dynamic> json) {
    return LikeCardOrder(
      orderReference: json['orderReference'] as String,
      productId: json['productId'] as String,
      productNameEn: json['productNameEn'] as String,
      productNameAr: json['productNameAr'] as String,
      productInitial: json['productInitial'] as String? ?? '?',
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
