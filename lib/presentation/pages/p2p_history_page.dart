import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/auth_models.dart';
import '../../data/models/p2p_models.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/p2p_service.dart';
import 'notifications_page.dart';

class P2PHistoryPage extends StatefulWidget {
  final List<P2POrder>? orders;

  const P2PHistoryPage({super.key, this.orders});

  @override
  State<P2PHistoryPage> createState() => _P2PHistoryPageState();
}

class _P2PHistoryPageState extends State<P2PHistoryPage> {
  static const Color _surfaceBorder = Color(0xFFE7E9EF);

  bool _loading = false;
  List<P2POrder> _orders = const [];
  AuthData? _user;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  String _t(String en, String ar) => _isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _orders = List<P2POrder>.from(widget.orders ?? const <P2POrder>[]);
    _loadUser();
    if (widget.orders == null) {
      _loadOrders();
    }
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (!mounted) return;
    setState(() => _user = user);
  }

  Future<void> _refresh() async {
    await Future.wait([
      _loadOrders(),
      _loadUser(),
    ]);
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final orders = await P2PService.getOrders();
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
          content: Text(
            _t(
              'Transaction history could not be loaded.',
              'تعذر تحميل سجل المعاملات.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return const Color(0xFF1E8758);
      case 'UNDER_REVIEW':
        return const Color(0xFFC48723);
      default:
        return AppColors.exchangeDark;
    }
  }

  Color _statusBackground(String status) {
    return _statusColor(status).withOpacity(0.12);
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'COMPLETED':
        return _t('Completed', 'مكتمل');
      case 'UNDER_REVIEW':
        return _t('Under review', 'قيد المراجعة');
      default:
        return status;
    }
  }

  List<P2POrderAttachment> _attachmentsFor(P2POrder order) {
    try {
      final attachments = order.attachments;
      if (attachments.isNotEmpty) {
        return attachments;
      }
    } catch (_) {
      // Hot reload can leave older mock objects in memory without new fields.
    }
    if (order.customerReceiptName.trim().isEmpty) {
      return const [];
    }
    return [
      P2POrderAttachment(
        label: _t('Receipt', 'الإيصال'),
        name: order.customerReceiptName,
      ),
    ];
  }

  Future<void> _showDetails(P2POrder order) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _TransactionDetailsSheet(
          order: order,
          attachments: _attachmentsFor(order),
          isArabic: _isArabic,
          statusLabel: _statusLabel(order.status),
          statusColor: _statusColor(order.status),
          statusBackground: _statusBackground(order.status),
          onPreviewAttachment: (attachment) => _showAttachmentPreview(
            attachment: attachment,
          ),
        );
      },
    );
  }

  Future<void> _showAttachmentPreview({
    required P2POrderAttachment attachment,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _TransactionImagePreviewSheet(
          title: attachment.label,
          subtitle: attachment.name,
          previewSource: attachment.previewSource,
          isArabic: _isArabic,
        );
      },
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }

  String _formatCreatedAt(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value.replaceFirst('T', ' ');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(parsed.year, parsed.month, parsed.day);
    final difference = today.difference(date).inDays;

    final hour24 = parsed.hour;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final hour12 = ((hour24 + 11) % 12) + 1;
    final period = _isArabic
        ? (hour24 >= 12 ? 'م' : 'ص')
        : (hour24 >= 12 ? 'PM' : 'AM');
    final time = '$hour12:$minute $period';

    if (difference == 0) {
      return _t('Today, $time', 'اليوم، $time');
    }
    if (difference == 1) {
      return _t('Yesterday, $time', 'أمس، $time');
    }
    return value.replaceFirst('T', ' ');
  }

  String _routeTitle(P2POrder order) {
    if (order.routeTitle.trim().isNotEmpty) {
      return order.routeTitle;
    }
    if (order.sourceName != null &&
        order.sourceName!.trim().isNotEmpty &&
        order.destinationName != null &&
        order.destinationName!.trim().isNotEmpty) {
      return '${order.sourceName} → ${order.destinationName}';
    }
    return order.serviceTitle;
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _user?.firstName.trim();
    final displayName = (firstName == null || firstName.isEmpty)
        ? _t('Guest', 'المستخدم')
        : firstName;
    final avatarText = displayName[0].toUpperCase();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            children: [
              _buildTopBar(avatarText),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_orders.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE7E9EF)),
                  ),
                  child: Text(
                    _t(
                      'No transaction history found.',
                      'لا يوجد سجل معاملات.',
                    ),
                    textAlign: _isArabic ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                ..._orders.asMap().entries.map((entry) {
                  final order = entry.value;

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: entry.key == _orders.length - 1 ? 0 : 12,
                    ),
                    child: _TransactionHistoryCard(
                      isArabic: _isArabic,
                      logoUrl: order.destinationLogoUrl ?? order.sourceLogoUrl,
                      title: _routeTitle(order),
                      timeLabel: _formatCreatedAt(order.createdAt),
                      amountLabel:
                          '${P2PService.fmtAmount(order.receiveAmount)} ${order.receiveCurrency}',
                      statusLabel: _statusLabel(order.status),
                      statusColor: _statusColor(order.status),
                      statusBackground: _statusBackground(order.status),
                      onTap: () => _showDetails(order),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(String avatarText) {
    final canPop = Navigator.of(context).canPop();
    final leadingIcon = canPop
        ? (_isArabic
              ? Icons.arrow_forward_ios_rounded
              : Icons.arrow_back_ios_new_rounded)
        : Icons.notifications_none_rounded;

    return SizedBox(
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _TopCircleButton(
              icon: leadingIcon,
              onTap: canPop ? () => Navigator.of(context).pop() : _openNotifications,
              foreground: const Color(0xFF6E7688),
              background: Colors.white,
              borderColor: _surfaceBorder,
            ),
          ),
          const Center(child: _BrandMark()),
          Align(
            alignment: Alignment.centerRight,
            child: _TopCircleButton(
              label: avatarText,
              foreground: Colors.white,
              background: const Color(0xFF0C2C5E),
              borderColor: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageTitle() {
    return Column(
      crossAxisAlignment:
          _isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          _t('Transaction history', 'سجل المعاملات'),
          textAlign: _isArabic ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            color: Color(0xFF101828),
            fontSize: 27,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _t(
            'Tap any transaction to view full details.',
            'اضغط على أي معاملة لعرض التفاصيل الكاملة.',
          ),
          textAlign: _isArabic ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _TransactionHistoryCard extends StatelessWidget {
  final bool isArabic;
  final String? logoUrl;
  final String title;
  final String timeLabel;
  final String amountLabel;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackground;
  final VoidCallback onTap;

  const _TransactionHistoryCard({
    required this.isArabic,
    required this.logoUrl,
    required this.title,
    required this.timeLabel,
    required this.amountLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE4E7EC)),
          ),
          child: Row(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    _HistoryTileLogo(logoUrl: logoUrl),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: isArabic
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign:
                                isArabic ? TextAlign.right : TextAlign.left,
                            style: const TextStyle(
                              color: Color(0xFF101828),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            timeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign:
                                isArabic ? TextAlign.right : TextAlign.left,
                            style: const TextStyle(
                              color: Color(0xFF667085),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 108),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          amountLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            color: Color(0xFF101828),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _StatusChip(
                          label: statusLabel,
                          color: statusColor,
                          backgroundColor: statusBackground,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTileLogo extends StatelessWidget {
  final String? logoUrl;

  const _HistoryTileLogo({
    required this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      'assets/images/app_icon.png',
      width: 34,
      height: 34,
      fit: BoxFit.cover,
    );

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      alignment: Alignment.center,
      child: ClipOval(
        child: logoUrl == null || logoUrl!.trim().isEmpty
            ? fallback
            : Image.network(
                logoUrl!,
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) {
                    return child;
                  }
                  return fallback;
                },
              ),
      ),
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final Color foreground;
  final Color background;
  final Color borderColor;
  final VoidCallback? onTap;

  const _TopCircleButton({
    this.icon,
    this.label,
    required this.foreground,
    required this.background,
    required this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor),
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, color: foreground, size: 22)
          : Text(
              label ?? '',
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
    );

    if (onTap == null) {
      return child;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: child,
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/app_icon.png',
          width: 36,
          height: 36,
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'صرف' : 'Sarf',
              style: const TextStyle(
                color: Color(0xFF101828),
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Exchange',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TransactionDetailsSheet extends StatelessWidget {
  final P2POrder order;
  final List<P2POrderAttachment> attachments;
  final bool isArabic;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackground;
  final ValueChanged<P2POrderAttachment> onPreviewAttachment;

  const _TransactionDetailsSheet({
    required this.order,
    required this.attachments,
    required this.isArabic,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackground,
    required this.onPreviewAttachment,
  });

  String _t(String en, String ar) => isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FBFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4DEE2),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _t('Transaction details', 'تفاصيل المعاملة'),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order.orderReference,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _StatusChip(
                          label: statusLabel,
                          color: statusColor,
                          backgroundColor: statusBackground,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppGradients.exchangeHeader,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _RouteLogos(
                                sourceName: order.sourceName,
                                sourceLogoUrl: order.sourceLogoUrl,
                                destinationName: order.destinationName,
                                destinationLogoUrl: order.destinationLogoUrl,
                                dark: true,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  order.sourceName != null &&
                                          order.destinationName != null
                                      ? '${order.sourceName}  ${isArabic ? '<' : '>'}  ${order.destinationName}'
                                      : order.routeTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _SheetAmount(
                                  label: _t('Transfer amount', 'مبلغ التحويل'),
                                  value:
                                      '${P2PService.fmtAmount(order.sendAmount)} ${order.sendCurrency}',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _SheetAmount(
                                  label: _t('Received amount', 'المبلغ المستلم'),
                                  value:
                                      '${P2PService.fmtAmount(order.receiveAmount)} ${order.receiveCurrency}',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DetailSection(
                      title: _t('Summary', 'الملخص'),
                      child: Column(
                        children: [
                          _DetailRow(
                            label: _t('Created at', 'تاريخ الإنشاء'),
                            value: order.createdAt,
                          ),
                          _DetailRow(
                            label: _t('Exchange rate', 'سعر التحويل'),
                            value:
                                '1 ${order.sendCurrency} = ${P2PService.fmtAmount(order.rate)} ${order.receiveCurrency}',
                          ),
                          _DetailRow(
                            label: _t('Fee', 'الرسوم'),
                            value:
                                '${P2PService.fmtAmount(order.feeAmount)} ${order.feeCurrency}',
                          ),
                          _DetailRow(
                            label: _t('Handled by', 'تم التنفيذ عبر'),
                            value: order.merchantName,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DetailSection(
                      title: _t('Execution details', 'تفاصيل التنفيذ'),
                      child: Column(
                        children: [
                          _DetailRow(
                            label: _t('Route', 'المسار'),
                            value: order.routeTitle,
                          ),
                          _DetailRow(
                            label: _t('Payment', 'الدفع'),
                            value: order.paymentSummary,
                          ),
                          _DetailRow(
                            label: _t('Destination', 'وجهة الاستلام'),
                            value: order.destinationSummary,
                          ),
                        ],
                      ),
                    ),
                    if (attachments.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _DetailSection(
                        title: _t('Attachments', 'المرفقات'),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: attachments
                              .map(
                                (attachment) => _AttachmentPreviewCard(
                                  attachment: attachment,
                                  onTap: attachment.previewSource == null ||
                                          attachment.previewSource!.isEmpty
                                      ? null
                                      : () => onPreviewAttachment(attachment),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionImagePreviewSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? previewSource;
  final bool isArabic;

  const _TransactionImagePreviewSheet({
    required this.title,
    required this.subtitle,
    required this.previewSource,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.86,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FBFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4DEE2),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                child: Row(
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE2EAEE)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: previewSource == null || previewSource!.isEmpty
                          ? const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.textSecondary,
                                size: 36,
                              ),
                            )
                          : InteractiveViewer(
                              minScale: 1,
                              maxScale: 4,
                              child: _PreviewImage(
                                source: previewSource!,
                                fit: BoxFit.contain,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteLogos extends StatelessWidget {
  final String? sourceName;
  final String? sourceLogoUrl;
  final String? destinationName;
  final String? destinationLogoUrl;
  final bool dark;

  const _RouteLogos({
    required this.sourceName,
    required this.sourceLogoUrl,
    required this.destinationName,
    required this.destinationLogoUrl,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final arrowColor = dark ? Colors.white70 : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _EntityLogo(
          label: sourceName,
          logoUrl: sourceLogoUrl,
          dark: dark,
        ),
        Container(
          width: 26,
          alignment: Alignment.center,
          child: Icon(
            Icons.east_rounded,
            size: 18,
            color: arrowColor,
          ),
        ),
        _EntityLogo(
          label: destinationName,
          logoUrl: destinationLogoUrl,
          dark: dark,
        ),
      ],
    );
  }
}

class _EntityLogo extends StatelessWidget {
  final String? label;
  final String? logoUrl;
  final bool dark;

  const _EntityLogo({
    required this.label,
    required this.logoUrl,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Padding(
      padding: const EdgeInsets.all(6),
      child: Image.asset(
        'assets/images/app_icon.png',
        fit: BoxFit.contain,
      ),
    );

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: dark ? Colors.white.withOpacity(0.12) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              dark ? Colors.white.withOpacity(0.18) : const Color(0xFFD7E2E6),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl == null || logoUrl!.trim().isEmpty
          ? fallback
          : Image.network(
              logoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
              loadingBuilder: (context, child, progress) {
                if (progress == null) {
                  return child;
                }
                return fallback;
              },
            ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color backgroundColor;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _AmountTile extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _AmountTile({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: highlight ? AppColors.exchangeDark : AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetAmount extends StatelessWidget {
  final String label;
  final String value;

  const _SheetAmount({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2EAEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentThumb extends StatelessWidget {
  final P2POrderAttachment attachment;
  final VoidCallback onTap;

  const _AttachmentThumb({
    required this.attachment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD7E2E6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: attachment.previewSource == null || attachment.previewSource!.isEmpty
            ? Container(
                color: AppColors.inputFill,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.description_outlined,
                  color: AppColors.textSecondary,
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  _PreviewImage(
                    source: attachment.previewSource!,
                    fit: BoxFit.cover,
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.zoom_in_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _AttachmentPreviewCard extends StatelessWidget {
  final P2POrderAttachment attachment;
  final VoidCallback? onTap;

  const _AttachmentPreviewCard({
    required this.attachment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 138,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 108,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: attachment.previewSource == null ||
                      attachment.previewSource!.isEmpty
                  ? const Center(
                      child: Icon(
                        Icons.description_outlined,
                        color: AppColors.textSecondary,
                        size: 28,
                      ),
                    )
                  : _PreviewImage(
                      source: attachment.previewSource!,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 10),
            Text(
              attachment.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              attachment.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  final String source;
  final BoxFit fit;

  const _PreviewImage({
    required this.source,
    this.fit = BoxFit.cover,
  });

  bool get _isNetworkSource {
    return source.startsWith('http://') || source.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    if (_isNetworkSource) {
      return Image.network(
        source,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _ImageFallback();
        },
      );
    }

    final file = File(source);
    if (!file.existsSync()) {
      return _ImageFallback();
    }

    return Image.file(
      file,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return _ImageFallback();
      },
    );
  }
}

class _ImageFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.inputFill,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.textSecondary,
        size: 28,
      ),
    );
  }
}
