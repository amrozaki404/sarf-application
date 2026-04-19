import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/auth_models.dart';
import '../../data/models/international_transfer_models.dart'
    show TransferService;
import '../../data/services/auth_service.dart';
import '../../data/services/international_transfer_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/wallet_service.dart';
import '../pages/notifications_page.dart';
import '../pages/international_transfer_page.dart';
import '../pages/gift_card_page.dart';
import '../pages/main_shell_page.dart' show MorePage;
import '../pages/p2p_exchange_page.dart';
import '../pages/transactions_page.dart';
import '../pages/digital_subscriptions_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AuthData? _user;
  int _unreadCount = 0;
  List<TransferService> _services = [];
  double _balance = 0;
  bool _balanceVisible = true;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';
  String _t(String en, String ar) => _isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadUser(), _loadHomeData()]);
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (!mounted) return;
    setState(() => _user = user);
  }

  Future<void> _loadHomeData() async {
    final results = await Future.wait([
      NotificationService.getUnreadCount(),
      InternationalTransferService.getServices(),
      WalletService.getBalance(),
    ]);
    if (!mounted) return;
    setState(() {
      _unreadCount = results[0] as int;
      _services = results[1] as List<TransferService>;
      _balance = results[2] as double;
    });
  }

  Future<void> _openService(TransferService service) async {
    switch (service.routeType) {
      case 'INTERNATIONAL_TRANSFER':
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const InternationalTransferPage()),
        );
        break;
      case 'LOCAL_TRANSFER':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => P2PExchangePage(initialServiceCode: service.code),
          ),
        );
        break;
      case 'GIFT_CARD':
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GiftCardPage()),
        );
        break;
      case 'DIGITAL_SUBSCRIPTION':
        await Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => const DigitalSubscriptionsPage()),
        );
        break;
      case 'COMING_SOON':
      default:
        _showComingSoon(service.name);
        return;
    }
    if (mounted) _loadHomeData();
  }

  void _showComingSoon(String serviceName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(_t('$serviceName — Coming soon!', '$serviceName — قريباً!')),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
    final count = await NotificationService.getUnreadCount();
    if (mounted) setState(() => _unreadCount = count);
  }

  // ── Service helpers ────────────────────────────────────────────────────────

  String _serviceTitle(TransferService service) {
    if (service.routeType == 'GIFT_CARD') {
      return _t('Gift Cards', 'بطاقات الهدايا');
    }
    if (service.routeType == 'DIGITAL_SUBSCRIPTION') {
      return _t('Digital Subscriptions', 'الاشتراكات الرقمية');
    }
    return service.name;
  }

  IconData _serviceIcon(TransferService service) {
    switch (service.routeType) {
      case 'INTERNATIONAL_TRANSFER':
        return Icons.public_rounded;
      case 'LOCAL_TRANSFER':
        return Icons.account_balance_rounded;
      case 'GIFT_CARD':
        return Icons.card_giftcard_rounded;
      case 'DIGITAL_SUBSCRIPTION':
        return Icons.subscriptions_rounded;
      default:
        return Icons.swap_horiz_rounded;
    }
  }

  Color _serviceColor(int index) {
    const colors = [
      Color(0xFF006BFF),
      Color(0xFF06B6D4),
      Color(0xFF8B5CF6),
      Color(0xFFF59E0B),
    ];
    return colors[index % colors.length];
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final firstName = _user?.firstName.trim();
    final initial = (firstName != null && firstName.isNotEmpty)
        ? firstName[0].toUpperCase()
        : (_isArabic ? 'م' : 'G');
    final avatarText = initial;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(avatarText),
            const SizedBox(height: 28),
            _buildServicesSection(),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  // ── Dark Header ────────────────────────────────────────────────────────────

  Widget _buildHeader(String avatarText) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  // Notification button
                  _HeaderCircle(
                    onTap: _openNotifications,
                    child: const Icon(Icons.notifications_none_rounded,
                        color: Colors.white, size: 20),
                    badgeCount: _unreadCount,
                  ),
                  const Spacer(),
                  // Brand mark centered
                  Image.asset('assets/images/app_icon.png',
                      width: 32, height: 32),
                  const SizedBox(width: 8),
                  Text(
                    _isArabic ? 'صرف' : 'Sarf',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  // Avatar
                  _HeaderCircle(
                    filled: true,
                    child: Text(
                      avatarText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Balance section ──
            _buildBalanceSection(),

            const SizedBox(height: 24),

            // ── Action bar (More / Deposit / History) ──
            _buildActionBar(),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  /// Balance display with show/hide toggle — matches screenshot design
  Widget _buildBalanceSection() {
    // Format balance: show as integer if whole, otherwise 2 decimals
    final balanceText = _balance == _balance.truncateToDouble()
        ? _balance.toInt().toString().replaceAllMapped(
              RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]},',
            )
        : _balance.toStringAsFixed(2).replaceAllMapped(
              RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]},',
            );

    return Column(
      children: [
        // Label row with wallet icon
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _t('Total Balance', 'الرصيد الإجمالي'),
              style: TextStyle(
                color: Colors.white.withOpacity(0.70),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Balance number + eye toggle
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _balanceVisible ? balanceText : '••••••',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w900,
                height: 1.1,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() => _balanceVisible = !_balanceVisible),
              child: Icon(
                _balanceVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.white.withOpacity(0.60),
                size: 22,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// White rounded action bar with More / Deposit / History
  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // More
              Expanded(
                child: _ActionBarItem(
                  icon: Icons.more_horiz_rounded,
                  label: _t('More', 'المزيد'),
                  onTap: _openMore,
                ),
              ),
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: const Color(0xFFE7E9EF),
              ),
              // Deposit
              Expanded(
                child: _ActionBarItem(
                  icon: Icons.add_rounded,
                  label: _t('Deposit', 'إيداع'),
                  onTap: _openDeposit,
                ),
              ),
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: const Color(0xFFE7E9EF),
              ),
              // History
              Expanded(
                child: _ActionBarItem(
                  icon: Icons.receipt_long_rounded,
                  label: _t('History', 'السجل'),
                  onTap: _openHistory,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openMore() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MorePage()),
    );
    if (mounted) _loadHomeData();
  }

  void _openDeposit() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t('Deposit — Coming soon!', 'الإيداع — قريباً!')),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TransactionsPage()),
    );
    if (mounted) _loadHomeData();
  }

  // ── Services Section ───────────────────────────────────────────────────────

  Widget _buildServicesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment:
            _isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            _t('Services', 'الخدمات'),
            style: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _services.isEmpty ? _buildSkeletonGrid() : _buildServiceCards(),
        ],
      ),
    );
  }

  Widget _buildServiceCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: List.generate(_services.length, (index) {
        final service = _services[index];
        return _ServiceCard(
          title: _serviceTitle(service),
          icon: _serviceIcon(service),
          color: _serviceColor(index),
          logoUrl: service.logoUrl,
          onTap: () => _openService(service),
        );
      }),
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: List.generate(4, (_) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4F8),
          borderRadius: BorderRadius.circular(18),
        ),
      )),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ── Private Widgets ──────────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════

/// Circle button used in the header (notification / avatar)
class _HeaderCircle extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final int badgeCount;
  final bool filled;

  const _HeaderCircle({
    required this.child,
    this.onTap,
    this.badgeCount = 0,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: filled
            ? Colors.white.withOpacity(0.22)
            : Colors.white.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      alignment: Alignment.center,
      child: child,
    );

    final widget = Stack(
      clipBehavior: Clip.none,
      children: [
        circle,
        if (badgeCount > 0)
          PositionedDirectional(
            end: -4,
            top: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );

    if (onTap == null) return widget;
    return GestureDetector(onTap: onTap, child: widget);
  }
}

/// One item inside the white action bar (icon + label, tappable)
class _ActionBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionBarItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF101828), size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual white service card
class _ServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String? logoUrl;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.icon,
    required this.color,
    this.logoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildIcon(),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF1D2939),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          logoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Center(child: Icon(icon, color: color, size: 22)),
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: color),
                  ),
                ),
        ),
      );
    }
    return Center(child: Icon(icon, color: color, size: 22));
  }
}
