import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Deterministic brand color from initial character
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
// Category enum
// ─────────────────────────────────────────────────────────────────────────────

enum SubCategory {
  all,
  entertainment,
  productivity,
  design,
  ai,
  security,
  business,
}

extension SubCategoryX on SubCategory {
  String get labelEn {
    switch (this) {
      case SubCategory.all:           return 'All';
      case SubCategory.entertainment: return 'Entertainment';
      case SubCategory.productivity:  return 'Productivity';
      case SubCategory.design:        return 'Design';
      case SubCategory.ai:            return 'AI Tools';
      case SubCategory.security:      return 'Security';
      case SubCategory.business:      return 'Business';
    }
  }

  String get labelAr {
    switch (this) {
      case SubCategory.all:           return 'الكل';
      case SubCategory.entertainment: return 'ترفيه';
      case SubCategory.productivity:  return 'إنتاجية';
      case SubCategory.design:        return 'تصميم';
      case SubCategory.ai:            return 'ذكاء اصطناعي';
      case SubCategory.security:      return 'حماية';
      case SubCategory.business:      return 'أعمال';
    }
  }

  IconData get icon {
    switch (this) {
      case SubCategory.all:           return Icons.apps_rounded;
      case SubCategory.entertainment: return Icons.play_circle_rounded;
      case SubCategory.productivity:  return Icons.work_outline_rounded;
      case SubCategory.design:        return Icons.palette_outlined;
      case SubCategory.ai:            return Icons.auto_awesome_rounded;
      case SubCategory.security:      return Icons.shield_outlined;
      case SubCategory.business:      return Icons.business_center_outlined;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub Duration
// ─────────────────────────────────────────────────────────────────────────────

class SubDuration {
  final String id;
  final String labelEn;
  final String labelAr;
  final int months;
  final double totalPrice;
  final bool isBestValue;

  const SubDuration({
    required this.id,
    required this.labelEn,
    required this.labelAr,
    required this.months,
    required this.totalPrice,
    this.isBestValue = false,
  });

  double get monthlyPrice => totalPrice / months;

  factory SubDuration.fromJson(Map<String, dynamic> json) {
    return SubDuration(
      id: json['id'] as String,
      labelEn: json['labelEn'] as String,
      labelAr: json['labelAr'] as String,
      months: (json['months'] as num).toInt(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      isBestValue: json['isBestValue'] as bool? ?? false,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub Review
// ─────────────────────────────────────────────────────────────────────────────

class SubReview {
  final String authorName;
  final double rating;
  final String comment;
  final String date;

  const SubReview({
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory SubReview.fromJson(Map<String, dynamic> json) {
    return SubReview(
      authorName: json['authorName'] as String,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String? ?? '',
      date: json['date'] as String,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub Field  (dynamic checkout input)
// ─────────────────────────────────────────────────────────────────────────────

class SubField {
  final String fieldKey;
  final String fieldType; // TEXT | EMAIL | PHONE | NUMBER
  final String labelEn;
  final String labelAr;
  final bool required;

  const SubField({
    required this.fieldKey,
    required this.fieldType,
    required this.labelEn,
    required this.labelAr,
    required this.required,
  });

  factory SubField.fromJson(Map<String, dynamic> json) {
    return SubField(
      fieldKey: json['fieldKey'] as String,
      fieldType: json['fieldType'] as String? ?? 'TEXT',
      labelEn: json['labelEn'] as String,
      labelAr: json['labelAr'] as String,
      required: json['required'] as bool? ?? true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Digital Subscription
// ─────────────────────────────────────────────────────────────────────────────

class DigitalSubscription {
  final String id;
  final String nameEn;
  final String nameAr;
  final String? imageUrl;
  final String initial;
  final String descEn;
  final String descAr;
  final List<String> featuresEn;
  final List<String> featuresAr;
  final List<SubField> fields;
  final double rating;
  final int reviewCount;
  final int purchaseCount;
  final List<SubDuration> durations;
  final SubCategory category;
  final bool isPopular;

  const DigitalSubscription({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.imageUrl,
    required this.initial,
    required this.descEn,
    required this.descAr,
    required this.featuresEn,
    required this.featuresAr,
    required this.fields,
    required this.rating,
    required this.reviewCount,
    required this.purchaseCount,
    required this.durations,
    required this.category,
    this.isPopular = false,
  });

  Color get brandColor => _colorFromInitial(initial);

  double get startingMonthlyPrice =>
      durations.map((d) => d.monthlyPrice).reduce((a, b) => a < b ? a : b);

  factory DigitalSubscription.fromJson(Map<String, dynamic> json) {
    return DigitalSubscription(
      id: json['id'] as String,
      nameEn: json['nameEn'] as String,
      nameAr: json['nameAr'] as String,
      imageUrl: json['imageUrl'] as String?,
      initial: json['initial'] as String? ?? '?',
      descEn: json['descEn'] as String? ?? '',
      descAr: json['descAr'] as String? ?? '',
      featuresEn: (json['featuresEn'] as List? ?? []).cast<String>(),
      featuresAr: (json['featuresAr'] as List? ?? []).cast<String>(),
      fields: (json['fields'] as List? ?? [])
          .map((e) => SubField.fromJson(e as Map<String, dynamic>))
          .toList(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      purchaseCount: (json['purchaseCount'] as num?)?.toInt() ?? 0,
      durations: (json['plans'] as List? ?? [])
          .map((e) => SubDuration.fromJson(e as Map<String, dynamic>))
          .toList(),
      category: _categoryFromString(json['category'] as String? ?? ''),
      isPopular: json['popular'] as bool? ?? false,
    );
  }

  static SubCategory _categoryFromString(String s) {
    switch (s) {
      case 'entertainment': return SubCategory.entertainment;
      case 'productivity':  return SubCategory.productivity;
      case 'design':        return SubCategory.design;
      case 'ai':            return SubCategory.ai;
      case 'security':      return SubCategory.security;
      case 'business':      return SubCategory.business;
      default:              return SubCategory.all;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub Order (passed to success sheet)
// ─────────────────────────────────────────────────────────────────────────────

class SubOrder {
  final String subscriptionNameEn;
  final String subscriptionNameAr;
  final String durationLabelEn;
  final String durationLabelAr;
  final double totalPrice;
  final String initial;
  final String? imageUrl;

  const SubOrder({
    required this.subscriptionNameEn,
    required this.subscriptionNameAr,
    required this.durationLabelEn,
    required this.durationLabelAr,
    required this.totalPrice,
    required this.initial,
    this.imageUrl,
  });

  Color get brandColor => _colorFromInitial(initial);
}
