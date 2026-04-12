import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/auth_models.dart';
import '../../data/models/international_transfer_models.dart' show TransferService;
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
        content: Text(_t('$serviceName — Coming soon!', '$serviceName — قريباً!')),
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

  String _serviceLabel(TransferService service) {
    switch (service.routeType) {
      case 'INTERNATIONAL_TRANSFER':
        return _t('Send', 'إرسال');
      case 'LOCAL_TRANSFER':
        return _t('Local', 'محلي');
      case 'GIFT_CARD':
        return _t('Gift Cards', 'هدايا');
      default:
        return service.name;
    }
  }

  String _serviceSubtitle(TransferService service) {
    if (service.description?.isNotEmpty == true) return service.description!;
    switch (service.routeType) {
      case 'INTERNATIONAL_TRANSFER':
        return _t('Receive international transfers', 'استلام الحوالات الدولية');
      case 'LOCAL_TRANSFER':
        return _t('Banks & Wallets transfer', 'تحويل بين البنوك والمحافظ');
      case 'GIFT_CARD':
        return _t('Buy digital gift cards instantly', 'اشترِ بطاقات هدايا رقمية فوراً');
      default:
        return '';
    }
  }

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

  Color _cardColor(int index) {
    const colors = [
      Color(0xFF006BFF),
      Color(0xFF56C51F),
      Color(0xFFF59E0B),
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
      Color(0xFFEF4444),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _user?.firstName.trim();
    final displayName = (firstName == null || firstName.isEmpty)
        ? _t('Guest', 'المستخدم')
        : firstName;
    final avatarText = displayName[0].toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadAll,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(displayName, avatarText),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 120),
              sliver: SliverToBoxAdapter(
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(String displayName, String avatarText) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF071C3F), AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(avatarText),
            const SizedBox(height: 28),
            _buildGreeting(displayName),
            const SizedBox(height: 28),
            if (_services.isNotEmpty) _buildQuickActions(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(String avatarText) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Notification — start
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _HeaderIconButton(
                onTap: _openNotifications,
                badgeCount: _unreadCount,
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            // Brand — center
            _HeaderBrandMark(isArabic: _isArabic),
            // Avatar — end
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _AvatarCircle(label: avatarText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(String displayName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Align(
        alignment: _isArabic ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              _isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              _t('Welcome back,', 'مرحباً بعودتك،'),
              style: TextStyle(
                color: Colors.white.withOpacity(0.70),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    // Show up to 3 quick-action buttons from live services
    final items = _services.take(3).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: List.generate(items.length, (i) {
          final service = items[i];
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i > 0 ? 10 : 0),
              child: _QuickActionButton(
                icon: _serviceIcon(service),
                label: _serviceLabel(service),
                onTap: () => _openService(service),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Column(
      crossAxisAlignment:
          _isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          _t('Services', 'الخدمات'),
          style: const TextStyle(
            color: Color(0xFF101828),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        _services.isEmpty ? _buildSkeletonGrid() : _buildServicesGrid(),
      ],
    );
  }

  Widget _buildServicesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.05,
      ),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];
        return _ServiceGridCard(
          title: _serviceTitle(service),
          subtitle: _serviceSubtitle(service),
          icon: _serviceIcon(service),
          color: _cardColor(index),
          logoUrl: service.logoUrl,
          onTap: () => _openService(service),
          isArabic: _isArabic,
        );
      },
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.05,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(22),
        ),
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _HeaderIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final int badgeCount;
  final Widget child;

  const _HeaderIconButton({
    required this.onTap,
    required this.child,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.22)),
            ),
            alignment: Alignment.center,
            child: child,
          ),
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
      ),
    );
  }
}

class _HeaderBrandMark extends StatelessWidget {
  final bool isArabic;
  const _HeaderBrandMark({required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/app_icon.png', width: 34, height: 34),
        const SizedBox(width: 9),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'صرف' : 'Sarf',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Pay & Receive',
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 9.5,
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

class _AvatarCircle extends StatelessWidget {
  final String label;
  const _AvatarCircle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.30)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.14),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white.withOpacity(0.15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceGridCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? logoUrl;
  final VoidCallback onTap;
  final bool isArabic;

  const _ServiceGridCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.logoUrl,
    required this.onTap,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.055),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Icon badge
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: logoUrl != null && logoUrl!.isNotEmpty
                      ? Image.network(
                          logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(icon, color: color, size: 26),
                          loadingBuilder: (_, child, progress) =>
                              progress == null
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
                      : Icon(icon, color: color, size: 26),
                ),
                const Spacer(),
                // Title
                Text(
                  title,
                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF667085).withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
