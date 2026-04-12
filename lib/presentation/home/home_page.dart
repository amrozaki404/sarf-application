import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/auth_models.dart';
import '../../data/models/international_transfer_models.dart'
    show TransferService;
import '../../data/services/auth_service.dart';
import '../../data/services/international_transfer_service.dart';
import '../../data/services/notification_service.dart';
import '../pages/notifications_page.dart';
import '../pages/international_transfer_page.dart';
import '../pages/gift_card_page.dart';
import '../pages/p2p_exchange_page.dart';

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
    ]);
    if (!mounted) return;
    setState(() {
      _unreadCount = results[0] as int;
      _services = results[1] as List<TransferService>;
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
      case 'COMING_SOON':
      default:
        _showComingSoon(service.name);
        break;
    }
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
      default:
        return Icons.swap_horiz_rounded;
    }
  }

  Color _serviceColor(int index) {
    const colors = [
      Color(0xFF006BFF), // brand blue
      Color(0xFF56C51F), // green
      Color(0xFFF59E0B), // amber
      Color(0xFF8B5CF6), // purple
      Color(0xFF06B6D4), // cyan
      Color(0xFFEF4444), // red
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
        gradient: LinearGradient(
          colors: [Color(0xFF071C3F), AppColors.primaryDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
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
            Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white.withOpacity(0.70),
              size: 16,
            ),
            const SizedBox(width: 6),
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

  // ── Services Section ───────────────────────────────────────────────────────

  Widget _buildServicesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment:
            _isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            _t('Services', 'الخدمات'),
            style: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          _services.isEmpty ? _buildSkeletonGrid() : _buildServiceIcons(),
        ],
      ),
    );
  }

  /// Grid of service icons — small colored rounded squares + label underneath
  Widget _buildServiceIcons() {
    // Use a Wrap so items flow naturally in rows of ~4
    return Wrap(
      spacing: 16,
      runSpacing: 20,
      alignment: _isArabic ? WrapAlignment.end : WrapAlignment.start,
      children: List.generate(_services.length, (index) {
        final service = _services[index];
        final color = _serviceColor(index);
        return _ServiceIconTile(
          title: _serviceTitle(service),
          icon: _serviceIcon(service),
          color: color,
          logoUrl: service.logoUrl,
          onTap: () => _openService(service),
        );
      }),
    );
  }

  Widget _buildSkeletonGrid() {
    return Wrap(
      spacing: 16,
      runSpacing: 20,
      children: List.generate(
        4,
        (_) => SizedBox(
          width: 72,
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8ECF1),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 48,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8ECF1),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ),
      ),
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

/// A single service icon tile — colored rounded square with label underneath
class _ServiceIconTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String? logoUrl;
  final VoidCallback onTap;

  const _ServiceIconTile({
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
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon square
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.antiAlias,
              child: logoUrl != null && logoUrl!.isNotEmpty
                  ? Image.network(
                      logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(icon, color: color, size: 28),
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: color,
                                ),
                              ),
                            ),
                    )
                  : Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            // Label
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF344054),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
