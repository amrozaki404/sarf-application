import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/locale_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/auth_models.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/notification_service.dart';
import '../auth/login_page.dart';
import '../home/home_page.dart';
import '../home/wallet_page.dart';
import 'notifications_page.dart';
import 'transactions_page.dart';

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
    () => TransactionsPage(
          key: ValueKey('transactions-${LocaleService.locale.languageCode}'),
        ),
    () => MorePage(key: ValueKey('more-${LocaleService.locale.languageCode}')),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = _safeCurrentIndex;

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
    );
  }
}

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  static const Color _deepNavy = Color(0xFF0E2344);
  static const Color _softBlue = Color(0xFF1A73E8);
  static const Color _mistBlue = Color(0xFFF5F8FF);
  static const Color _rose = Color(0xFFFFF0EC);

  AuthData? _user;
  int _unreadCount = 0;
  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  String _t(String en, String ar) => _isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadUnreadCount();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (!mounted) return;
    setState(() => _user = user);
  }

  Future<void> _loadUnreadCount() async {
    final count = await NotificationService.getUnreadCount();
    if (!mounted) return;
    setState(() => _unreadCount = count);
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
    _loadUnreadCount();
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
    final firstName = _user?.firstName.trim() ?? '';
    final displayName = firstName.isNotEmpty ? firstName : _t('User', 'المستخدم');
    final initial = displayName[0].toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          _buildProfileHeader(displayName, initial),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(_t('General', 'عام')),
                _item(
                  Icons.language_rounded,
                  _t('Language', 'اللغة'),
                  subtitle: LocaleService.isArabic ? 'English' : 'العربية',
                  onTap: _toggleLanguage,
                  iconColor: _softBlue,
                  iconBackground: _mistBlue,
                ),
                _item(
                  Icons.notifications_none_rounded,
                  _t('Notifications', 'الإشعارات'),
                  badgeText: _unreadCount > 0 ? '$_unreadCount' : null,
                  onTap: _openNotifications,
                  iconColor: const Color(0xFF8B5CF6),
                  iconBackground: const Color(0xFFF3F0FF),
                ),
                const SizedBox(height: 20),
                _sectionTitle(_t('Account', 'الحساب')),
                _item(
                  Icons.person_outline_rounded,
                  _t('Profile', 'الملف الشخصي'),
                  subtitle: _user?.fullName,
                  onTap: _openAccount,
                  iconColor: _deepNavy,
                  iconBackground: const Color(0xFFF2F4F7),
                ),
                const SizedBox(height: 20),
                _sectionTitle(_t('Support', 'الدعم')),
                _item(
                  Icons.chat_bubble_outline_rounded,
                  _t('Contact Us', 'تواصل معنا'),
                  subtitle: 'WhatsApp',
                  onTap: _openWhatsApp,
                  iconColor: const Color(0xFF25D366),
                  iconBackground: const Color(0xFFECFDF5),
                ),
                _item(
                  Icons.info_outline_rounded,
                  _t('About', 'عن التطبيق'),
                  subtitle: _t('Version ${AppConstants.appVersion}', 'الإصدار ${AppConstants.appVersion}'),
                  onTap: _showAbout,
                  iconColor: AppColors.primary,
                  iconBackground: const Color(0xFFEFF6FF),
                ),
                const SizedBox(height: 20),
                _item(
                  Icons.logout_rounded,
                  _t('Logout', 'تسجيل الخروج'),
                  onTap: _logout,
                  iconColor: const Color(0xFFD92D20),
                  iconBackground: _rose,
                  titleColor: const Color(0xFFD92D20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String name, String initial) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('Hello,', 'مرحباً،'),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.70),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
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

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
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
    String? badgeText,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBackground ?? const Color(0xFFF3F7F9),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: iconColor ?? AppColors.exchangeDark, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor ?? AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
            if (badgeText != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}
