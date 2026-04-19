import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/digital_subscription_models.dart';
import '../../data/services/digital_subscription_service.dart';
import 'digital_subscriptions_page.dart' show SubBrandAvatar;

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _sdg(double v) {
  final s = v.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '$buf';
}

String _fmtK(int n) =>
    n >= 1000 ? '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k' : '$n';

// ─────────────────────────────────────────────────────────────────────────────
// Detail Page
// ─────────────────────────────────────────────────────────────────────────────

class DigitalSubscriptionDetailPage extends StatefulWidget {
  final DigitalSubscription subscription;

  const DigitalSubscriptionDetailPage({
    super.key,
    required this.subscription,
  });

  @override
  State<DigitalSubscriptionDetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DigitalSubscriptionDetailPage> {
  SubDuration? _selected;
  bool _isAr = false;
  List<SubReview> _reviews = [];
  bool _reviewsLoading = true;

  DigitalSubscription get _sub => widget.subscription;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final reviews =
          await DigitalSubscriptionService.getReviews(_sub.id);
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _reviewsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _reviewsLoading = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isAr = Localizations.localeOf(context).languageCode == 'ar';
  }

  String _t(String en, String ar) => _isAr ? ar : en;

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              _isAr
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.arrow_back_ios_rounded,
              size: 18,
              color: AppColors.textPrimary,
            ),
          ),
          title: Text(
            _isAr ? _sub.nameAr : _sub.nameEn,
            style: GoogleFonts.cairo(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.borderSoft),
          ),
        ),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 160),
              children: [
                _buildStatsStrip(),
                const SizedBox(height: 16),
                _buildPlansSection(),
                const SizedBox(height: 16),
                _buildFeaturesSection(),
                const SizedBox(height: 16),
                _buildReviewsSection(),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomBar(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats strip ────────────────────────────────────────────────────────────

  Widget _buildStatsStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.lg,
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              value: _sub.rating.toStringAsFixed(1),
              label: _t('Rating', 'التقييم'),
              icon: Icons.star_rounded,
              iconColor: const Color(0xFFF59E0B),
            ),
          ),
          _VertDivider(),
          Expanded(
            child: _StatItem(
              value: _fmtK(_sub.reviewCount),
              label: _t('Reviews', 'تقييمات'),
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: AppColors.primary,
            ),
          ),
          _VertDivider(),
          Expanded(
            child: _StatItem(
              value: _fmtK(_sub.purchaseCount),
              label: _t('Sold', 'عملية شراء'),
              icon: Icons.shopping_bag_outlined,
              iconColor: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Plans ──────────────────────────────────────────────────────────────────

  Widget _buildPlansSection() {
    return _Section(
      title: _t('Choose your plan', 'اختر باقتك'),
      subtitle: _t(
        'Longer plans give better value per month',
        'الباقات الأطول تعني توفيراً أكبر شهرياً',
      ),
      child: Column(
        children: _sub.durations.asMap().entries.map((e) {
          final i = e.key;
          final dur = e.value;
          return Padding(
            padding:
                EdgeInsets.only(bottom: i < _sub.durations.length - 1 ? 10 : 0),
            child: _PlanCard(
              duration: dur,
              isSelected: _selected?.id == dur.id,
              brandColor: _sub.brandColor,
              isAr: _isAr,
              onTap: () => setState(() => _selected = dur),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Features ───────────────────────────────────────────────────────────────

  Widget _buildFeaturesSection() {
    final features = _isAr ? _sub.featuresAr : _sub.featuresEn;
    return _Section(
      title: _t("What's included", 'ما يشمله الاشتراك'),
      subtitle: _isAr ? _sub.descAr : _sub.descEn,
      child: Column(
        children: features
            .map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            size: 12, color: AppColors.secondary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          f,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ── Reviews ────────────────────────────────────────────────────────────────

  Widget _buildReviewsSection() {
    Widget reviewsBody;
    if (_reviewsLoading) {
      reviewsBody = const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
            child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2)),
      );
    } else if (_reviews.isEmpty) {
      reviewsBody = Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          _t('No reviews yet. Be the first!', 'لا توجد تقييمات بعد. كن الأول!'),
          style: GoogleFonts.cairo(
              fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    } else {
      reviewsBody = Column(
        children: [
          _RatingSummary(sub: _sub, isAr: _isAr),
          const SizedBox(height: 16),
          ..._reviews.asMap().entries.map((e) => Column(
                children: [
                  if (e.key > 0)
                    const Divider(
                        height: 20, thickness: 1, color: AppColors.borderSoft),
                  _ReviewTile(review: e.value, isAr: _isAr),
                ],
              )),
        ],
      );
    }

    return _Section(
      title: _t('Reviews', 'التقييمات'),
      action: _WriteReviewButton(
        label: _t('Write a review', 'أضف تقييمك'),
        onTap: _openWriteReview,
      ),
      child: reviewsBody,
    );
  }

  void _openWriteReview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WriteReviewSheet(
        sub: _sub,
        isAr: _isAr,
        onSubmitted: _loadReviews,
      ),
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(top: BorderSide(color: AppColors.borderSoft)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Row(
        children: [
          // Price display
          Expanded(
            child: _selected == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _t('Select a plan', 'اختر باقة'),
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _t(
                          'From ${_sdg(_sub.startingMonthlyPrice)}/mo',
                          'من ${_sdg(_sub.startingMonthlyPrice)}/شهر',
                        ),
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _sdg(_selected!.totalPrice),
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          height: 1,
                        ),
                      ),
                      Text(
                        '${_sdg(_selected!.monthlyPrice)} ${_t('/month', '/شهر')}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 16),
          // CTA button
          SizedBox(
            width: 160,
            child: AppButton(
              label: _t('Subscribe', 'اشترك الآن'),
              onPressed: _selected == null ? null : _openCheckout,
              height: 50,
              borderRadius: AppRadii.lg,
            ),
          ),
        ],
      ),
    );
  }

  void _openCheckout() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CheckoutSheet(
        sub: _sub,
        duration: _selected!,
        isAr: _isAr,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable: Section card
// ─────────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;

  const _Section({
    required this.title,
    this.subtitle,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.xl,
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat item (in hero)
// ─────────────────────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textHint),
        ),
      ],
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      color: AppColors.borderSoft,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan card
// ─────────────────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final SubDuration duration;
  final bool isSelected;
  final Color brandColor;
  final bool isAr;
  final VoidCallback onTap;

  const _PlanCard({
    required this.duration,
    required this.isSelected,
    required this.brandColor,
    required this.isAr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Color.lerp(brandColor, AppColors.primary, 0.3)!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? accent.withAlpha(12) : AppColors.background,
          borderRadius: AppRadii.lg,
          border: Border.all(
            color: isSelected ? accent : AppColors.borderSoft,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accent : Colors.transparent,
                border: Border.all(
                  color: isSelected ? accent : AppColors.borderSoft,
                  width: isSelected ? 0 : 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            // Label + monthly
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isAr ? duration.labelAr : duration.labelEn,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (duration.isBestValue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withAlpha(20),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isAr ? 'الأوفر' : 'Best value',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '${_sdg(duration.monthlyPrice)} ${isAr ? 'شهرياً' : '/month'}',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: isSelected
                          ? accent.withAlpha(200)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Total price
            Text(
              _sdg(duration.totalPrice),
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: isSelected ? accent : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rating summary (aggregate)
// ─────────────────────────────────────────────────────────────────────────────

class _RatingSummary extends StatelessWidget {
  final DigitalSubscription sub;
  final bool isAr;

  const _RatingSummary({required this.sub, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadii.lg,
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          // Big number
          Column(
            children: [
              Text(
                sub.rating.toStringAsFixed(1),
                style: GoogleFonts.cairo(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < sub.rating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_fmtK(sub.reviewCount)} ${isAr ? 'تقييم' : 'reviews'}',
                style:
                    GoogleFonts.cairo(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Bar breakdown (5→1)
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                // Approximate distribution
                final frac = star == 5
                    ? 0.75
                    : star == 4
                        ? 0.15
                        : star == 3
                            ? 0.06
                            : star == 2
                                ? 0.03
                                : 0.01;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: AppColors.textHint),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded,
                          size: 10, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: frac,
                            backgroundColor: AppColors.borderSoft,
                            color: const Color(0xFFF59E0B),
                            minHeight: 5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Review tile
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewTile extends StatelessWidget {
  final SubReview review;
  final bool isAr;

  const _ReviewTile({required this.review, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.background,
              child: Text(
                review.authorName.isNotEmpty
                    ? review.authorName[0].toUpperCase()
                    : '?',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.authorName,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    review.date,
                    style: GoogleFonts.cairo(
                        fontSize: 11, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
            // Stars
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < review.rating.round()
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 13,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          review.comment,
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Write a review" inline button
// ─────────────────────────────────────────────────────────────────────────────

class _WriteReviewButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _WriteReviewButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.primary.withAlpha(40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_outlined, size: 13, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Write Review Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _WriteReviewSheet extends StatefulWidget {
  final DigitalSubscription sub;
  final bool isAr;
  final VoidCallback? onSubmitted;

  const _WriteReviewSheet({
    required this.sub,
    required this.isAr,
    this.onSubmitted,
  });

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  int _stars = 0;
  final _commentCtrl = TextEditingController();
  bool _loading = false;
  bool _done = false;

  String _t(String en, String ar) => widget.isAr ? ar : en;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(_t('Please select a star rating', 'الرجاء اختيار عدد النجوم')),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ));
      return;
    }
    if (_commentCtrl.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t('Please write at least a short comment',
            'الرجاء كتابة تعليق مختصر على الأقل')),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      final ok = await DigitalSubscriptionService.submitReview(
        subscriptionId: widget.sub.id,
        rating: _stars,
        comment: _commentCtrl.text.trim(),
      );
      if (!mounted) return;
      if (!ok) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_t(
            'Could not submit review. You may have already reviewed this.',
            'تعذّر إرسال التقييم. ربما قيّمت هذا الاشتراك من قبل.',
          )),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ));
        return;
      }
      setState(() {
        _loading = false;
        _done = true;
      });
      widget.onSubmitted?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t(
          'Network error. Check your connection.',
          'خطأ في الاتصال. تحقق من الشبكة.',
        )),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ));
    }
  }

  static const _labels = [
    ['Terrible', 'سيئ جداً'],
    ['Bad', 'سيئ'],
    ['OK', 'مقبول'],
    ['Good', 'جيد'],
    ['Excellent', 'ممتاز'],
  ];

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _done ? _buildDone() : _buildForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildDone() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                size: 36, color: AppColors.secondary),
          ),
          const SizedBox(height: 14),
          Text(
            _t('Thank you!', 'شكراً لك!'),
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _t('Your review has been submitted.', 'تم إرسال تقييمك بنجاح.'),
            style:
                GoogleFonts.cairo(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: _t('Close', 'إغلاق'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product row
        Row(
          children: [
            SubBrandAvatar(sub: widget.sub, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isAr ? widget.sub.nameAr : widget.sub.nameEn,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _t('Share your experience', 'شارك تجربتك'),
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Star picker
        Text(
          _t('Your rating', 'تقييمك'),
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(5, (i) {
            final filled = i < _stars;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _stars = i + 1);
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 150),
                  scale: filled ? 1.15 : 1.0,
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 36,
                    color:
                        filled ? const Color(0xFFF59E0B) : AppColors.borderSoft,
                  ),
                ),
              ),
            );
          }),
        ),
        if (_stars > 0) ...[
          const SizedBox(height: 6),
          Text(
            widget.isAr ? _labels[_stars - 1][1] : _labels[_stars - 1][0],
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF59E0B),
            ),
          ),
        ],
        const SizedBox(height: 18),

        // Comment field
        Text(
          _t('Your comment', 'تعليقك'),
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: TextField(
            controller: _commentCtrl,
            minLines: 3,
            maxLines: 5,
            maxLength: 300,
            style:
                GoogleFonts.cairo(fontSize: 13, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: _t(
                'Tell others about your experience with this subscription…',
                'أخبر الآخرين عن تجربتك مع هذا الاشتراك…',
              ),
              hintStyle:
                  GoogleFonts.cairo(fontSize: 13, color: AppColors.textHint),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
              isDense: true,
              counterStyle:
                  GoogleFonts.cairo(fontSize: 11, color: AppColors.textHint),
            ),
          ),
        ),
        const SizedBox(height: 20),

        AppButton(
          label: _t('Submit Review', 'إرسال التقييم'),
          onPressed: _submit,
          isLoading: _loading,
          height: 52,
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Checkout Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CheckoutSheet extends StatefulWidget {
  final DigitalSubscription sub;
  final SubDuration duration;
  final bool isAr;

  const _CheckoutSheet({
    required this.sub,
    required this.duration,
    required this.isAr,
  });

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, FocusNode> _focusNodes;
  bool _loading = false;
  String? _formError;
  bool _success = false;

  String _t(String en, String ar) => widget.isAr ? ar : en;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final f in widget.sub.fields) f.fieldKey: TextEditingController(),
    };
    _focusNodes = {
      for (final f in widget.sub.fields) f.fieldKey: FocusNode(),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    for (final n in _focusNodes.values) n.dispose();
    super.dispose();
  }

  bool _validEmail(String v) =>
      RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim());

  Future<void> _confirm() async {
    for (final field in widget.sub.fields) {
      final val = _controllers[field.fieldKey]?.text.trim() ?? '';
      if (field.required && val.isEmpty) {
        final label = widget.isAr ? field.labelAr : field.labelEn;
        setState(() => _formError =
            _t('$label is required', '$label مطلوب'));
        _focusNodes[field.fieldKey]?.requestFocus();
        return;
      }
      if (field.fieldType == 'EMAIL' && val.isNotEmpty && !_validEmail(val)) {
        setState(() => _formError =
            _t('Enter a valid email', 'أدخل بريداً إلكترونياً صحيحاً'));
        _focusNodes[field.fieldKey]?.requestFocus();
        return;
      }
    }
    setState(() {
      _loading = true;
      _formError = null;
    });
    try {
      final fieldValues = <String, String>{
        for (final f in widget.sub.fields)
          if ((_controllers[f.fieldKey]?.text.trim() ?? '').isNotEmpty)
            f.fieldKey: _controllers[f.fieldKey]!.text.trim(),
      };
      final ok = await DigitalSubscriptionService.createOrder(
        subscriptionId: widget.sub.id,
        planId: widget.duration.id,
        fieldValues: fieldValues,
      );
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _loading = false;
          _formError = _t(
            'Purchase failed. Please try again.',
            'فشلت عملية الشراء. حاول مرة أخرى.',
          );
        });
        return;
      }
      setState(() {
        _loading = false;
        _success = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _formError = _t(
          'Network error. Check your connection.',
          'خطأ في الاتصال. تحقق من الشبكة.',
        );
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _success ? _buildSuccess() : _buildForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                size: 36, color: AppColors.secondary),
          ),
          const SizedBox(height: 14),
          Text(
            _t('Order placed!', 'تم الطلب بنجاح!'),
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _controllers['email']?.text.trim().isNotEmpty == true
                  ? _t(
                      'Your subscription will be activated on ${_controllers['email']!.text.trim()}.\nActivation hours: 10 AM – 12 AM.',
                      'سيتم التفعيل على ${_controllers['email']!.text.trim()}.\nأوقات التفعيل: 10 ص – 12 م.',
                    )
                  : _t(
                      'Your subscription is being processed. You will receive a confirmation shortly.',
                      'جارٍ معالجة اشتراكك. ستصلك رسالة تأكيد قريباً.',
                    ),
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: _t('Done', 'إغلاق'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildFieldInput(SubField field) {
    final label = widget.isAr ? field.labelAr : field.labelEn;
    final ctrl = _controllers[field.fieldKey]!;
    final focus = _focusNodes[field.fieldKey]!;
    final keyboardType = switch (field.fieldType) {
      'EMAIL' => TextInputType.emailAddress,
      'PHONE' => TextInputType.phone,
      'NUMBER' => TextInputType.number,
      _ => TextInputType.text,
    };
    final icon = switch (field.fieldType) {
      'EMAIL' => Icons.email_outlined,
      'PHONE' => Icons.phone_outlined,
      'NUMBER' => Icons.tag_rounded,
      _ => Icons.edit_outlined,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (field.required) ...[
                const SizedBox(width: 3),
                const Text('*',
                    style: TextStyle(color: AppColors.error, fontSize: 13)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: AppRadii.md,
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: TextField(
              controller: ctrl,
              focusNode: focus,
              keyboardType: keyboardType,
              textDirection: field.fieldType == 'EMAIL' || field.fieldType == 'NUMBER'
                  ? TextDirection.ltr
                  : null,
              onChanged: (_) {
                if (_formError != null) setState(() => _formError = null);
              },
              style: GoogleFonts.cairo(
                  fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: label,
                hintStyle:
                    GoogleFonts.cairo(fontSize: 14, color: AppColors.textHint),
                prefixIcon:
                    Icon(icon, size: 18, color: AppColors.textHint),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('Review your order', 'مراجعة طلبك'),
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),

        // Order summary
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: AppRadii.lg,
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Row(
            children: [
              SubBrandAvatar(sub: widget.sub, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isAr ? widget.sub.nameAr : widget.sub.nameEn,
                      style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary),
                    ),
                    Text(
                      widget.isAr
                          ? widget.duration.labelAr
                          : widget.duration.labelEn,
                      style: GoogleFonts.cairo(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _sdg(widget.duration.totalPrice),
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '${_sdg(widget.duration.monthlyPrice)}/${_t('mo', 'شهر')}',
                    style: GoogleFonts.cairo(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Dynamic fields
        if (widget.sub.fields.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...widget.sub.fields.map((f) => _buildFieldInput(f)),
          if (_formError != null) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 13, color: AppColors.error),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(_formError!,
                      style: GoogleFonts.cairo(
                          fontSize: 11, color: AppColors.error)),
                ),
              ],
            ),
          ],
        ] else if (_formError != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 13, color: AppColors.error),
              const SizedBox(width: 4),
              Expanded(
                child: Text(_formError!,
                    style:
                        GoogleFonts.cairo(fontSize: 11, color: AppColors.error)),
              ),
            ],
          ),
        ],

        const SizedBox(height: 20),
        AppButton(
          label: _t('Confirm & Pay', 'تأكيد والدفع'),
          onPressed: _confirm,
          isLoading: _loading,
          height: 52,
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            _t('Deducted from your wallet', 'سيتم الخصم من محفظتك'),
            style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textHint),
          ),
        ),
      ],
    );
  }
}
