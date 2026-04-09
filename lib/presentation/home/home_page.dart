import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/auth_models.dart';
import '../../data/models/international_transfer_models.dart' show TransferService;
import '../../data/services/auth_service.dart';
import '../../data/services/international_transfer_service.dart';
import '../../data/services/notification_service.dart';
import '../pages/notifications_page.dart';
import '../pages/international_transfer_page.dart';
import '../pages/p2p_exchange_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color _brandBlue = AppColors.primary;
  static const Color _brandBlueDark = AppColors.primaryDark;
  static const Color _surfaceBorder = Color(0xFFE7E9EF);

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
          MaterialPageRoute(
            builder: (_) => const InternationalTransferPage(),
          ),
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
        // TODO: navigate to GiftCardPage when implemented
        _showComingSoon(service.name);
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
        content: Text(
          _t(
            '$serviceName — Coming soon!',
            '$serviceName — قريباً!',
          ),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotificationsPage(),
      ),
    );
    // Refresh badge after returning
    final count = await NotificationService.getUnreadCount();
    if (mounted) setState(() => _unreadCount = count);
  }

  IconData _serviceIcon(String code) {
    final c = code.toUpperCase();
    if (c.contains('INTL') || c.contains('INTERNATIONAL')) {
      return Icons.currency_exchange_rounded;
    }
    if (c.contains('LOCAL')) return Icons.compare_arrows_rounded;
    return Icons.swap_horiz_rounded;
  }

  String _serviceSubtitle(String code) {
    final c = code.toUpperCase();
    if (c.contains('INTL') || c.contains('INTERNATIONAL')) {
      return _t('Receive international transfers', 'استلام الحوالات الدولية');
    }
    if (c.contains('LOCAL')) {
      return _t('Banks & Wallets transfer', 'تحويل بين البنوك والمحافظ');
    }
    return '';
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
          color: _brandBlue,
          onRefresh: _loadAll,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
            children: [
              _buildTopBar(avatarText),
              const SizedBox(height: 20),
              _buildSectionTitle(),
              const SizedBox(height: 14),
              ..._services.asMap().entries.map((entry) {
                final service = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.key == _services.length - 1 ? 0 : 10,
                  ),
                  child: _ServiceCard(
                    title: service.name,
                    subtitle: service.description?.isNotEmpty == true
                        ? service.description!
                        : _serviceSubtitle(service.code),
                    icon: _serviceIcon(service.code),
                    onTap: () => _openService(service),
                    isArabic: _isArabic,
                    blue: _brandBlue,
                    blueDark: _brandBlueDark,
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
    return SizedBox(
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _TopCircleButton(
              icon: Icons.notifications_none_rounded,
              onTap: _openNotifications,
              badgeText: _unreadCount > 0 ? '$_unreadCount' : null,
              foreground: const Color(0xFF6E7688),
              background: Colors.white,
              borderColor: _surfaceBorder,
            ),
          ),
          Center(
            child: _BrandMark(blue: _brandBlue),
          ),
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

  Widget _buildSectionTitle() {
    return Align(
      alignment: _isArabic ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        _t('Services', 'الخدمات'),
        textAlign: _isArabic ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          color: Color(0xFF101828),
          fontSize: 27,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

}

// ── Widget helpers ────────────────────────────────────────────────────────────

class _TopCircleButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final Color foreground;
  final Color background;
  final Color borderColor;
  final String? badgeText;
  final VoidCallback? onTap;

  const _TopCircleButton({
    this.icon,
    this.label,
    required this.foreground,
    required this.background,
    required this.borderColor,
    this.badgeText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
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
          ),
          if (badgeText != null)
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
                  badgeText!,
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

    if (onTap == null) return child;

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
  final Color blue;

  const _BrandMark({required this.blue});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/app_icon.png', width: 36, height: 36),
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
                color: blue,
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

class _ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isArabic;
  final Color blue;
  final Color blueDark;

  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.isArabic,
    required this.blue,
    required this.blueDark,
  });

  @override
  Widget build(BuildContext context) {
    final arrow =
        isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded;
    final serviceIcon = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
    final arrowBadge = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(arrow, color: Colors.white, size: 22),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [blue, blueDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: blue.withOpacity(0.24),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              if (isArabic) arrowBadge else serviceIcon,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.78),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (isArabic) serviceIcon else arrowBadge,
            ],
          ),
        ),
      ),
    );
  }
}

