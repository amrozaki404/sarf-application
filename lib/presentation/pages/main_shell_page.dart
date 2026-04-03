import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/localization/locale_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/auth_models.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/notification_service.dart';
import '../auth/login_page.dart';
import '../home/home_page.dart';
import '../home/wallet_page.dart';
import 'notifications_page.dart';
import 'p2p_history_page.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  static _MainShellPageState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MainShellPageState>();
  }

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;
  final Set<int> _loadedIndexes = {0};

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  String _t(String en, String ar) => _isArabic ? ar : en;

  int get _safeCurrentIndex {
    if (_currentIndex < 0) return 0;
    if (_currentIndex >= _pageBuilders.length) {
      return _pageBuilders.length - 1;
    }
    return _currentIndex;
  }

  void changeTab(int index) {
    if (index < 0 || index >= _pageBuilders.length || !mounted) return;
    setState(() {
      _currentIndex = index;
      _loadedIndexes.add(index);
    });
  }

  void refreshForLocaleChange() {
    if (!mounted) return;
    setState(() {
      _loadedIndexes
        ..clear()
        ..add(_safeCurrentIndex);
    });
  }

  late final List<Widget Function()> _pageBuilders = [
    () => HomePage(key: ValueKey('home-${LocaleService.locale.languageCode}')),
    () => P2PHistoryPage(
          key: ValueKey('history-${LocaleService.locale.languageCode}'),
        ),
    () => MorePage(key: ValueKey('more-${LocaleService.locale.languageCode}')),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = _safeCurrentIndex;
    final items = [
      _BottomNavItem(
        icon: Icons.home_rounded,
        label: _t('Home', 'الرئيسية'),
      ),
      _BottomNavItem(
        icon: Icons.receipt_long_rounded,
        label: _t('History', 'السجل'),
      ),
      _BottomNavItem(
        icon: Icons.menu_rounded,
        label: _t('More', 'المزيد'),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: currentIndex,
        children: List.generate(_pageBuilders.length, (index) {
          if (!_loadedIndexes.contains(index)) {
            return const SizedBox.shrink();
          }
          return _pageBuilders[index]();
        }),
      ),
      bottomNavigationBar: Container(
        height: 86,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0E2B37).withOpacity(0.10),
              blurRadius: 22,
              offset: const Offset(0, -6),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final selected = currentIndex == index;
            final item = items[index];
            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => changeTab(index),
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 62,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          color: selected
                              ? AppColors.exchangeDark
                              : AppColors.textHint,
                          size: 21,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? AppColors.exchangeDark
                                : AppColors.textSecondary,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _BottomNavItem {
  final IconData icon;
  final String label;

  _BottomNavItem({
    required this.icon,
    required this.label,
  });
}

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  static const Color _surfaceBorder = Color(0xFFE7E9EF);
  static const Color _deepNavy = Color(0xFF0E2344);
  static const Color _softBlue = Color(0xFF1A73E8);
  static const Color _mistBlue = Color(0xFFF5F8FF);
  static const Color _rose = Color(0xFFFFF0EC);

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

  Future<void> _toggleLanguage() async {
    await LocaleService.toggle();
    if (!mounted) return;
    await context.setLocale(LocaleService.locale);
    MainShellPage.of(context)?.refreshForLocaleChange();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openAccount() async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'No account data found. Please sign in again.',
              'لا توجد بيانات حساب. يرجى تسجيل الدخول مرة أخرى.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WalletPage(user: _user!)),
    );
    await _loadUser();
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Column(
          crossAxisAlignment:
              _isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'صرف',
              textAlign: _isArabic ? TextAlign.right : TextAlign.left,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _t('Version 1.0.0', 'الإصدار 1.0.0'),
              textAlign: _isArabic ? TextAlign.right : TextAlign.left,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              _isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              _t(
                'Sarf is a currency pricing and exchange service focused on Sudanese market needs. The app helps users follow exchange prices, use conversion tools, and access supported financial services.',
                'صرف هو تطبيق لخدمات أسعار وتحويل العملات يركز على احتياجات السوق السوداني. يساعد التطبيق المستخدمين على متابعة أسعار الصرف واستخدام أدوات التحويل والوصول إلى الخدمات المالية المدعومة.',
              ),
              textAlign: _isArabic ? TextAlign.right : TextAlign.left,
              style: const TextStyle(
                color: AppColors.textPrimary,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _aboutInfoRow(
              _t('Core services', 'الخدمات الأساسية'),
              _t(
                'Transfers, transaction history, account access, and support.',
                'التحويلات، سجل المعاملات، الوصول إلى الحساب، والدعم.',
              ),
            ),
            const SizedBox(height: 10),
            _aboutInfoRow(
              _t('Support', 'الدعم'),
              'WhatsApp +249115979161',
            ),
            const SizedBox(height: 10),
            _aboutInfoRow(
              _t('Developer', 'المطور'),
              'A Solutions',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_t('Close', 'إغلاق')),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/249115979161');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _t(
            'WhatsApp could not be opened on this device.',
            'تعذر فتح واتساب على هذا الجهاز.',
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = (_user?.fullName.trim().isNotEmpty ?? false)
        ? _user!.fullName.trim()
        : _t('Guest', 'المستخدم');
    final avatarText = displayName[0].toUpperCase();
    final unreadCount = NotificationService.unreadCount;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            _buildTopBar(avatarText),
            const SizedBox(height: 22),
            _item(
              Icons.language_rounded,
              _t('Language', 'اللغة'),
              subtitle: LocaleService.isArabic ? 'English' : 'العربية',
              onTap: _toggleLanguage,
              iconColor: _softBlue,
              iconBackground: _mistBlue,
            ),
            _item(
              Icons.person_outline_rounded,
              _t('Account', 'الحساب'),
              subtitle: _user?.fullName,
              onTap: _openAccount,
              iconColor: _deepNavy,
              iconBackground: const Color(0xFFF2F4F7),
            ),
            _item(
              Icons.logout_rounded,
              _t('Logout', 'تسجيل الخروج'),
              subtitle: _t(
                'Sign out from your account on this device',
                'تسجيل الخروج من حسابك على هذا الجهاز',
              ),
              onTap: _logout,
              iconColor: const Color(0xFFD92D20),
              iconBackground: _rose,
              titleColor: const Color(0xFFD92D20),
              trailingColor: const Color(0xFFD92D20),
            ),
          ],
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
            child: _MoreTopCircleButton(
              icon: Icons.menu_rounded,
              foreground: const Color(0xFF6E7688),
              background: Colors.white,
              borderColor: _surfaceBorder,
            ),
          ),
          const Center(child: _MoreBrandMark()),
          Align(
            alignment: Alignment.centerRight,
            child: _MoreTopCircleButton(
              label: avatarText,
              foreground: Colors.white,
              background: _deepNavy,
              borderColor: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(String displayName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_deepNavy, _softBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _softBlue.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -18,
            right: _isArabic ? null : -10,
            left: _isArabic ? -10 : null,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: _isArabic ? null : -20,
            right: _isArabic ? -20 : null,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment:
                _isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _t('Account & support', 'الحساب والدعم'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                displayName,
                textAlign: _isArabic ? TextAlign.right : TextAlign.left,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _t(
                  'Control your account settings, support, and app preferences from one place.',
                  'تحكم في إعدادات الحساب والدعم وتفضيلات التطبيق من مكان واحد.',
                ),
                textAlign: _isArabic ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                textDirection:
                    _isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                children: [
                  Expanded(
                    child: _heroStat(
                      title: _t('Language', 'اللغة'),
                      value: LocaleService.isArabic ? 'AR / EN' : 'EN / AR',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _heroStat(
                      title: _t('Support', 'الدعم'),
                      value: 'WhatsApp',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment:
            _isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: _isArabic ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              color: Colors.white.withOpacity(0.76),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: _isArabic ? TextAlign.right : TextAlign.left,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, String subtitle) {
    return Column(
      crossAxisAlignment:
          _isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: _isArabic ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            color: Color(0xFF101828),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: _isArabic ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF103B2E), Color(0xFF1E8A57)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E8A57).withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        textDirection: _isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF25D366),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  _isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Contact us', 'تواصل معنا'),
                  textAlign: _isArabic ? TextAlign.right : TextAlign.left,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'WhatsApp  +249115979161',
                  textAlign: _isArabic ? TextAlign.right : TextAlign.left,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.74),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _openWhatsApp,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(_t('Open', 'فتح')),
          ),
        ],
      ),
    );
  }

  Widget _aboutInfoRow(String title, String value) {
    return Column(
      crossAxisAlignment:
          _isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: _isArabic ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: _isArabic ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _item(
    IconData icon,
    String title, {
    String? subtitle,
    Color? iconColor,
    Color? iconBackground,
    Color? titleColor,
    Color? trailingColor,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE7E9EF)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            textDirection:
                _isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBackground ?? const Color(0xFFF3F7F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.exchangeDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      _isArabic
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: _isArabic ? TextAlign.right : TextAlign.left,
                      style: TextStyle(
                        color: titleColor ?? AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        textAlign:
                            _isArabic ? TextAlign.right : TextAlign.left,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                textDirection:
                    _isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                children: [
                  if (badgeText != null) ...[
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 26,
                        minHeight: 26,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isArabic
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      color: trailingColor ?? AppColors.textHint,
                      size: 18,
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

class _MoreTopCircleButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final Color foreground;
  final Color background;
  final Color borderColor;
  final VoidCallback? onTap;

  const _MoreTopCircleButton({
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

class _MoreBrandMark extends StatelessWidget {
  const _MoreBrandMark();

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
