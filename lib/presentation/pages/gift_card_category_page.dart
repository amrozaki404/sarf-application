import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/like_card_models.dart';
import '../../data/services/like_card_service.dart';
import 'gift_card_product_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _fmtSDG(double v) {
  final s = v.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '$buf SDG';
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class GiftCardCategoryPage extends StatefulWidget {
  final LikeCardCategory category;

  const GiftCardCategoryPage({super.key, required this.category});

  @override
  State<GiftCardCategoryPage> createState() => _GiftCardCategoryPageState();
}

class _GiftCardCategoryPageState extends State<GiftCardCategoryPage> {
  final _searchCtrl = TextEditingController();
  bool _isSearching = false;
  bool _popularOnly = false;
  List<LikeCardProduct> _allProducts = [];
  List<LikeCardProduct> _filtered = [];
  bool _isAr = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_applyFilters);
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products =
          await LikeCardService.getProductsByCategory(widget.category.id);
      if (!mounted) return;
      setState(() {
        _allProducts = products;
        _filtered = products;
        _loading = false;
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isAr = Localizations.localeOf(context).languageCode == 'ar';
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilters);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _isSearching = q.isNotEmpty;
      _filtered = _allProducts.where((p) {
        final matchQuery = q.isEmpty ||
            p.nameEn.toLowerCase().contains(q) ||
            p.nameAr.contains(q);
        final matchPopular = !_popularOnly || p.isPopular;
        return matchQuery && matchPopular;
      }).toList();
    });
  }

  void _togglePopular(bool value) {
    _popularOnly = value;
    _applyFilters();
  }

  String _t(String en, String ar) => _isAr ? ar : en;

  void _clearSearch() {
    _searchCtrl.clear();
    FocusScope.of(context).unfocus();
    _applyFilters();
  }

  void _resetFilters() {
    _searchCtrl.clear();
    _popularOnly = false;
    FocusScope.of(context).unfocus();
    _applyFilters();
  }

  void _goToProduct(LikeCardProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GiftCardProductPage(product: product)),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            _isAr ? widget.category.nameAr : widget.category.nameEn,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: Column(
          children: [
            _buildSearchAndFilter(),
            Expanded(child: _buildGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: AppShadows.action,
            ),
            child: TextField(
              controller: _searchCtrl,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: _t('Search cards...', 'ابحث عن بطاقة...'),
                hintStyle: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppColors.textHint,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textHint,
                  size: 19,
                ),
                suffixIcon: _isSearching
                    ? GestureDetector(
                        onTap: _clearSearch,
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 4),
                isDense: true,
              ),
            ),
          ),
        
        ],
      ),
    );
  }

  Widget _buildGrid() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.card,
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 34,
                  color: AppColors.textHint.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _t('Failed to load products', 'تعذر تحميل المنتجات'),
                style: GoogleFonts.cairo(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _t(
                  'Please retry to fetch the latest cards in this category.',
                  'أعد المحاولة لتحميل أحدث البطاقات في هذا التصنيف.',
                ),
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _loadProducts,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  _t('Retry', 'إعادة المحاولة'),
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.card,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 34,
                  color: AppColors.textHint.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _t('No products found', 'لا توجد منتجات'),
                style: GoogleFonts.cairo(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _t(
                  'Try another search term or clear the active filters.',
                  'جرّب كلمة بحث مختلفة أو امسح عوامل التصفية الحالية.',
                ),
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      physics: const BouncingScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _ProductCard(
        product: _filtered[i],
        isAr: _isAr,
        onTap: () => _goToProduct(_filtered[i]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product Card
// ─────────────────────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final LikeCardProduct product;
  final bool isAr;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.isAr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.lg,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.lg,
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: AppShadows.card,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _BrandAvatar(
                  initial: product.initial,
                  color: product.brandColor,
                  imageUrl: product.imageUrl,
                  size: 56,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isAr ? product.nameAr : product.nameEn,
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                height: 1.15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.textHint,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter Chip
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.borderSoft,
            ),
            boxShadow: selected ? AppShadows.action : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Brand Avatar (shared)
// ─────────────────────────────────────────────────────────────────────────────

class _BrandAvatar extends StatelessWidget {
  final String initial;
  final Color color;
  final double size;
  final String? imageUrl;

  const _BrandAvatar({
    required this.initial,
    required this.color,
    required this.size,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final luminance = color.computeLuminance();
    final textColor = luminance > 0.6 ? Colors.black87 : Colors.white;
    final radius = BorderRadius.circular(size * 0.28);

    Widget fallback = Center(
      child: Text(
        initial,
        style: TextStyle(
          color: textColor,
          fontSize: size * 0.44,
          fontWeight: FontWeight.w800,
          fontFamily: 'Cairo',
        ),
      ),
    );

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: size,
        height: size,
        color: color,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => fallback,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : fallback,
              )
            : fallback,
      ),
    );
  }
}
