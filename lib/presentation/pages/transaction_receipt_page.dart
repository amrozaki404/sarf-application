import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/receipt_models.dart';

class TransactionReceiptPage extends StatefulWidget {
  final TransactionReceipt receipt;

  const TransactionReceiptPage({
    super.key,
    required this.receipt,
  });

  @override
  State<TransactionReceiptPage> createState() => _TransactionReceiptPageState();
}

class _TransactionReceiptPageState extends State<TransactionReceiptPage>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _iconScale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _iconScale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  IconData _statusIcon(String? status) {
    switch ((status ?? '').trim().toUpperCase()) {
      case 'SUCCESS':
      case 'COMPLETED':
      case 'APPROVED':
        return Icons.check_circle_rounded;
      case 'PENDING':
      case 'UNDER_REVIEW':
      case 'PROCESSING':
        return Icons.schedule_rounded;
      case 'FAILED':
      case 'REJECTED':
      case 'CANCELLED':
        return Icons.cancel_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
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
        backgroundColor: AppColors.success,
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
    final icon = _statusIcon(receipt.transactionStatus);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Brand-color hero background
            Container(
              height: MediaQuery.of(context).size.height * 0.38,
              decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            ),
            SafeArea(
              child: Column(
                children: [
                  // ── Nav row ────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                  // ── Hero icon + status ─────────────────────────────────
                  const SizedBox(height: 24),
                  ScaleTransition(
                    scale: _iconScale,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.32),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 46),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeTransition(
                    opacity: _fade,
                    child: Column(
                      children: [
                        if ((receipt.transactionStatus ?? '').isNotEmpty)
                          _StatusPill(label: receipt.transactionStatus!),
                        if ((receipt.tranDescription ?? '').isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              receipt.tranDescription!,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.78),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // ── Overlapping content area ───────────────────────────
                  Expanded(
                    child: FadeTransition(
                      opacity: _fade,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SingleChildScrollView(
                          padding:
                              const EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Column(
                            children: [
                              _buildMainCard(isAr, receipt),
                              if (receipt.transactionFields.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _buildDetailsCard(isAr, receipt),
                              ],
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ── Done button ────────────────────────────────────────
                  Container(
                    color: AppColors.background,
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

  Widget _buildMainCard(bool isAr, TransactionReceipt receipt) {
    return _ReceiptCard(
      children: [
        _ReceiptRow(
          label: isAr ? 'نوع العملية' : 'Type',
          value: receipt.tranType,
        ),
        _ReceiptRow(
          label: isAr ? 'المبلغ' : 'Amount',
          value: receipt.amountWithCurrency.isNotEmpty
              ? receipt.amountWithCurrency
              : null,
        ),
        _ReceiptRow(
          label: isAr ? 'التاريخ' : 'Date',
          value: receipt.tranDate,
        ),
        _ReceiptRow(
          label: isAr ? 'الوقت' : 'Time',
          value: receipt.tranTime,
        ),
        _ReceiptRow(
          label: isAr ? 'الرسوم' : 'Fee',
          value: receipt.feeAmount,
        ),
        _ReceiptRow(
          label: isAr ? 'المستفيد' : 'Beneficiary',
          value: receipt.beneficiaryName,
        ),
        _ReceiptRow(
          label: isAr ? 'القيمة' : 'Beneficiary value',
          value: receipt.beneficiaryValue,
        ),
        if ((receipt.transactionId ?? '').isNotEmpty)
          _ReceiptRowWithCopy(
            label: isAr ? 'رقم العملية' : 'Transaction ID',
            value: receipt.transactionId!,
            onCopy: _copyId,
          ),
      ],
    );
  }

  Widget _buildDetailsCard(bool isAr, TransactionReceipt receipt) {
    return _ReceiptCard(
      title: isAr ? 'تفاصيل إضافية' : 'Details',
      children: receipt.transactionFields
          .map((f) => _ReceiptRow(label: f.label, value: f.value))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────

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
            color: Colors.white.withOpacity(0.14),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.28)),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  const _ReceiptCard({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final visible = children.whereType<Widget>().toList();
    if (visible.isEmpty) return const SizedBox.shrink();

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
          if (title != null) ...[
            Text(
              title!,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(color: AppColors.borderSoft, height: 1),
            const SizedBox(height: 10),
          ],
          ...visible,
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String? value;
  const _ReceiptRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
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

class _ReceiptRowWithCopy extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;
  const _ReceiptRowWithCopy({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppColors.borderSoft, height: 1),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onCopy,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: AppRadii.md,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.25),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: GoogleFonts.robotoMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
