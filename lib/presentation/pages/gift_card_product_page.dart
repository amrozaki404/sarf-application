import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/like_card_models.dart';
import '../../data/services/like_card_service.dart';

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
// Product Page
// ─────────────────────────────────────────────────────────────────────────────

class GiftCardProductPage extends StatefulWidget {
  final LikeCardProduct product;

  const GiftCardProductPage({super.key, required this.product});

  @override
  State<GiftCardProductPage> createState() => _GiftCardProductPageState();
}

class _GiftCardProductPageState extends State<GiftCardProductPage> {
  LikeCardDenomination? _selected;
  bool _isAr = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isAr = Localizations.localeOf(context).languageCode == 'ar';
  }

  String _t(String en, String ar) => _isAr ? ar : en;

  void _onBuy() {
    if (_selected == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CheckoutSheet(
        product: widget.product,
        denomination: _selected!,
        isAr: _isAr,
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
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                _buildSliverHeader(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      children: [
                        _buildDenominationsSection(),
                      ],
                    ),
                  ),
                ),
                // Extra space for sticky bar
                const SliverToBoxAdapter(child: SizedBox(height: 170)),
              ],
            ),
            // Sticky bottom bar
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

  // ── Sliver Header ──────────────────────────────────────────────────────────

  Widget _buildSliverHeader() {
    final p = widget.product;
    final accentDark = Color.lerp(p.brandColor, Colors.black, 0.42)!;

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      stretch: true,
      backgroundColor: accentDark,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      title: Text(
        _isAr ? p.nameAr : p.nameEn,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.cairo(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                p.brandColor,
                accentDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -24,
                top: -32,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                left: -40,
                bottom: 16,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                right: 56,
                bottom: 118,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 76, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    final p = widget.product;
    final previewLabel = _selected?.label ??
        _t(
          'Start with ${p.denominations.first.label}',
          'ابدأ بقيمة ${p.denominations.first.label}',
        );
    final previewPrice = _selected?.priceSDG ?? p.minPriceSDG;

    return Container(
      height: 158,
      decoration: BoxDecoration(
        borderRadius: AppRadii.xxl,
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.22),
            Colors.white.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -24,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            left: 26,
            bottom: -34,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _BrandIcon(
                      initial: p.initial,
                      color: p.brandColor,
                      imageUrl: p.imageUrl,
                      size: 52,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isAr ? p.nameAr : p.nameEn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _t('Instant code', 'كود فوري'),
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  previewLabel,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.76),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      _fmtSDG(previewPrice),
                      style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _t('Range', 'النطاق'),
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.65),
                          ),
                        ),
                        Text(
                          '${_fmtSDG(p.minPriceSDG)} - ${_fmtSDG(p.maxPriceSDG)}',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Denominations ──────────────────────────────────────────────────────────

  Widget _buildDenominationsSection() {
    final denoms = widget.product.denominations;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.xxl,
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('Choose your amount', 'اختر المبلغ المناسب'),
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...denoms.asMap().entries.map((entry) {
            final i = entry.key;
            final denomination = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: i == denoms.length - 1 ? 0 : 12),
              child: _DenominationCard(
                denomination: denomination,
                isSelected: _selected?.id == denomination.id,
                brandColor: widget.product.brandColor,
                isAr: _isAr,
                onTap: () => setState(() => _selected = denomination),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Bottom Bar ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.borderSoft.withOpacity(0.85)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _selected == null ? _buildSelectPrompt() : _buildBuyBar(),
          const SizedBox(height: 14),
          AppButton(
            label: _selected == null
                ? _t('Select an amount', 'اختر مبلغاً')
                : _t('Continue to checkout', 'المتابعة للدفع'),
            onPressed: _selected == null ? null : _onBuy,
            height: 56,
            borderRadius: AppRadii.lg,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectPrompt() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('Select an amount to continue', 'اختر مبلغاً للمتابعة'),
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _t(
                  'Available range ${_fmtSDG(widget.product.minPriceSDG)} - ${_fmtSDG(widget.product.maxPriceSDG)}',
                  'النطاق المتاح ${_fmtSDG(widget.product.minPriceSDG)} - ${_fmtSDG(widget.product.maxPriceSDG)}',
                ),
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          _fmtSDG(widget.product.minPriceSDG),
          style: GoogleFonts.cairo(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildBuyBar() {
    return Row(
      children: [
        // Price info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selected!.label,
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          _fmtSDG(_selected!.priceSDG),
          style: GoogleFonts.cairo(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Denomination Card
// ─────────────────────────────────────────────────────────────────────────────

class _DenominationCard extends StatelessWidget {
  final LikeCardDenomination denomination;
  final bool isSelected;
  final Color brandColor;
  final bool isAr;
  final VoidCallback onTap;

  const _DenominationCard({
    required this.denomination,
    required this.isSelected,
    required this.brandColor,
    required this.isAr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentShade = Color.lerp(brandColor, AppColors.primary, 0.35)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.xl,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? accentShade.withOpacity(0.08) : AppColors.surface,
            borderRadius: AppRadii.xl,
            border: Border.all(
              color: isSelected ? accentShade : AppColors.borderSoft,
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentShade.withOpacity(0.14)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  denomination.label.split(' ').first,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? accentShade : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      denomination.label,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmtSDG(denomination.priceSDG),
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? accentShade : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentShade.withOpacity(0.14)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isSelected
                          ? (isAr ? 'محدد' : 'Selected')
                          : (isAr ? 'اضغط للاختيار' : 'Tap to choose'),
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? accentShade : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandIcon extends StatelessWidget {
  final String initial;
  final Color color;
  final String? imageUrl;
  final double size;

  const _BrandIcon({
    required this.initial,
    required this.color,
    required this.imageUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color.computeLuminance() > 0.6 ? Colors.black87 : Colors.white;
    final radius = BorderRadius.circular(size * 0.28);

    Widget fallback = Center(
      child: Text(
        initial,
        style: TextStyle(
          color: textColor,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w900,
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

// ─────────────────────────────────────────────────────────────────────────────
// Checkout Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CheckoutSheet extends StatefulWidget {
  final LikeCardProduct product;
  final LikeCardDenomination denomination;
  final bool isAr;

  const _CheckoutSheet({
    required this.product,
    required this.denomination,
    required this.isAr,
  });

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  bool _loading = false;
  String? _errorMessage;

  String _t(String en, String ar) => widget.isAr ? ar : en;

  Future<void> _confirm() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final order = await LikeCardService.createOrder(
        productId: widget.product.id,
        denominationId: widget.denomination.id,
      );
      if (!mounted) return;
      if (order == null) {
        setState(() {
          _loading = false;
          _errorMessage = _t(
              'Could not complete your purchase. Please try again.',
              'تعذر إتمام عملية الشراء. حاول مرة أخرى.');
        });
        return;
      }
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = _t(
            'Network error. Please check your connection.',
            'خطأ في الاتصال. تحقق من الشبكة.');
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
            _buildForm(),
          ],
        ),
      ),
    );
  }

  // ── Form ───────────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          _t('Review purchase', 'مراجعة الشراء'),
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Product + denomination row
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: AppRadii.lg,
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Row(
            children: [
              _BrandIcon(
                initial: widget.product.initial,
                color: widget.product.brandColor,
                imageUrl: widget.product.imageUrl,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isAr
                          ? widget.product.nameAr
                          : widget.product.nameEn,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.denomination.label,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Price
              Text(
                _fmtSDG(widget.denomination.priceSDG),
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Divider(color: AppColors.borderSoft),
        const SizedBox(height: 20),

        // Error message (if any)
        if (_errorMessage != null) ...[
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Confirm button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: AppButton(
            label: _t('Confirm & Pay', 'تأكيد والدفع'),
            onPressed: _confirm,
            isLoading: _loading,
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            _t('Amount will be deducted from your wallet',
                'سيتم الخصم من محفظتك'),
            style: GoogleFonts.cairo(
                fontSize: 11, color: AppColors.textHint),
          ),
        ),
      ],
    );
  }

}
