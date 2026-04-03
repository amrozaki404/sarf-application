import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/marketplace_models.dart';
import '../../data/services/marketplace_service.dart';

String _mt(bool isArabic, String en, String ar) => isArabic ? ar : en;

String _formatAmount(double value, {int decimals = 2}) {
  final fixed = value.toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final whole = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '$whole.${parts.last}';
}

String _formatDateTime(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.day} ${months[value.month - 1]}, $hour:$minute';
}

String _statusLabel(String status, bool isArabic) {
  switch (status) {
    case 'UNDER_REVIEW':
      return _mt(isArabic, 'Under review', 'قيد المراجعة');
    case 'READY_FOR_PAYOUT':
      return _mt(isArabic, 'Ready for payout', 'جاهز للصرف');
    case 'COMPLETED':
      return _mt(isArabic, 'Completed', 'مكتمل');
    case 'LOCKED':
      return _mt(isArabic, 'Locked', 'موقوف');
    case 'OPEN':
      return _mt(isArabic, 'Open case', 'بلاغ مفتوح');
    case 'RECEIPT_VERIFIED':
      return _mt(isArabic, 'Receipt verified', 'تم التحقق من الإيصال');
    case 'MORE_INFO_REQUIRED':
      return _mt(isArabic, 'More info required', 'مطلوب معلومات إضافية');
    default:
      return status;
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'UNDER_REVIEW':
      return const Color(0xFFB26A00);
    case 'READY_FOR_PAYOUT':
      return const Color(0xFF155EEF);
    case 'COMPLETED':
    case 'RECEIPT_VERIFIED':
      return AppColors.success;
    case 'LOCKED':
    case 'OPEN':
    case 'MORE_INFO_REQUIRED':
      return AppColors.error;
    default:
      return AppColors.textSecondary;
  }
}

Color _statusBackground(String status) {
  switch (status) {
    case 'UNDER_REVIEW':
      return const Color(0xFFFFF4DE);
    case 'READY_FOR_PAYOUT':
      return const Color(0xFFE9F1FF);
    case 'COMPLETED':
    case 'RECEIPT_VERIFIED':
      return const Color(0xFFE7F9F1);
    case 'LOCKED':
    case 'OPEN':
    case 'MORE_INFO_REQUIRED':
      return const Color(0xFFFFE9E9);
    default:
      return const Color(0xFFF1F5F7);
  }
}

String _deadlineText(DateTime deadline, bool isArabic) {
  final diff = deadline.difference(DateTime.now());
  if (diff.isNegative) {
    final overdue = diff.abs().inMinutes;
    return _mt(
      isArabic,
      'Over SLA by ${overdue}m',
      'تجاوز المهلة بـ ${overdue} دقيقة',
    );
  }
  if (diff.inMinutes < 60) {
    return _mt(
      isArabic,
      '${diff.inMinutes}m left',
      'متبقي ${diff.inMinutes} دقيقة',
    );
  }
  final hours = diff.inHours;
  return _mt(isArabic, '${hours}h left', 'متبقي $hours ساعة');
}

bool _canRaiseDispute(String status) {
  return status == 'READY_FOR_PAYOUT' || status == 'COMPLETED';
}

class _TimelineStepData {
  final String title;
  final String subtitle;
  final bool done;
  final bool active;
  final bool blocked;

  const _TimelineStepData({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.active,
    this.blocked = false,
  });
}

List<_TimelineStepData> _timelineForOrder(
  MarketplaceOrder order,
  bool isArabic,
) {
  final underReviewDone = order.status != 'UNDER_REVIEW';
  final payoutDone = order.status == 'COMPLETED' || order.status == 'LOCKED';
  final completeDone = order.status == 'COMPLETED';

  return [
    _TimelineStepData(
      title: _mt(isArabic, 'Order submitted', 'تم إرسال الطلب'),
      subtitle: _formatDateTime(order.createdAt),
      done: true,
      active: false,
    ),
    _TimelineStepData(
      title: _mt(isArabic, 'Merchant review', 'مراجعة التاجر'),
      subtitle: _mt(
        isArabic,
        'KYC and transfer proof are being checked.',
        'يتم التحقق من الهوية وإثبات التحويل.',
      ),
      done: underReviewDone,
      active: order.status == 'UNDER_REVIEW',
    ),
    _TimelineStepData(
      title: _mt(isArabic, 'External payout', 'الصرف الخارجي'),
      subtitle: _mt(
        isArabic,
        'Merchant pays the recipient and uploads payout proof.',
        'يقوم التاجر بالصرف ويرفع إثبات الدفع.',
      ),
      done: payoutDone,
      active: order.status == 'READY_FOR_PAYOUT',
      blocked: order.status == 'LOCKED',
    ),
    _TimelineStepData(
      title: order.status == 'LOCKED'
          ? _mt(isArabic, 'Locked for dispute', 'تم إيقاف العملية')
          : _mt(isArabic, 'Completed', 'مكتمل'),
      subtitle: order.status == 'LOCKED'
          ? _mt(
              isArabic,
              'Admin review is required before release.',
              'المعاملة تحتاج مراجعة إدارية قبل الإفراج.',
            )
          : _mt(
              isArabic,
              'Customer confirmed or payout proof was uploaded.',
              'تم تأكيد العميل أو رفع إثبات الصرف.',
            ),
      done: completeDone || order.status == 'LOCKED',
      active: order.status == 'COMPLETED' || order.status == 'LOCKED',
      blocked: order.status == 'LOCKED',
    ),
  ];
}

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  bool _loading = true;
  int _workspaceIndex = 0;
  String? _selectedPairId;
  String? _selectedMerchantId;
  List<ExchangePairOption> _pairs = [];
  List<ExchangeHouse> _merchants = [];
  List<MarketplaceOrder> _orders = [];
  List<MarketplaceDisputeCase> _cases = [];
  MarketplaceOverview? _overview;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  String _t(String en, String ar) => _mt(_isArabic, en, ar);

  ExchangePairOption? get _selectedPair {
    if (_selectedPairId == null) return null;
    try {
      return _pairs.firstWhere((pair) => pair.id == _selectedPairId);
    } catch (_) {
      return null;
    }
  }

  ExchangeHouse? get _selectedMerchant {
    if (_selectedMerchantId == null) return null;
    try {
      return _merchants.firstWhere((merchant) => merchant.id == _selectedMerchantId);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pairs = await MarketplaceService.getPairs();
    final merchants = await MarketplaceService.getExchangeHouses();
    final orders = await MarketplaceService.getOrders();
    final cases = await MarketplaceService.getDisputeCases();
    final overview = await MarketplaceService.getOverview();

    final nextPairId = pairs.any((pair) => pair.id == _selectedPairId)
        ? _selectedPairId
        : (pairs.isEmpty ? null : pairs.first.id);
    final nextMerchantId = merchants.any(
      (merchant) => merchant.id == _selectedMerchantId,
    )
        ? _selectedMerchantId
        : (merchants.isEmpty ? null : merchants.first.id);

    if (!mounted) return;
    setState(() {
      _pairs = pairs;
      _merchants = merchants;
      _orders = orders;
      _cases = cases;
      _overview = overview;
      _selectedPairId = nextPairId;
      _selectedMerchantId = nextMerchantId;
      _loading = false;
    });
  }

  List<ExchangeHouse> _customerMerchants() {
    final pair = _selectedPair;
    if (pair == null) return [];
    final items = _merchants.where((merchant) => merchant.supportsPair(pair.id)).toList();
    items.sort((a, b) => b.offerFor(pair.id).rate.compareTo(a.offerFor(pair.id).rate));
    return items;
  }

  List<MarketplaceOrder> _merchantOrders(String merchantId) {
    final items = _orders.where((order) => order.merchantId == merchantId).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> _openMerchantProfile(ExchangeHouse merchant) async {
    final pair = _selectedPair;
    if (pair == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _MerchantProfilePage(
          merchant: merchant,
          pair: pair,
          isArabic: _isArabic,
        ),
      ),
    );
    await _load();
  }

  Future<void> _openOrderTracking(MarketplaceOrder order) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CustomerOrderTrackingPage(
          orderId: order.id,
          isArabic: _isArabic,
        ),
      ),
    );
    await _load();
  }

  Future<void> _openMerchantOrder(MarketplaceOrder order) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _MerchantExecutionPage(
          orderId: order.id,
          isArabic: _isArabic,
        ),
      ),
    );
    await _load();
  }

  Future<void> _openAdminCase(MarketplaceDisputeCase item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AdminDisputePage(
          disputeCaseId: item.id,
          isArabic: _isArabic,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_t('Exchange Marketplace', 'سوق دور الصرافة')),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.exchangeDark,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            _buildHero(),
            const SizedBox(height: 14),
            _WorkspaceToggle(
              activeIndex: _workspaceIndex,
              labels: [
                _t('Customer', 'العميل'),
                _t('Merchant', 'التاجر'),
                _t('Admin', 'الإدارة'),
              ],
              onChanged: (value) => setState(() => _workspaceIndex = value),
            ),
            const SizedBox(height: 14),
            if (_workspaceIndex == 0) _buildCustomerWorkspace(),
            if (_workspaceIndex == 1) _buildMerchantWorkspace(),
            if (_workspaceIndex == 2) _buildAdminWorkspace(),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.exchangeHeader,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.exchange,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _t(
                    'Verified exchange houses with escrow-style tracking',
                    'دور صرافة موثقة مع تتبع يشبه الضمان التشغيلي',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _t(
              'Sarf routes customer documents, merchant execution, payout receipts, and disputes without touching the actual settlement funds.',
              'يقوم صرف بربط مستندات العميل وتنفيذ التاجر وإيصالات الصرف وحالات النزاع دون التعامل المباشر مع أموال التسوية.',
            ),
            style: const TextStyle(
              color: Color(0xFFD4E3E8),
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerWorkspace() {
    final pair = _selectedPair;
    final merchants = _customerMerchants();
    final lastOrder = _orders.isEmpty ? null : _orders.first;
    double? bestRate;
    int? fastestEta;

    if (pair != null && merchants.isNotEmpty) {
      bestRate = merchants.first.offerFor(pair.id).rate;
      fastestEta = merchants
          .map((merchant) => merchant.avgCompletionMinutes)
          .reduce((a, b) => a < b ? a : b);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lastOrder != null) ...[
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _t('Latest order', 'آخر طلب'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    _StatusBadge(
                      label: _statusLabel(lastOrder.status, _isArabic),
                      color: _statusColor(lastOrder.status),
                      backgroundColor: _statusBackground(lastOrder.status),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${lastOrder.id}  •  ${lastOrder.merchantName}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatAmount(lastOrder.sendAmount)} ${lastOrder.sendCurrency}  →  ${_formatAmount(lastOrder.receiveAmount)} ${lastOrder.receiveCurrency}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                AppButton(
                  label: _t('Track order', 'تتبع الطلب'),
                  onPressed: () => _openOrderTracking(lastOrder),
                  height: 48,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _pairs.map((pairItem) {
              final selected = pairItem.id == _selectedPairId;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(pairItem.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedPairId = pairItem.id),
                  showCheckmark: false,
                  selectedColor: AppColors.exchangeDark,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(
                      color: selected ? AppColors.exchangeDark : AppColors.borderSoft,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (pair != null) ...[
          const SizedBox(height: 12),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pair.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricCard(
                      title: _t('Active desks', 'الدور النشطة'),
                      value: merchants.length.toString(),
                      icon: Icons.verified_user_outlined,
                    ),
                    _MetricCard(
                      title: _t('Best rate', 'أفضل سعر'),
                      value: bestRate == null
                          ? '--'
                          : '${_formatAmount(bestRate)} ${pair.receiveCurrency}',
                      icon: Icons.trending_up_rounded,
                    ),
                    _MetricCard(
                      title: _t('Fastest ETA', 'أسرع وقت'),
                      value: fastestEta == null
                          ? '--'
                          : _t('$fastestEta min', '$fastestEta دقيقة'),
                      icon: Icons.timer_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          _t('Available exchange houses', 'دور الصرافة المتاحة'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        if (merchants.isEmpty)
          _EmptyStateCard(
            title: _t('No active merchants for this pair', 'لا يوجد تجار نشطون لهذا المسار'),
            subtitle: _t(
              'Try another corridor or refresh the marketplace.',
              'جرّب مساراً آخر أو حدّث السوق.',
            ),
          )
        else
          ...merchants.map(
            (merchant) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MerchantMarketplaceCard(
                merchant: merchant,
                offer: merchant.offerFor(pair!.id),
                receiveCurrency: pair.receiveCurrency,
                onTap: () => _openMerchantProfile(merchant),
                isArabic: _isArabic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMerchantWorkspace() {
    final merchant = _selectedMerchant;
    if (merchant == null) {
      return _EmptyStateCard(
        title: _t('No merchant dashboard data', 'لا توجد بيانات لوحة التاجر'),
        subtitle: _t(
          'There are no active merchants configured right now.',
          'لا توجد دور صرافة نشطة حالياً.',
        ),
      );
    }

    final orders = _merchantOrders(merchant.id);
    final pending = orders.where((order) => order.status == 'UNDER_REVIEW').length;
    final payoutReady = orders.where((order) => order.status == 'READY_FOR_PAYOUT').length;
    final completed = orders.where((order) => order.status == 'COMPLETED').length;
    final atRisk = orders
        .where((order) => order.status != 'COMPLETED' && order.status != 'LOCKED')
        .where((order) => order.slaDeadline.difference(DateTime.now()).inMinutes <= 10)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _merchants.map((item) {
              final selected = item.id == _selectedMerchantId;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(item.name),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedMerchantId = item.id),
                  showCheckmark: false,
                  selectedColor: AppColors.exchangeDark,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(
                      color: selected ? AppColors.exchangeDark : AppColors.borderSoft,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          merchant.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${merchant.region}  •  ${merchant.supportWindow}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F1FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _t('SLA ${merchant.slaMinutes}m', 'المهلة ${merchant.slaMinutes}د'),
                      style: const TextStyle(
                        color: Color(0xFF155EEF),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetricCard(
                    title: _t('Under review', 'قيد المراجعة'),
                    value: pending.toString(),
                    icon: Icons.rule_folder_outlined,
                  ),
                  _MetricCard(
                    title: _t('Ready to pay', 'جاهز للصرف'),
                    value: payoutReady.toString(),
                    icon: Icons.payments_outlined,
                  ),
                  _MetricCard(
                    title: _t('Completed', 'مكتمل'),
                    value: completed.toString(),
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  _MetricCard(
                    title: _t('SLA risk', 'خطر المهلة'),
                    value: atRisk.toString(),
                    icon: Icons.priority_high_rounded,
                    accentColor: atRisk > 0 ? AppColors.error : null,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _t('Merchant queue', 'قائمة التاجر'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        if (orders.isEmpty)
          _EmptyStateCard(
            title: _t('No assigned marketplace orders', 'لا توجد طلبات مخصصة'),
            subtitle: _t(
              'New customer submissions will appear here after validation.',
              'ستظهر طلبات العملاء هنا بعد التحقق.',
            ),
          )
        else
          ...orders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MerchantQueueCard(
                order: order,
                isArabic: _isArabic,
                onTap: () => _openMerchantOrder(order),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAdminWorkspace() {
    final overview = _overview;
    final atRiskOrders = _orders
        .where((order) => order.status != 'COMPLETED' && order.status != 'LOCKED')
        .where((order) => order.slaDeadline.difference(DateTime.now()).inMinutes <= 10)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (overview != null)
          _SectionCard(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricCard(
                  title: _t('Active merchants', 'التجار النشطون'),
                  value: overview.activeMerchants.toString(),
                  icon: Icons.storefront_outlined,
                ),
                _MetricCard(
                  title: _t('Open disputes', 'النزاعات المفتوحة'),
                  value: overview.openDisputes.toString(),
                  icon: Icons.gpp_maybe_outlined,
                  accentColor: overview.openDisputes > 0 ? AppColors.error : null,
                ),
                _MetricCard(
                  title: _t('Locked orders', 'الطلبات الموقوفة'),
                  value: overview.lockedTransactions.toString(),
                  icon: Icons.lock_outline_rounded,
                ),
                _MetricCard(
                  title: _t('SLA breaches', 'تجاوزات المهلة'),
                  value: overview.slaBreaches.toString(),
                  icon: Icons.av_timer_rounded,
                  accentColor: overview.slaBreaches > 0 ? AppColors.error : null,
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        Text(
          _t('Dispute queue', 'قائمة النزاعات'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        if (_cases.isEmpty)
          _EmptyStateCard(
            title: _t('No disputes right now', 'لا توجد نزاعات حالياً'),
            subtitle: _t(
              'Locked orders and customer complaints will appear here.',
              'ستظهر الطلبات الموقوفة وشكاوى العملاء هنا.',
            ),
          )
        else
          ..._cases.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AdminCaseCard(
                item: item,
                isArabic: _isArabic,
                onTap: () => _openAdminCase(item),
              ),
            ),
          ),
        const SizedBox(height: 14),
        Text(
          _t('SLA watchlist', 'قائمة مراقبة المهلة'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        if (atRiskOrders.isEmpty)
          _EmptyStateCard(
            title: _t('No orders near SLA breach', 'لا توجد طلبات قريبة من تجاوز المهلة'),
            subtitle: _t(
              'Merchant queues are within the configured service window.',
              'قوائم التجار ضمن نافذة الخدمة المحددة.',
            ),
          )
        else
          ...atRiskOrders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _WatchlistCard(
                order: order,
                isArabic: _isArabic,
              ),
            ),
          ),
      ],
    );
  }
}

class _MerchantProfilePage extends StatelessWidget {
  final ExchangeHouse merchant;
  final ExchangePairOption pair;
  final bool isArabic;

  const _MerchantProfilePage({
    required this.merchant,
    required this.pair,
    required this.isArabic,
  });

  String _t(String en, String ar) => _mt(isArabic, en, ar);

  @override
  Widget build(BuildContext context) {
    final offer = merchant.offerFor(pair.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_t('Merchant profile', 'ملف التاجر')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppGradients.exchangeHeader,
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppShadows.exchange,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            merchant.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${merchant.region}  •  ${merchant.supportWindow}',
                            style: const TextStyle(
                              color: Color(0xFFD4E3E8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(
                      label: _t('Active', 'نشط'),
                      color: AppColors.success,
                      backgroundColor: Colors.white.withOpacity(0.12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${_formatAmount(offer.rate)} ${pair.receiveCurrency}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _t(
                    'Per 1 ${pair.sendCurrency} in the ${pair.label} corridor',
                    'لكل 1 ${pair.sendCurrency} في مسار ${pair.label}',
                  ),
                  style: const TextStyle(
                    color: Color(0xFFD4E3E8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricCard(
                  title: _t('Rating', 'التقييم'),
                  value: merchant.rating.toStringAsFixed(1),
                  icon: Icons.star_rounded,
                ),
                _MetricCard(
                  title: _t('Avg completion', 'متوسط الإنجاز'),
                  value: _t(
                    '${merchant.avgCompletionMinutes} min',
                    '${merchant.avgCompletionMinutes} دقيقة',
                  ),
                  icon: Icons.flash_on_outlined,
                ),
                _MetricCard(
                  title: _t('Completion', 'نسبة الإنجاز'),
                  value: '${merchant.completionRate.toStringAsFixed(1)}%',
                  icon: Icons.analytics_outlined,
                ),
                _MetricCard(
                  title: _t('Range', 'الحدود'),
                  value:
                      '${_formatAmount(offer.minAmount)} - ${_formatAmount(offer.maxAmount)} ${pair.sendCurrency}',
                  icon: Icons.swap_vert_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Payout channels', 'قنوات الصرف'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: merchant.payoutMethods
                      .map((method) => _TagChip(label: method))
                      .toList(),
                ),
                const SizedBox(height: 18),
                Text(
                  _t('Operational notes', 'ملاحظات تشغيلية'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  merchant.verificationNote,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: merchant.badges
                      .map((badge) => _TagChip(label: badge, tinted: true))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: _t('Start order with this merchant', 'ابدأ طلباً مع هذا التاجر'),
            onPressed: () async {
              final submitted = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => _CustomerOrderFormPage(
                    merchant: merchant,
                    pair: pair,
                    isArabic: isArabic,
                  ),
                ),
              );
              if (submitted == true && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _CustomerOrderFormPage extends StatefulWidget {
  final ExchangeHouse merchant;
  final ExchangePairOption pair;
  final bool isArabic;

  const _CustomerOrderFormPage({
    required this.merchant,
    required this.pair,
    required this.isArabic,
  });

  @override
  State<_CustomerOrderFormPage> createState() => _CustomerOrderFormPageState();
}

class _CustomerOrderFormPageState extends State<_CustomerOrderFormPage> {
  final _picker = ImagePicker();
  final _customerNameController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _payoutDestinationController = TextEditingController();
  final _transferReferenceController = TextEditingController();
  final _amountController = TextEditingController();

  File? _kycFile;
  File? _transferReceiptFile;
  String? _selectedPayoutMethod;
  bool _submitting = false;

  String _t(String en, String ar) => _mt(widget.isArabic, en, ar);

  ExchangeHouseOffer get _offer => widget.merchant.offerFor(widget.pair.id);

  @override
  void initState() {
    super.initState();
    _selectedPayoutMethod = widget.merchant.payoutMethods.first;
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _recipientNameController.dispose();
    _payoutDestinationController.dispose();
    _transferReferenceController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument(bool isKyc) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    setState(() {
      if (isKyc) {
        _kycFile = File(file.path);
      } else {
        _transferReceiptFile = File(file.path);
      }
    });
  }

  double? _sendAmount() {
    return double.tryParse(_amountController.text.replaceAll(',', ''));
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submit() async {
    final sendAmount = _sendAmount();
    if (_customerNameController.text.trim().isEmpty ||
        _recipientNameController.text.trim().isEmpty ||
        _payoutDestinationController.text.trim().isEmpty ||
        _transferReferenceController.text.trim().isEmpty ||
        _selectedPayoutMethod == null ||
        sendAmount == null ||
        sendAmount <= 0) {
      _show(_t('Complete every required field.', 'أكمل جميع الحقول المطلوبة.'));
      return;
    }
    if (_kycFile == null || _transferReceiptFile == null) {
      _show(_t('Upload KYC and transfer proof.', 'ارفع الهوية وإثبات التحويل.'));
      return;
    }

    setState(() => _submitting = true);
    await MarketplaceService.uploadDocument(_kycFile!);
    await MarketplaceService.uploadDocument(_transferReceiptFile!);
    final order = await MarketplaceService.submitCustomerOrder(
      merchantId: widget.merchant.id,
      pairId: widget.pair.id,
      customerName: _customerNameController.text.trim(),
      recipientName: _recipientNameController.text.trim(),
      payoutMethod: _selectedPayoutMethod!,
      payoutDestination: _payoutDestinationController.text.trim(),
      transferReference: _transferReferenceController.text.trim(),
      sendAmount: sendAmount,
      kycFileName: _kycFile!.path.split(Platform.pathSeparator).last,
      transferReceiptName:
          _transferReceiptFile!.path.split(Platform.pathSeparator).last,
    );
    if (!mounted) return;

    setState(() => _submitting = false);
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => _CustomerOrderTrackingPage(
          orderId: order.id,
          isArabic: widget.isArabic,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sendAmount = _sendAmount();
    final receivePreview = sendAmount == null ? null : sendAmount * _offer.rate;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_t('Submit marketplace order', 'إرسال طلب السوق')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppGradients.exchangeHeader,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppShadows.exchange,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.merchant.name}  •  ${widget.pair.label}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _t(
                    'KYC and transfer proof are validated before the order reaches the merchant queue.',
                    'يتم التحقق من الهوية وإثبات التحويل قبل وصول الطلب إلى قائمة التاجر.',
                  ),
                  style: const TextStyle(
                    color: Color(0xFFD4E3E8),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                _StatusBadge(
                  label: _t(
                    'Rate ${_formatAmount(_offer.rate)} ${widget.pair.receiveCurrency}',
                    'السعر ${_formatAmount(_offer.rate)} ${widget.pair.receiveCurrency}',
                  ),
                  color: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Customer details', 'بيانات العميل'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _customerNameController,
                  decoration: InputDecoration(
                    labelText: _t('Customer full name', 'الاسم الكامل للعميل'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _recipientNameController,
                  decoration: InputDecoration(
                    labelText: _t('Recipient name', 'اسم المستفيد'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _transferReferenceController,
                  decoration: InputDecoration(
                    labelText: _t('Transfer reference / MTCN', 'مرجع التحويل / MTCN'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _t(
                      'Send amount (${widget.pair.sendCurrency})',
                      'مبلغ الإرسال (${widget.pair.sendCurrency})',
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('Estimated payout', 'الصرف المتوقع'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        receivePreview == null
                            ? '--'
                            : '${_formatAmount(receivePreview)} ${widget.pair.receiveCurrency}',
                        style: const TextStyle(
                          color: AppColors.exchangeDark,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Payout destination', 'جهة الصرف'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.merchant.payoutMethods.map((method) {
                    final selected = method == _selectedPayoutMethod;
                    return ChoiceChip(
                      label: Text(method),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedPayoutMethod = method),
                      showCheckmark: false,
                      selectedColor: AppColors.exchangeDark,
                      backgroundColor: AppColors.inputFill,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                        side: BorderSide(
                          color: selected ? AppColors.exchangeDark : AppColors.inputBorder,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _payoutDestinationController,
                  decoration: InputDecoration(
                    labelText: _t(
                      'Payout handle / account number',
                      'معرف الصرف / رقم الحساب',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Documents', 'المستندات'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _UploadTile(
                  title: _t('KYC document', 'وثيقة الهوية'),
                  subtitle: _t(
                    'Passport or national ID image.',
                    'صورة الجواز أو الهوية الوطنية.',
                  ),
                  fileName: _kycFile?.path.split(Platform.pathSeparator).last,
                  onTap: () => _pickDocument(true),
                ),
                const SizedBox(height: 10),
                _UploadTile(
                  title: _t('Transfer proof', 'إثبات التحويل'),
                  subtitle: _t(
                    'Western Union, MoneyGram, or bank transfer receipt.',
                    'إيصال ويسترن يونيون أو موني جرام أو تحويل بنكي.',
                  ),
                  fileName:
                      _transferReceiptFile?.path.split(Platform.pathSeparator).last,
                  onTap: () => _pickDocument(false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: _t('Send to merchant queue', 'إرسال إلى قائمة التاجر'),
            onPressed: _submit,
            isLoading: _submitting,
          ),
        ],
      ),
    );
  }
}

class _CustomerOrderTrackingPage extends StatefulWidget {
  final String orderId;
  final bool isArabic;

  const _CustomerOrderTrackingPage({
    required this.orderId,
    required this.isArabic,
  });

  @override
  State<_CustomerOrderTrackingPage> createState() => _CustomerOrderTrackingPageState();
}

class _CustomerOrderTrackingPageState extends State<_CustomerOrderTrackingPage> {
  MarketplaceOrder? _order;
  bool _loading = true;
  bool _flagging = false;

  String _t(String en, String ar) => _mt(widget.isArabic, en, ar);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final order = await MarketplaceService.getOrderById(widget.orderId);
    if (!mounted) return;
    setState(() {
      _order = order;
      _loading = false;
    });
  }

  Future<void> _raiseDispute() async {
    final controller = TextEditingController(
      text: _t(
        'Funds not received by the beneficiary.',
        'لم يستلم المستفيد الأموال.',
      ),
    );

    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 24,
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Report payout issue', 'الإبلاغ عن مشكلة الصرف'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: _t(
                      'Explain what happened to the recipient.',
                      'اشرح ما حدث للمستفيد.',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: _t('Lock transaction and alert admin', 'إيقاف المعاملة وتنبيه الإدارة'),
                  onPressed: () => Navigator.of(context).pop(
                    controller.text.trim(),
                  ),
                  height: 50,
                ),
              ],
            ),
          ),
        );
      },
    );

    if (reason == null || reason.isEmpty) return;

    setState(() => _flagging = true);
    await MarketplaceService.raiseDispute(orderId: widget.orderId, reason: reason);
    if (!mounted) return;
    setState(() => _flagging = false);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _order == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final order = _order!;
    final timeline = _timelineForOrder(order, widget.isArabic);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_t('Order tracking', 'تتبع الطلب')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppGradients.exchangeHeader,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppShadows.exchange,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.id,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _StatusBadge(
                      label: _statusLabel(order.status, widget.isArabic),
                      color: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${_formatAmount(order.sendAmount)} ${order.sendCurrency}  →  ${_formatAmount(order.receiveAmount)} ${order.receiveCurrency}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${order.merchantName}  •  ${order.payoutMethod}',
                  style: const TextStyle(
                    color: Color(0xFFD4E3E8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (order.status == 'LOCKED')
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _WarningBanner(
                title: _t('Transaction locked', 'تم إيقاف المعاملة'),
                message: _t(
                  'Admin has been alerted and the payout proof is under review.',
                  'تم تنبيه الإدارة ويجري التحقق من إثبات الصرف.',
                ),
              ),
            ),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Status timeline', 'المخطط الزمني'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                ...timeline.map(
                  (step) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TimelineTile(step: step),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Order summary', 'ملخص الطلب'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: _t('Customer', 'العميل'),
                  value: order.customerName,
                ),
                _InfoRow(
                  label: _t('Recipient', 'المستفيد'),
                  value: order.recipientName,
                ),
                _InfoRow(
                  label: _t('Destination', 'الوجهة'),
                  value: order.payoutDestination,
                ),
                _InfoRow(
                  label: _t('Transfer reference', 'مرجع التحويل'),
                  value: order.transferReference,
                ),
                _InfoRow(
                  label: _t('Submitted', 'تاريخ الإرسال'),
                  value: _formatDateTime(order.createdAt),
                ),
                _InfoRow(
                  label: _t('SLA target', 'المهلة'),
                  value: _deadlineText(order.slaDeadline, widget.isArabic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Uploaded documents', 'المستندات المرفوعة'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _StaticDocumentTile(
                  title: _t('KYC file', 'ملف الهوية'),
                  fileName: order.kycFileName,
                ),
                const SizedBox(height: 10),
                _StaticDocumentTile(
                  title: _t('Transfer receipt', 'إيصال التحويل'),
                  fileName: order.transferReceiptName,
                ),
                if (order.payoutReceiptName != null) ...[
                  const SizedBox(height: 10),
                  _StaticDocumentTile(
                    title: _t('Payout receipt', 'إيصال الصرف'),
                    fileName: order.payoutReceiptName!,
                  ),
                ],
              ],
            ),
          ),
          if (_canRaiseDispute(order.status)) ...[
            const SizedBox(height: 18),
            AppButton(
              label: _t('Funds not received', 'لم تصل الأموال'),
              onPressed: _raiseDispute,
              isLoading: _flagging,
            ),
          ],
        ],
      ),
    );
  }
}

class _MerchantExecutionPage extends StatefulWidget {
  final String orderId;
  final bool isArabic;

  const _MerchantExecutionPage({
    required this.orderId,
    required this.isArabic,
  });

  @override
  State<_MerchantExecutionPage> createState() => _MerchantExecutionPageState();
}

class _MerchantExecutionPageState extends State<_MerchantExecutionPage> {
  final _picker = ImagePicker();
  MarketplaceOrder? _order;
  File? _payoutReceiptFile;
  bool _loading = true;
  bool _verifying = false;
  bool _completing = false;

  String _t(String en, String ar) => _mt(widget.isArabic, en, ar);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final order = await MarketplaceService.getOrderById(widget.orderId);
    if (!mounted) return;
    setState(() {
      _order = order;
      _loading = false;
    });
  }

  Future<void> _verifyTransfer() async {
    setState(() => _verifying = true);
    await MarketplaceService.verifyIncomingTransfer(widget.orderId);
    if (!mounted) return;
    setState(() => _verifying = false);
    await _load();
  }

  Future<void> _pickPayoutReceipt() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    setState(() => _payoutReceiptFile = File(file.path));
  }

  Future<void> _completePayout() async {
    if (_payoutReceiptFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('Upload the payout receipt first.', 'ارفع إيصال الصرف أولاً.'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _completing = true);
    await MarketplaceService.uploadDocument(_payoutReceiptFile!);
    await MarketplaceService.completePayout(
      orderId: widget.orderId,
      payoutReceiptName: _payoutReceiptFile!.path.split(Platform.pathSeparator).last,
    );
    if (!mounted) return;
    setState(() => _completing = false);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _order == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final order = _order!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_t('Merchant execution', 'تنفيذ التاجر')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppGradients.exchangeHeader,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppShadows.exchange,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.id,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${order.customerName}  •  ${order.pairLabel}',
                  style: const TextStyle(
                    color: Color(0xFFD4E3E8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _StatusBadge(
                  label: _statusLabel(order.status, widget.isArabic),
                  color: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (order.status == 'LOCKED')
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _WarningBanner(
                title: _t('Case locked by customer dispute', 'الحالة موقوفة بسبب نزاع'),
                message: _t(
                  'Admin review is required before any further settlement action.',
                  'مراجعة الإدارة مطلوبة قبل أي إجراء إضافي.',
                ),
              ),
            ),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Customer documents', 'مستندات العميل'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _StaticDocumentTile(
                  title: _t('KYC file', 'ملف الهوية'),
                  fileName: order.kycFileName,
                ),
                const SizedBox(height: 10),
                _StaticDocumentTile(
                  title: _t('Transfer proof', 'إثبات التحويل'),
                  fileName: order.transferReceiptName,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Payout instructions', 'تعليمات الصرف'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: _t('Recipient', 'المستفيد'),
                  value: order.recipientName,
                ),
                _InfoRow(
                  label: _t('Method', 'الوسيلة'),
                  value: order.payoutMethod,
                ),
                _InfoRow(
                  label: _t('Destination', 'الوجهة'),
                  value: order.payoutDestination,
                ),
                _InfoRow(
                  label: _t('Expected payout', 'الصرف المتوقع'),
                  value:
                      '${_formatAmount(order.receiveAmount)} ${order.receiveCurrency}',
                ),
                _InfoRow(
                  label: _t('SLA target', 'المهلة'),
                  value: _deadlineText(order.slaDeadline, widget.isArabic),
                ),
              ],
            ),
          ),
          if (order.status == 'UNDER_REVIEW') ...[
            const SizedBox(height: 18),
            AppButton(
              label: _t('Verify transfer in external terminal', 'التحقق من التحويل في النظام الخارجي'),
              onPressed: _verifyTransfer,
              isLoading: _verifying,
            ),
          ],
          if (order.status == 'READY_FOR_PAYOUT' || order.status == 'COMPLETED') ...[
            const SizedBox(height: 12),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('Payout receipt', 'إيصال الصرف'),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (order.payoutReceiptName != null)
                    _StaticDocumentTile(
                      title: _t('Uploaded proof', 'الإثبات المرفوع'),
                      fileName: order.payoutReceiptName!,
                    )
                  else
                    _UploadTile(
                      title: _t('Upload payout receipt', 'رفع إيصال الصرف'),
                      subtitle: _t(
                        'Merchant must upload proof before marking complete.',
                        'يجب على التاجر رفع الإثبات قبل الإكمال.',
                      ),
                      fileName: _payoutReceiptFile?.path
                          .split(Platform.pathSeparator)
                          .last,
                      onTap: _pickPayoutReceipt,
                    ),
                ],
              ),
            ),
          ],
          if (order.status == 'READY_FOR_PAYOUT') ...[
            const SizedBox(height: 18),
            AppButton(
              label: _t('Mark completed with payout receipt', 'إنهاء الطلب مع إيصال الصرف'),
              onPressed: _completePayout,
              isLoading: _completing,
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminDisputePage extends StatefulWidget {
  final String disputeCaseId;
  final bool isArabic;

  const _AdminDisputePage({
    required this.disputeCaseId,
    required this.isArabic,
  });

  @override
  State<_AdminDisputePage> createState() => _AdminDisputePageState();
}

class _AdminDisputePageState extends State<_AdminDisputePage> {
  MarketplaceDisputeCase? _disputeCase;
  MarketplaceOrder? _order;
  bool _loading = true;
  bool _actionLoading = false;

  String _t(String en, String ar) => _mt(widget.isArabic, en, ar);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final disputeCase =
        await MarketplaceService.getDisputeCaseById(widget.disputeCaseId);
    final order = await MarketplaceService.getOrderById(disputeCase.orderId);
    if (!mounted) return;
    setState(() {
      _disputeCase = disputeCase;
      _order = order;
      _loading = false;
    });
  }

  Future<void> _verifyReceipt() async {
    setState(() => _actionLoading = true);
    await MarketplaceService.verifyMerchantProof(widget.disputeCaseId);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    await _load();
  }

  Future<void> _requestEvidence() async {
    setState(() => _actionLoading = true);
    await MarketplaceService.requestMoreEvidence(widget.disputeCaseId);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _disputeCase == null || _order == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final disputeCase = _disputeCase!;
    final order = _order!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_t('Dispute review', 'مراجعة النزاع')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppGradients.exchangeHeader,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppShadows.exchange,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disputeCase.id,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${order.id}  •  ${disputeCase.merchantName}',
                  style: const TextStyle(
                    color: Color(0xFFD4E3E8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusBadge(
                      label: _statusLabel(disputeCase.status, widget.isArabic),
                      color: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.14),
                    ),
                    _StatusBadge(
                      label: '${_t('Priority', 'الأولوية')}: ${disputeCase.priority}',
                      color: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Dispute summary', 'ملخص النزاع'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: _t('Customer', 'العميل'),
                  value: disputeCase.customerName,
                ),
                _InfoRow(
                  label: _t('Reason', 'السبب'),
                  value: disputeCase.reason,
                ),
                _InfoRow(
                  label: _t('Opened', 'تاريخ الفتح'),
                  value: _formatDateTime(disputeCase.openedAt),
                ),
                _InfoRow(
                  label: _t('Review deadline', 'موعد المراجعة'),
                  value: _deadlineText(disputeCase.reviewDeadline, widget.isArabic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Evidence review', 'مراجعة الأدلة'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _StaticDocumentTile(
                  title: _t('Customer KYC', 'هوية العميل'),
                  fileName: order.kycFileName,
                ),
                const SizedBox(height: 10),
                _StaticDocumentTile(
                  title: _t('Transfer receipt', 'إيصال التحويل'),
                  fileName: order.transferReceiptName,
                ),
                const SizedBox(height: 10),
                if (order.payoutReceiptName != null)
                  _StaticDocumentTile(
                    title: _t('Merchant payout receipt', 'إيصال صرف التاجر'),
                    fileName: order.payoutReceiptName!,
                  )
                else
                  _WarningBanner(
                    title: _t('Missing merchant proof', 'إثبات التاجر مفقود'),
                    message: _t(
                      'The merchant marked a payout step without uploading receipt evidence.',
                      'تمت خطوة الصرف دون رفع إيصال إثبات من التاجر.',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Locked order details', 'تفاصيل الطلب الموقوف'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: _t('Route', 'المسار'),
                  value: order.pairLabel,
                ),
                _InfoRow(
                  label: _t('Destination', 'الوجهة'),
                  value: '${order.payoutMethod} / ${order.payoutDestination}',
                ),
                _InfoRow(
                  label: _t('Amount', 'المبلغ'),
                  value:
                      '${_formatAmount(order.receiveAmount)} ${order.receiveCurrency}',
                ),
                _InfoRow(
                  label: _t('Merchant status', 'حالة التاجر'),
                  value: _statusLabel(order.status, widget.isArabic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: _t('Verify merchant payout receipt', 'التحقق من إيصال الصرف'),
            onPressed: order.payoutReceiptName == null ? null : _verifyReceipt,
            isLoading: _actionLoading,
          ),
          const SizedBox(height: 10),
          AppButton(
            label: _t('Request more evidence', 'طلب أدلة إضافية'),
            onPressed: _requestEvidence,
          ),
        ],
      ),
    );
  }
}

class _WorkspaceToggle extends StatelessWidget {
  final int activeIndex;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  const _WorkspaceToggle({
    required this.activeIndex,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = index == activeIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppColors.exchangeDark : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? accentColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final tone = accentColor ?? AppColors.exchangeDark;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tone, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: tone,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchantMarketplaceCard extends StatelessWidget {
  final ExchangeHouse merchant;
  final ExchangeHouseOffer offer;
  final String receiveCurrency;
  final VoidCallback onTap;
  final bool isArabic;

  const _MerchantMarketplaceCard({
    required this.merchant,
    required this.offer,
    required this.receiveCurrency,
    required this.onTap,
    required this.isArabic,
  });

  String _t(String en, String ar) => _mt(isArabic, en, ar);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          merchant.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          merchant.region,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(
                    label: _t('Active', 'نشط'),
                    color: AppColors.success,
                    backgroundColor: const Color(0xFFE7F9F1),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MiniMetric(
                      label: _t('Rate', 'السعر'),
                      value: '${_formatAmount(offer.rate)} $receiveCurrency',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetric(
                      label: _t('ETA', 'الوقت'),
                      value: _t(
                        '${merchant.avgCompletionMinutes} min',
                        '${merchant.avgCompletionMinutes} دقيقة',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetric(
                      label: _t('Rating', 'التقييم'),
                      value: merchant.rating.toStringAsFixed(1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: merchant.payoutMethods
                    .take(3)
                    .map((method) => _TagChip(label: method))
                    .toList(),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      merchant.liquidityLabel,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onTap,
                    child: Text(_t('Open profile', 'فتح الملف')),
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

class _MerchantQueueCard extends StatelessWidget {
  final MarketplaceOrder order;
  final bool isArabic;
  final VoidCallback onTap;

  const _MerchantQueueCard({
    required this.order,
    required this.isArabic,
    required this.onTap,
  });

  String _t(String en, String ar) => _mt(isArabic, en, ar);

  @override
  Widget build(BuildContext context) {
    final atRisk = order.status != 'COMPLETED' &&
        order.status != 'LOCKED' &&
        order.slaDeadline.difference(DateTime.now()).inMinutes <= 10;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
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
                      order.id,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _StatusBadge(
                    label: _statusLabel(order.status, isArabic),
                    color: _statusColor(order.status),
                    backgroundColor: _statusBackground(order.status),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${order.customerName}  →  ${order.recipientName}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatAmount(order.receiveAmount)} ${order.receiveCurrency}  •  ${order.payoutMethod}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MiniMetric(
                      label: _t('Submitted', 'أرسل'),
                      value: _formatDateTime(order.createdAt),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetric(
                      label: _t('SLA', 'المهلة'),
                      value: _deadlineText(order.slaDeadline, isArabic),
                      tone: atRisk ? AppColors.error : AppColors.exchangeDark,
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

class _AdminCaseCard extends StatelessWidget {
  final MarketplaceDisputeCase item;
  final bool isArabic;
  final VoidCallback onTap;

  const _AdminCaseCard({
    required this.item,
    required this.isArabic,
    required this.onTap,
  });

  String _t(String en, String ar) => _mt(isArabic, en, ar);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
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
                      item.id,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _StatusBadge(
                    label: _statusLabel(item.status, isArabic),
                    color: _statusColor(item.status),
                    backgroundColor: _statusBackground(item.status),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${item.customerName}  •  ${item.merchantName}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.reason,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MiniMetric(
                      label: _t('Priority', 'الأولوية'),
                      value: item.priority,
                      tone: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetric(
                      label: _t('Review deadline', 'موعد المراجعة'),
                      value: _deadlineText(item.reviewDeadline, isArabic),
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

class _WatchlistCard extends StatelessWidget {
  final MarketplaceOrder order;
  final bool isArabic;

  const _WatchlistCard({
    required this.order,
    required this.isArabic,
  });

  String _t(String en, String ar) => _mt(isArabic, en, ar);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
                  order.id,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusBadge(
                label: _statusLabel(order.status, isArabic),
                color: _statusColor(order.status),
                backgroundColor: _statusBackground(order.status),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${order.merchantName}  •  ${order.customerName}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_t('Deadline', 'المهلة')}: ${_deadlineText(order.slaDeadline, isArabic)}',
            style: const TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? fileName;
  final VoidCallback onTap;

  const _UploadTile({
    required this.title,
    required this.subtitle,
    required this.fileName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inputFill,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.exchangeDark.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.upload_file_rounded,
                  color: AppColors.exchangeDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName ?? title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaticDocumentTile extends StatelessWidget {
  final String title;
  final String fileName;

  const _StaticDocumentTile({
    required this.title,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.exchangeDark.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.insert_drive_file_outlined,
              color: AppColors.exchangeDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fileName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color backgroundColor;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool tinted;

  const _TagChip({
    required this.label,
    this.tinted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tinted ? const Color(0xFFE9F1FF) : AppColors.inputFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: tinted ? const Color(0xFFCEE0FF) : AppColors.inputBorder,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tinted ? const Color(0xFF155EEF) : AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? tone;

  const _MiniMetric({
    required this.label,
    required this.value,
    this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final color = tone ?? AppColors.exchangeDark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
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
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final _TimelineStepData step;

  const _TimelineTile({
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    final color = step.blocked
        ? AppColors.error
        : step.done || step.active
            ? AppColors.exchangeDark
            : AppColors.textHint;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(step.done || step.active ? 0.12 : 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            step.blocked
                ? Icons.lock_outline_rounded
                : step.done
                    ? Icons.check_rounded
                    : Icons.circle_outlined,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: TextStyle(
                  color: step.done || step.active
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step.subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final String title;
  final String message;

  const _WarningBanner({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD6D6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
