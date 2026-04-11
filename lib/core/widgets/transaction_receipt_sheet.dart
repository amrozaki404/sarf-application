import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/receipt_models.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

class TransactionReceiptSheet extends StatelessWidget {
  final TransactionReceipt receipt;

  const TransactionReceiptSheet({
    super.key,
    required this.receipt,
  });

  bool get _isCredit => receipt.isCredit == true;

  Color _statusColor(String? status) {
    switch ((status ?? '').trim().toUpperCase()) {
      case 'SUCCESS':
      case 'COMPLETED':
      case 'APPROVED':
        return AppColors.success;
      case 'PENDING':
      case 'UNDER_REVIEW':
      case 'PROCESSING':
        return const Color(0xFFC48723);
      case 'FAILED':
      case 'REJECTED':
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final statusColor = _statusColor(receipt.transactionStatus);
    final amountText = receipt.amountWithCurrency;
    final amountColor = _isCredit ? AppColors.success : AppColors.textPrimary;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          MediaQuery.of(context).padding.bottom + 18,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? 'الإيصال' : 'Receipt',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if ((receipt.tranDescription ?? '').isNotEmpty)
                          Text(
                            receipt.tranDescription!,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
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
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        receipt.transactionStatus!,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                ],
              ),
              if (amountText.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  amountText,
                  style: GoogleFonts.cairo(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: amountColor,
                    height: 1,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.55,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _ReceiptCard(
                        children: [
                          _ReceiptRow(
                            label: isAr ? 'نوع العملية' : 'Type',
                            value: receipt.tranType,
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
                          _ReceiptRow(
                            label: isAr ? 'رقم العملية' : 'Transaction ID',
                            value: receipt.transactionId,
                            emphasize: true,
                          ),
                        ],
                      ),
                      if (receipt.transactionFields.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _ReceiptCard(
                          title: isAr ? 'التفاصيل' : 'Details',
                          children: receipt.transactionFields
                              .map(
                                (field) => _ReceiptRow(
                                  label: field.label,
                                  value: field.value,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: isAr ? 'تم' : 'Done',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _ReceiptCard({
    this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final visibleChildren = children.where((child) => child is! SizedBox).toList();
    if (visibleChildren.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadii.xl,
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          ...visibleChildren,
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool emphasize;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
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
                fontSize: 12,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
