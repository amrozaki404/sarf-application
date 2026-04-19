import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/digital_subscription_models.dart';
import '../../data/services/digital_subscription_service.dart';
import 'digital_subscription_detail_page.dart';

String _fmtSDG(double v) {
  final s = v.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '$buf';
}

// ─────────────────────────────────────────────────────────────────────────────
// Browse Page
// ─────────────────────────────────────────────────────────────────────────────

class DigitalSubscriptionsPage extends StatefulWidget {
  const DigitalSubscriptionsPage({super.key});

  @override
  State<DigitalSubscriptionsPage> createState() =>
      _DigitalSubscriptionsPageState();
}

class _DigitalSubscriptionsPageState extends State<DigitalSubscriptionsPage> {
  final _searchCtrl = TextEditingController();
  SubCategory _selectedCat = SubCategory.all;
  List<DigitalSubscription> _all = [];
  List<DigitalSubscription> _filtered = [];
  bool _loading = true;
  String? _error;

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';
  String _t(String en, String ar) => _isAr ? ar : en;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_applyFilters);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl
      ..removeListener(_applyFilters)
      ..dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final subs = await DigitalSubscriptionService.getSubscriptions();
      if (!mounted) return;
      setState(() {
        _all = subs;
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

  void _applyFilters() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = _all.where((s) {
        final matchCat =
            _selectedCat == SubCategory.all || s.category == _selectedCat;
        final matchQ = q.isEmpty ||
            s.nameEn.toLowerCase().contains(q) ||
            s.nameAr.contains(q);
        return matchCat && matchQ;
      }).toList();
    });
  }

  void _openDetail(DigitalSubscription sub) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DigitalSubscriptionDetailPage(subscription: sub),
      ),
    );
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
            _buildSearch(),
            _buildCategoryStrip(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(
          _isAr ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_rounded,
          size: 18,
          color: AppColors.textPrimary,
        ),
      ),
      title: Text(
        _t('Digital Subscriptions', 'الاشتراكات الرقمية'),
        style: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.borderSoft),
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSoft),
          boxShadow: AppShadows.action,
        ),
        child: TextField(
          controller: _searchCtrl,
          style: GoogleFonts.cairo(
              fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: _t('Search subscriptions…', 'ابحث عن اشتراك…'),
            hintStyle: GoogleFonts.cairo(
                fontSize: 14, color: AppColors.textHint),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.textHint, size: 19),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      FocusScope.of(context).unfocus();
                    },
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary, size: 17),
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

  Widget _buildCategoryStrip() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        scrollDirection: Axis.horizontal,
        itemCount: SubCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = SubCategory.values[i];
          final sel = _selectedCat == cat;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCat = cat);
              _applyFilters();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: sel ? AppColors.primary : AppColors.borderSoft,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat.icon,
                      size: 13,
                      color: sel ? Colors.white : AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    _isAr ? cat.labelAr : cat.labelEn,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color:
                          sel ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => const _SkeletonCard(),
      );
    }
    if (_error != null) {
      return _ErrorState(onRetry: _load, isAr: _isAr);
    }
    if (_filtered.isEmpty) {
      return _EmptyState(isAr: _isAr);
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _SubCard(
          sub: _filtered[i],
          isAr: _isAr,
          onTap: () => _openDetail(_filtered[i]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// List card
// ─────────────────────────────────────────────────────────────────────────────

class _SubCard extends StatelessWidget {
  final DigitalSubscription sub;
  final bool isAr;
  final VoidCallback onTap;

  const _SubCard({
    required this.sub,
    required this.isAr,
    required this.onTap,
  });

  String _fmtCount(int n) => n >= 1000
      ? '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k'
      : '$n';

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
                SubBrandAvatar(sub: sub, size: 58),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isAr ? sub.nameAr : sub.nameEn,
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (sub.isPopular) ...[
                            const SizedBox(width: 6),
                            _Badge(
                              label: isAr ? 'الأكثر مبيعاً' : 'Popular',
                              color: const Color(0xFFEA580C),
                              bg: const Color(0xFFFFF7ED),
                              border: const Color(0xFFFED7AA),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Rating + sold
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 13, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 3),
                          Text(
                            sub.rating.toStringAsFixed(1),
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${_fmtCount(sub.reviewCount)})',
                            style: GoogleFonts.cairo(
                                fontSize: 11, color: AppColors.textHint),
                          ),
                          const Spacer(),
                          Text(
                            isAr
                                ? '${_fmtCount(sub.purchaseCount)} عملية شراء'
                                : '${_fmtCount(sub.purchaseCount)} sold',
                            style: GoogleFonts.cairo(
                                fontSize: 11, color: AppColors.textHint),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Price
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: isAr ? 'يبدأ من ' : 'From ',
                            style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: AppColors.textSecondary),
                          ),
                          TextSpan(
                            text: _fmtSDG(sub.startingMonthlyPrice),
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                          TextSpan(
                            text: isAr ? '/شهر' : '/mo',
                            style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: AppColors.textSecondary),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textHint, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Public: Brand avatar — shared with detail page
// ─────────────────────────────────────────────────────────────────────────────

class SubBrandAvatar extends StatelessWidget {
  final DigitalSubscription sub;
  final double size;

  const SubBrandAvatar({super.key, required this.sub, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = sub.brandColor;
    final radius = BorderRadius.circular(size * 0.26);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: size,
        height: size,
        color: color,
        child: sub.imageUrl != null && sub.imageUrl!.isNotEmpty
            ? Image.network(
                sub.imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : const SizedBox.shrink(),
              )
            : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable badge
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final Color border;

  const _Badge({
    required this.label,
    required this.color,
    required this.bg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
            fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.lg,
        border: Border.all(color: AppColors.borderSoft),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.skeletonBase,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Bone(w: 130, h: 13),
                const SizedBox(height: 8),
                _Bone(w: 90, h: 10),
                const SizedBox(height: 8),
                _Bone(w: 70, h: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  final double w;
  final double h;
  const _Bone({required this.w, required this.h});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: AppColors.skeletonBase,
        borderRadius: BorderRadius.circular(h / 2),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error / Empty states
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final bool isAr;
  const _ErrorState({required this.onRetry, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            isAr ? 'تعذر التحميل' : 'Failed to load',
            style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(isAr ? 'إعادة المحاولة' : 'Retry',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isAr;
  const _EmptyState({required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            isAr ? 'لا توجد نتائج' : 'No results found',
            style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
