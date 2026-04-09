import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/international_transfer_models.dart';
import '../../data/services/international_transfer_service.dart';

class P2PHistoryPage extends StatefulWidget {
  const P2PHistoryPage({super.key});

  @override
  State<P2PHistoryPage> createState() => _P2PHistoryPageState();
}

class _P2PHistoryPageState extends State<P2PHistoryPage> {
  bool _loading = true;
  List<IntlOrder> _orders = const [];

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';
  String _t(String en, String ar) => _isAr ? ar : en;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final orders = await InternationalTransferService.getOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t(
            'Could not load transfer history.',
            'تعذر تحميل سجل التحويلات.',
          )),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Status helpers ────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return const Color(0xFF1E8758);
      case 'UNDER_REVIEW':
        return const Color(0xFFC48723);
      case 'PENDING':
        return AppColors.primary;
      case 'REJECTED':
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return _t('Completed', 'مكتمل');
      case 'UNDER_REVIEW':
        return _t('Under Review', 'قيد المراجعة');
      case 'PENDING':
        return _t('Pending', 'معلق');
      case 'REJECTED':
        return _t('Rejected', 'مرفوض');
      case 'CANCELLED':
        return _t('Cancelled', 'ملغى');
      default:
        return status;
    }
  }

  // ── Details sheet ─────────────────────────────────────────────────────────

  void _showDetails(IntlOrder order) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _OrderDetailsSheet(
        order: order,
        isAr: _isAr,
        statusLabel: _statusLabel(order.status),
        statusColor: _statusColor(order.status),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            _isAr
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _t('Transfer History', 'سجل التحويلات'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadOrders,
              child: _orders.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: _orders.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) => _OrderCard(
                        order: _orders[i],
                        isAr: _isAr,
                        statusLabel: _statusLabel(_orders[i].status),
                        statusColor: _statusColor(_orders[i].status),
                        onTap: () => _showDetails(_orders[i]),
                      ),
                    ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_horiz_rounded,
              size: 56, color: AppColors.textHint),
          const SizedBox(height: 14),
          Text(
            _t('No transfers yet', 'لا توجد تحويلات بعد'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Order card ────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final IntlOrder order;
  final bool isAr;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.isAr,
    required this.statusLabel,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7E9EF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.currency_exchange_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: isAr
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderReference,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    order.exchangeName ?? order.exchangeCode ?? '-',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  if (order.createdAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      order.createdAt!,
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${order.sendAmount.toStringAsFixed(2)} ${order.sendCurrencyCode}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Details sheet ─────────────────────────────────────────────────────────────

class _OrderDetailsSheet extends StatelessWidget {
  final IntlOrder order;
  final bool isAr;
  final String statusLabel;
  final Color statusColor;

  const _OrderDetailsSheet({
    required this.order,
    required this.isAr,
    required this.statusLabel,
    required this.statusColor,
  });

  String _t(String en, String ar) => isAr ? ar : en;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD0D5DD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                textDirection:
                    isAr ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  Text(
                    _t('Order Details', 'تفاصيل الطلب'),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  _sheetSection(_t('Transfer', 'التحويل'), [
                    (_t('Reference', 'المرجع'), order.orderReference),
                    (
                      _t('You Sent', 'أرسلت'),
                      '${order.sendAmount.toStringAsFixed(2)} ${order.sendCurrencyCode}'
                    ),
                    (
                      _t('Receiver Got', 'استلم'),
                      '${order.receiveAmount.toStringAsFixed(2)} ${order.receiveCurrencyCode}'
                    ),
                    (
                      _t('Rate', 'السعر'),
                      '1 ${order.sendCurrencyCode} = ${order.appliedRate.toStringAsFixed(2)} ${order.receiveCurrencyCode}'
                    ),
                  ]),
                  const SizedBox(height: 14),
                  _sheetSection(_t('Exchange', 'الصرافة'), [
                    if (order.exchangeName != null)
                      (_t('Exchange', 'الصرافة'), order.exchangeName!),
                    if (order.providerName != null)
                      (_t('Provider', 'المزود'), order.providerName!),
                    if (order.providerReference != null)
                      (
                        _t('Reference No.', 'رقم المرجع'),
                        order.providerReference!
                      ),
                  ]),
                  const SizedBox(height: 14),
                  _sheetSection(_t('Parties', 'الأطراف'), [
                    if (order.senderName != null)
                      (_t('Sender', 'المرسل'), order.senderName!),
                    if (order.receiverName != null)
                      (_t('Receiver', 'المستلم'), order.receiverName!),
                    if (order.destinationAccountNumber != null)
                      (
                        _t('Account', 'الحساب'),
                        order.destinationAccountNumber!
                      ),
                    if (order.destinationAccountHolder != null)
                      (
                        _t('Holder', 'صاحب الحساب'),
                        order.destinationAccountHolder!
                      ),
                    if (order.receiveMethodCode != null)
                      (
                        _t('Method', 'الطريقة'),
                        order.receiveMethodCode!
                      ),
                  ]),
                  if (order.createdAt != null) ...[
                    const SizedBox(height: 14),
                    _sheetSection(_t('Date', 'التاريخ'), [
                      (_t('Created', 'تاريخ الإنشاء'), order.createdAt!),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetSection(String title, List<(String, String)> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Column(
            children: rows.asMap().entries.map((entry) {
              final isLast = entry.key == rows.length - 1;
              final row = entry.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    child: Row(
                      textDirection: isAr
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          row.$1,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            row.$2,
                            textAlign: isAr
                                ? TextAlign.left
                                : TextAlign.right,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Color(0xFFE7E9EF),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
