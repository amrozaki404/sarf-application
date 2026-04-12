import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/receipt_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Status style data
// ─────────────────────────────────────────────────────────────────────────────

class _StatusStyle {
  final IconData icon;
  final Color color;
  final Color lightBg;
  final LinearGradient gradient;

  const _StatusStyle({
    required this.icon,
    required this.color,
    required this.lightBg,
    required this.gradient,
  });

  static _StatusStyle of(String? status) {
    switch ((status ?? '').trim().toUpperCase()) {
      case 'SUCCESS':
      case 'COMPLETED':
      case 'APPROVED':
        return const _StatusStyle(
          icon: Icons.check_circle_rounded,
          color: Color(0xFF16A34A),
          lightBg: Color(0xFFDCFCE7),
          gradient: LinearGradient(
            colors: [Color(0xFF15803D), Color(0xFF22C55E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case 'PENDING':
      case 'UNDER_REVIEW':
      case 'PROCESSING':
        return const _StatusStyle(
          icon: Icons.schedule_rounded,
          color: Color(0xFFD97706),
          lightBg: Color(0xFFFEF3C7),
          gradient: LinearGradient(
            colors: [Color(0xFFB45309), Color(0xFFF59E0B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case 'FAILED':
      case 'REJECTED':
      case 'CANCELLED':
        return const _StatusStyle(
          icon: Icons.cancel_rounded,
          color: Color(0xFFDC2626),
          lightBg: Color(0xFFFEE2E2),
          gradient: LinearGradient(
            colors: [Color(0xFFB91C1C), Color(0xFFEF4444)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      default:
        return const _StatusStyle(
          icon: Icons.receipt_long_rounded,
          color: AppColors.primary,
          lightBg: Color(0xFFEFF6FF),
          gradient: AppColors.headerGradient,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class TransactionReceiptPage extends StatefulWidget {
  final TransactionReceipt receipt;

  const TransactionReceiptPage({super.key, required this.receipt});

  @override
  State<TransactionReceiptPage> createState() => _TransactionReceiptPageState();
}

class _TransactionReceiptPageState extends State<TransactionReceiptPage>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _iconScale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..forward();
    _iconScale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.30, 1.0, curve: Curves.easeOut),
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _copyId() {
    final id = widget.receipt.transactionId;
    if (id == null) return;
    Clipboard.setData(ClipboardData(text: id));
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr ? 'تم نسخ رقم العملية' : 'Transaction ID copied',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final receipt = widget.receipt;
    final style = _StatusStyle.of(receipt.transactionStatus);
    final amountColor = receipt.isCredit == true
        ? Colors.white
        : receipt.isCredit == false
            ? const Color(0xFFFFCDD2)
            : Colors.white;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: Stack(
          children: [
            // Status-coloured gradient header
            Container(
              height: MediaQuery.of(context).size.height * 0.36,
              decoration: BoxDecoration(gradient: style.gradient),
            ),
            SafeArea(
              child: Column(
                children: [
                  // Nav bar
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        _CircleNavBtn(
                          icon: isAr
                              ? Icons.arrow_forward_ios_rounded
                              : Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              isAr ? 'الإيصال' : 'Receipt',
                              style: GoogleFonts.cairo(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Status icon
                  ScaleTransition(
                    scale: _iconScale,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.14),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(style.icon, color: style.color, size: 42),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeTransition(
                    opacity: _fade,
                    child: Column(
                      children: [
                        if (receipt.amountWithCurrency.isNotEmpty)
                          Text(
                            receipt.amountWithCurrency,
                            style: GoogleFonts.cairo(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: amountColor,
                              height: 1.1,
                            ),
                          ),
                        const SizedBox(height: 6),
                        if ((receipt.transactionStatus ?? '').isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.32),
                              ),
                            ),
                            child: Text(
                              receipt.transactionStatus!,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Receipt body
                  Expanded(
                    child: SlideTransition(
                      position: _slideUp,
                      child: FadeTransition(
                        opacity: _fade,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                          ),
                          child: SingleChildScrollView(
                            padding:
                                const EdgeInsets.fromLTRB(16, 20, 16, 8),
                            child: Column(
                              children: [
                                _MainReceiptCard(
                                  isAr: isAr,
                                  receipt: receipt,
                                  style: style,
                                  onCopyId: _copyId,
                                ),
                                if (receipt.transactionFields.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _ExtraFieldsCard(
                                    isAr: isAr,
                                    fields: receipt.transactionFields,
                                  ),
                                ],
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Done button
                  Container(
                    color: const Color(0xFFF1F5F9),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      MediaQuery.of(context).padding.bottom + 12,
                    ),
                    child: AppButton(
                      label: isAr ? 'تم' : 'Done',
                      onPressed: () => Navigator.of(context).pop(),
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

// ─────────────────────────────────────────────────────────────────────────────
// Main receipt card (bank-style)
// ─────────────────────────────────────────────────────────────────────────────

class _MainReceiptCard extends StatelessWidget {
  final bool isAr;
  final TransactionReceipt receipt;
  final _StatusStyle style;
  final VoidCallback onCopyId;

  const _MainReceiptCard({
    required this.isAr,
    required this.receipt,
    required this.style,
    required this.onCopyId,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <_RowEntry>[
      if ((receipt.tranType?.trim() ?? '').isNotEmpty)
        _RowEntry(isAr ? 'نوع العملية' : 'Transaction Type', receipt.tranType!),
      if ((receipt.tranDate?.trim() ?? '').isNotEmpty)
        _RowEntry(isAr ? 'التاريخ' : 'Date', receipt.tranDate!),
      if ((receipt.tranTime?.trim() ?? '').isNotEmpty)
        _RowEntry(isAr ? 'الوقت' : 'Time', receipt.tranTime!),
      if ((receipt.feeAmount?.trim() ?? '').isNotEmpty)
        _RowEntry(isAr ? 'الرسوم' : 'Fee', receipt.feeAmount!),
      if ((receipt.beneficiaryName?.trim() ?? '').isNotEmpty)
        _RowEntry(isAr ? 'المستفيد' : 'Beneficiary', receipt.beneficiaryName!),
      if ((receipt.beneficiaryValue?.trim() ?? '').isNotEmpty)
        _RowEntry(
            isAr ? 'القيمة' : 'Beneficiary Value', receipt.beneficiaryValue!),
    ];

    final hasId = (receipt.transactionId ?? '').isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.xl,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Status header strip ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: BoxDecoration(
              color: style.lightBg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: style.color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(style.icon, color: style.color, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'إيصال العملية' : 'Transaction Receipt',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if ((receipt.tranDescription ?? '').isNotEmpty)
                        Text(
                          receipt.tranDescription!,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if ((receipt.transactionStatus ?? '').isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: style.color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      receipt.transactionStatus!,
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // ── Detail rows ─────────────────────────────────────────────────
          if (rows.isNotEmpty) ...[
            const _PerforationDivider(),
            ...rows.asMap().entries.map(
                  (e) => _BankRow(
                    label: e.value.label,
                    value: e.value.value,
                    shaded: e.key.isEven,
                  ),
                ),
          ],
          // ── Transaction ID ───────────────────────────────────────────────
          if (hasId) ...[
            const _PerforationDivider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              child: _TxIdRow(
                isAr: isAr,
                id: receipt.transactionId!,
                onCopy: onCopyId,
              ),
            ),
          ] else
            const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Extra fields card
// ─────────────────────────────────────────────────────────────────────────────

class _ExtraFieldsCard extends StatelessWidget {
  final bool isAr;
  final List<TransactionReceiptField> fields;

  const _ExtraFieldsCard({required this.isAr, required this.fields});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.xl,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 17,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  isAr ? 'تفاصيل إضافية' : 'Additional Details',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ...fields.asMap().entries.map(
                (e) => _BankRow(
                  label: e.value.label,
                  value: e.value.value,
                  shaded: e.key.isEven,
                ),
              ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _RowEntry {
  final String label;
  final String value;
  const _RowEntry(this.label, this.value);
}

class _BankRow extends StatelessWidget {
  final String label;
  final String value;
  final bool shaded;

  const _BankRow({
    required this.label,
    required this.value,
    this.shaded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: shaded ? const Color(0xFFF8FAFC) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TxIdRow extends StatelessWidget {
  final bool isAr;
  final String id;
  final VoidCallback onCopy;

  const _TxIdRow({
    required this.isAr,
    required this.id,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'رقم المرجع' : 'Reference Number',
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 7),
        GestureDetector(
          onTap: onCopy,
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.22),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    id,
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PerforationDivider extends StatelessWidget {
  const _PerforationDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius:
                  BorderRadius.horizontal(right: Radius.circular(10)),
            ),
          ),
          Expanded(
            child: CustomPaint(painter: _DashPainter()),
          ),
          Container(
            width: 10,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius:
                  BorderRadius.horizontal(left: Radius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashW = 5.0;
    const gap = 4.0;
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + dashW).clamp(0, size.width), y),
        paint,
      );
      x += dashW + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _CircleNavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleNavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.16),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
