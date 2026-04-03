import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/auth_models.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/p2p_service.dart';
import '../pages/notifications_page.dart';
import '../pages/p2p_history_page.dart';
import '../pages/p2p_exchange_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color _brandBlue = AppColors.primary;
  static const Color _brandBlueDark = AppColors.primaryDark;
  static const Color _brandGreen = AppColors.secondary;
  static const Color _surfaceBorder = Color(0xFFE7E9EF);

  static const List<_TransactionItem> _transactions = [
    _TransactionItem(
      title: 'International transfer',
      titleAr: 'حوالة دولية',
      logoUrl:
          'https://play-lh.googleusercontent.com/WEI7eaROMpsxYSAWCLGhmJdlTiw94MiS57vpHHOQmBShd25mOi22x6ImBkb3bNiFL7Y=w240-h480-rw',
      time: 'Today, 08:45 PM',
      timeAr: 'اليوم، 08:45 م',
      amount: '+1,250',
      amountColor: Color(0xFF067647),
      status: 'Completed',
      statusAr: 'مكتملة',
      statusIcon: Icons.check_rounded,
      statusColor: Color(0xFF067647),
      statusBackground: Color(0xFFECFDF3),
    ),
    _TransactionItem(
      title: 'Local transfer',
      titleAr: 'تحويل محلي',
      logoUrl:
          'https://play-lh.googleusercontent.com/6ycub52gYLRnYtuE0t-1UC4KsHGaXR84ol0RoezDg7U_ZFkSmSrtig9170O1TXZJQg=w240-h480-rw',
      time: 'Today, 06:10 PM',
      timeAr: 'اليوم، 06:10 م',
      amount: '450,000',
      amountColor: Color(0xFF101828),
      status: 'Pending',
      statusAr: 'قيد التنفيذ',
      statusIcon: Icons.schedule_rounded,
      statusColor: Color(0xFF175CD3),
      statusBackground: Color(0xFFEFF8FF),
    ),
    _TransactionItem(
      title: 'International transfer',
      titleAr: 'حوالة دولية',
      logoUrl:
          'https://scontent.fcai20-6.fna.fbcdn.net/v/t39.30808-6/462913065_554762910465058_8315845462438786345_n.jpg',
      time: 'Yesterday, 11:30 AM',
      timeAr: 'أمس، 11:30 ص',
      amount: '+320',
      amountColor: Color(0xFF101828),
      status: 'In review',
      statusAr: 'قيد المراجعة',
      statusIcon: Icons.hourglass_top_rounded,
      statusColor: Color(0xFFB54708),
      statusBackground: Color(0xFFFFFAEB),
    ),
  ];

  AuthData? _user;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  String _t(String en, String ar) => _isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (!mounted) return;
    setState(() => _user = user);
  }

  Future<void> _openTransfer(String serviceCode) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => P2PExchangePage(initialServiceCode: serviceCode),
      ),
    );
  }

  Future<void> _openTransactionHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const P2PHistoryPage(),
      ),
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotificationsPage(),
      ),
    );
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
          onRefresh: _loadUser,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
            children: [
              _buildTopBar(avatarText),
              const SizedBox(height: 20),
              _buildSectionTitle(),
              const SizedBox(height: 14),
              _ServiceCard(
                title: P2PService.titleFor(
                  P2PService.serviceInternationalTransfer,
                  isArabic: _isArabic,
                ),
                subtitle: _t(
                  'Receive international transfers',
                  'استلام الحوالات الدولية',
                ),
                icon: Icons.currency_exchange_rounded,
                onTap: () =>
                    _openTransfer(P2PService.serviceInternationalTransfer),
                isArabic: _isArabic,
                blue: _brandBlue,
                blueDark: _brandBlueDark,
              ),
              const SizedBox(height: 10),
              _ServiceCard(
                title: P2PService.titleFor(
                  P2PService.serviceLocalTransfer,
                  isArabic: _isArabic,
                ),
                subtitle: _t(
                  'Banks & Wallets transfer',
                  'تحويل بين البنوك والمحافظ',
                ),
                icon: Icons.compare_arrows_rounded,
                onTap: () => _openTransfer(P2PService.serviceLocalTransfer),
                isArabic: _isArabic,
                blue: _brandBlue,
                blueDark: _brandBlueDark,
              ),
              const SizedBox(height: 18),
              _buildLastTransactionsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(String avatarText) {
    final unreadCount = NotificationService.unreadCount;
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
              badgeText: unreadCount > 0 ? '$unreadCount' : null,
              foreground: const Color(0xFF6E7688),
              background: Colors.white,
              borderColor: _surfaceBorder,
            ),
          ),
          Center(
            child: _BrandMark(
              blue: _brandBlue,
            ),
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

  Widget _buildGreeting(String displayName) {
    return Column(
      crossAxisAlignment:
          _isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          _t('Hello, $displayName', 'أهلاً، $displayName'),
          textAlign: _isArabic ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            color: Color(0xFF101828),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _t(
            'Choose the service you want to start now.',
            'اختر الخدمة التي تريد البدء بها الآن.',
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

  Widget _buildLastTransactionsSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EEF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F101828),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            _isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection:
                      _isArabic ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE4E7EC)),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        size: 18,
                        color: Color(0xFF175CD3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _t('Last transactions', 'آخر المعاملات'),
                        textAlign: _isArabic ? TextAlign.right : TextAlign.left,
                        style: const TextStyle(
                          color: Color(0xFF101828),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _openTransactionHistory,
                style: TextButton.styleFrom(
                  foregroundColor: _brandBlue,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFE4E7EC)),
                  ),
                ),
                child: Text(
                  _t('View all', 'عرض الكل'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._transactions.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == _transactions.length - 1 ? 0 : 12,
              ),
              child: _TransactionTile(
                item: item,
                isArabic: _isArabic,
              ),
            );
          }),
        ],
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
  final Color blue;

  const _BrandMark({
    required this.blue,
  });

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
              style: TextStyle(
                color: const Color(0xFF101828),
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
      child: Icon(
        icon,
        color: Colors.white,
        size: 22,
      ),
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

class _TransactionTile extends StatelessWidget {
  final _TransactionItem item;
  final bool isArabic;

  const _TransactionTile({
    required this.item,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: Align(
              alignment:
                  isArabic ? Alignment.centerRight : Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FB),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE4E7EC)),
                    ),
                    alignment: Alignment.center,
                    child: ClipOval(
                      child: _LogoImage(
                        logoUrl: item.logoUrl,
                        width: 34,
                        height: 34,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Column(
                      crossAxisAlignment: isArabic
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isArabic ? item.titleAr : item.title,
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
                          isArabic ? item.timeAr : item.time,
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
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.amount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: item.amountColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: item.statusBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      textDirection: TextDirection.ltr,
                      children: [
                        Icon(
                          item.statusIcon,
                          size: 12,
                          color: item.statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isArabic ? item.statusAr : item.status,
                          style: TextStyle(
                            color: item.statusColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
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

class _TransactionItem {
  final String title;
  final String titleAr;
  final String? logoUrl;
  final String time;
  final String timeAr;
  final String amount;
  final Color amountColor;
  final String status;
  final String statusAr;
  final IconData statusIcon;
  final Color statusColor;
  final Color statusBackground;

  const _TransactionItem({
    required this.title,
    required this.titleAr,
    this.logoUrl,
    required this.time,
    required this.timeAr,
    required this.amount,
    required this.amountColor,
    required this.status,
    required this.statusAr,
    required this.statusIcon,
    required this.statusColor,
    required this.statusBackground,
  });
}

class _LogoImage extends StatelessWidget {
  final String? logoUrl;
  final double width;
  final double height;
  final BoxFit fit;

  const _LogoImage({
    required this.logoUrl,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      'assets/images/app_icon.png',
      width: width,
      height: height,
      fit: fit,
    );

    if (logoUrl == null || logoUrl!.trim().isEmpty) {
      return fallback;
    }

    return Image.network(
      logoUrl!,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return fallback;
      },
    );
  }
}
