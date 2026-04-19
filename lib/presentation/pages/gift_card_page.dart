import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/like_card_models.dart';
import '../../data/services/like_card_service.dart';
import 'gift_card_category_page.dart';
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

class GiftCardPage extends StatefulWidget {
  const GiftCardPage({super.key});

  @override
  State<GiftCardPage> createState() => _GiftCardPageState();
}

class _GiftCardPageState extends State<GiftCardPage> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  bool _isSearching = false;
  bool _searchLoading = false;
  List<LikeCardProduct> _searchResults = [];
  bool _isAr = false;

  // Browse data (loaded from API)
  bool _loading = true;
  String? _error;
  List<LikeCardCategory> _categories = [];
  List<LikeCardProduct> _popular = [];

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _loadBrowse();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isAr = Localizations.localeOf(context).languageCode == 'ar';
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadBrowse() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        LikeCardService.getCategories(),
        LikeCardService.getPopularProducts(),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<LikeCardCategory>;
        _popular = results[1] as List<LikeCardProduct>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text;
    final isSearching = q.trim().isNotEmpty;
    setState(() {
      _isSearching = isSearching;
      if (!isSearching) {
        _searchResults = [];
        _searchLoading = false;
      }
    });
    _searchDebounce?.cancel();
    if (!isSearching) return;
    setState(() => _searchLoading = true);
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final results = await LikeCardService.searchProducts(q.trim());
        if (!mounted || _searchCtrl.text.trim() != q.trim()) return;
        setState(() {
          _searchResults = results;
          _searchLoading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _searchResults = [];
          _searchLoading = false;
        });
      }
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _searchFocus.unfocus();
    setState(() {
      _isSearching = false;
      _searchResults = [];
      _searchLoading = false;
    });
  }

  String _t(String en, String ar) => _isAr ? ar : en;

  void _goToCategory(LikeCardCategory category) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GiftCardCategoryPage(category: category),
    ));
  }

  void _goToProduct(LikeCardProduct product) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GiftCardProductPage(product: product),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _SearchBar(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              isSearching: _isSearching,
              isAr: _isAr,
              onClear: _clearSearch,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _isSearching
                    ? _SearchResultsView(
                        key: const ValueKey('search'),
                        results: _searchResults,
                        query: _searchCtrl.text,
                        isAr: _isAr,
                        loading: _searchLoading,
                        categories: _categories,
                        onTap: _goToProduct,
                      )
                    : _loading
                        ? const _BrowseSkeleton(key: ValueKey('loading'))
                        : _error != null
                            ? _ErrorView(
                                key: const ValueKey('error'),
                                isAr: _isAr,
                                onRetry: _loadBrowse,
                              )
                            : _BrowseView(
                                key: const ValueKey('browse'),
                                isAr: _isAr,
                                categories: _categories,
                                popular: _popular,
                                onCategoryTap: _goToCategory,
                                onProductTap: _goToProduct,
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              size: 17,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 9),
          Text(
            _t('GiftCard', 'بطاقات الهدايا'),
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSearching;
  final bool isAr;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.isSearching,
    required this.isAr,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppShadows.action,
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: isAr ? 'ابحث عن بطاقة...' : 'Search cards...',
            hintStyle: GoogleFonts.cairo(
                fontSize: 14, color: AppColors.textHint),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.textHint, size: 20),
            suffixIcon: isSearching
                ? GestureDetector(
                    onTap: onClear,
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary, size: 20),
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            isDense: true,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Browse View  (categories + popular)
// ─────────────────────────────────────────────────────────────────────────────

class _BrowseView extends StatelessWidget {
  final bool isAr;
  final List<LikeCardCategory> categories;
  final List<LikeCardProduct> popular;
  final ValueChanged<LikeCardCategory> onCategoryTap;
  final ValueChanged<LikeCardProduct> onProductTap;

  const _BrowseView({
    super.key,
    required this.isAr,
    required this.categories,
    required this.popular,
    required this.onCategoryTap,
    required this.onProductTap,
  });

  String _t(String en, String ar) => isAr ? ar : en;

  @override
  Widget build(BuildContext context) {
    final cats = categories;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // ── Popular ────────────────────────────────────────────────────────
        _SectionHeader(label: _t('Popular', 'الأكثر طلباً')),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemCount: popular.length,
            itemBuilder: (_, i) => _PopularCard(
              product: popular[i],
              isAr: isAr,
              onTap: () => onProductTap(popular[i]),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ── Categories ─────────────────────────────────────────────────────
        _SectionHeader(label: _t('Categories', 'التصنيفات')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
            ),
            itemCount: cats.length,
            itemBuilder: (_, i) => _CategoryCard(
              category: cats[i],
              isAr: isAr,
              onTap: () => onCategoryTap(cats[i]),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Results View
// ─────────────────────────────────────────────────────────────────────────────

class _SearchResultsView extends StatelessWidget {
  final List<LikeCardProduct> results;
  final String query;
  final bool isAr;
  final bool loading;
  final List<LikeCardCategory> categories;
  final ValueChanged<LikeCardProduct> onTap;

  const _SearchResultsView({
    super.key,
    required this.results,
    required this.query,
    required this.isAr,
    required this.loading,
    required this.categories,
    required this.onTap,
  });

  String _t(String en, String ar) => isAr ? ar : en;

  LikeCardCategory? _categoryById(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return _SearchSkeleton();
    }
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56, color: AppColors.textHint.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              _t('No results for "$query"', 'لا نتائج لـ "$query"'),
              style: GoogleFonts.cairo(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: results.length,
      itemBuilder: (_, i) {
        final p = results[i];
        final cat = _categoryById(p.categoryId);
        return _SearchResultTile(
          product: p,
          categoryName: cat != null
              ? (isAr ? cat.nameAr : cat.nameEn)
              : '',
          isAr: isAr,
          onTap: () => onTap(p),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error View
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final bool isAr;
  final VoidCallback onRetry;

  const _ErrorView({super.key, required this.isAr, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 56, color: AppColors.textHint.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            isAr ? 'تعذر تحميل البيانات' : 'Failed to load data',
            style: GoogleFonts.cairo(
                color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              isAr ? 'إعادة المحاولة' : 'Retry',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ── Popular product horizontal card ──────────────────────────────────────────

class _PopularCard extends StatelessWidget {
  final LikeCardProduct product;
  final bool isAr;
  final VoidCallback onTap;

  const _PopularCard({
    required this.product,
    required this.isAr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.lg,
          boxShadow: AppShadows.action,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            _BrandAvatar(
                initial: product.initial,
                color: product.brandColor,
                imageUrl: product.imageUrl,
                size: 38),
            const Spacer(),
            // Name
            Text(
              isAr ? product.nameAr : product.nameEn,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Price
            Text(
              '${isAr ? 'من' : 'from'} ${_fmtSDG(product.minPriceSDG)}',
              style: GoogleFonts.cairo(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category grid card ────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final LikeCardCategory category;
  final bool isAr;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.isAr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.lg,
          boxShadow: AppShadows.card,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: category.iconUrl != null && category.iconUrl!.isNotEmpty
                  ? Image.network(
                      category.iconUrl!,
                      width: 26,
                      height: 26,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                          Icons.card_giftcard_rounded,
                          color: category.color, size: 24),
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Icon(Icons.card_giftcard_rounded,
                              color: category.color, size: 24),
                    )
                  : Icon(Icons.card_giftcard_rounded,
                      color: category.color, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isAr ? category.nameAr : category.nameEn,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${category.productCount} ${isAr ? 'منتج' : 'products'}',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search result tile ────────────────────────────────────────────────────────

class _SearchResultTile extends StatelessWidget {
  final LikeCardProduct product;
  final String categoryName;
  final bool isAr;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.product,
    required this.categoryName,
    required this.isAr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.lg,
          boxShadow: AppShadows.action,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _BrandAvatar(
                initial: product.initial,
                color: product.brandColor,
                imageUrl: product.imageUrl,
                size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? product.nameAr : product.nameEn,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    categoryName,
                    style: GoogleFonts.cairo(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isAr ? 'من' : 'from',
                  style: GoogleFonts.cairo(
                      fontSize: 10, color: AppColors.textHint),
                ),
                Text(
                  _fmtSDG(product.minPriceSDG),
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Bone extends StatelessWidget {
  final double w;
  final double h;
  final double? radius;
  const _Bone({required this.w, required this.h, this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.skeletonBase,
        borderRadius: BorderRadius.circular(radius ?? h / 2),
      ),
    );
  }
}

// Browse skeleton: popular row + categories grid
class _BrowseSkeleton extends StatelessWidget {
  const _BrowseSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Popular section header bone
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: _Bone(w: 100, h: 14),
        ),
        // Popular horizontal row
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemCount: 5,
            itemBuilder: (_, __) => Container(
              width: 130,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.lg,
                border: Border.all(color: AppColors.borderSoft),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bone(w: 38, h: 38, radius: 11),
                  const Spacer(),
                  _Bone(w: 80, h: 10),
                  const SizedBox(height: 5),
                  _Bone(w: 55, h: 9),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Categories section header bone
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: _Bone(w: 110, h: 14),
        ),
        // Categories grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
            ),
            itemCount: 6,
            itemBuilder: (_, __) => Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.lg,
                border: Border.all(color: AppColors.borderSoft),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  _Bone(w: 46, h: 46, radius: 13),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Bone(w: double.infinity, h: 11),
                        const SizedBox(height: 6),
                        _Bone(w: 50, h: 9),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Search skeleton: list of result tiles
class _SearchSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.lg,
          border: Border.all(color: AppColors.borderSoft),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _Bone(w: 46, h: 46, radius: 13),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bone(w: 120, h: 12),
                  const SizedBox(height: 6),
                  _Bone(w: 70, h: 10),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Bone(w: 30, h: 9),
                const SizedBox(height: 5),
                _Bone(w: 60, h: 11),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Brand avatar ──────────────────────────────────────────────────────────────

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
