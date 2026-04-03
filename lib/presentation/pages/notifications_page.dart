import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/auth_models.dart';
import '../../data/models/notification_models.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const Color _surfaceBorder = Color(0xFFE7E9EF);
  static const LinearGradient _brandGradient = LinearGradient(
    colors: [
      AppColors.primaryDark,
      AppColors.primary,
      AppColors.primaryDark,
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  AuthData? _user;
  _NotificationViewTab _selectedTab = _NotificationViewTab.unread;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  String _t(String en, String ar) => _isArabic ? ar : en;

  List<AppNotificationItem> get _filteredNotifications {
    return NotificationService.notifications.where(_matchesSelectedTab).toList();
  }

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

  bool _matchesSelectedTab(AppNotificationItem item) {
    switch (_selectedTab) {
      case _NotificationViewTab.read:
        return item.isRead;
      case _NotificationViewTab.unread:
        return !item.isRead;
    }
  }

  String _categoryLabel(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.transfer:
        return _t('Transfer', 'التحويلات');
      case NotificationCategory.account:
        return _t('Account', 'الحساب');
      case NotificationCategory.security:
        return _t('Security', 'الأمان');
      case NotificationCategory.promotion:
        return _t('Updates', 'التحديثات');
    }
  }

  Color _categoryColor() {
    return AppColors.primaryDark;
  }

  Color _categoryBackground() {
    return AppColors.primary.withOpacity(0.10);
  }

  Future<void> _showDetails(AppNotificationItem item) {
    final statusLabel = item.isRead ? _t('Read', 'مقروءة') : _t('Unread', 'غير مقروءة');
    final statusColor = item.isRead
        ? const Color(0xFF667085)
        : const Color(0xFF175CD3);
    final statusBackground = item.isRead
        ? const Color(0xFFF2F4F7)
        : const Color(0xFFEFF8FF);

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  _isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 56,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D5DD),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  textDirection:
                      _isArabic ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    _DetailChip(
                      label: statusLabel,
                      color: statusColor,
                      background: statusBackground,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _isArabic ? item.titleAr : item.title,
                  textAlign: _isArabic ? TextAlign.right : TextAlign.left,
                  style: const TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _isArabic ? item.timeLabelAr : item.timeLabel,
                  textAlign: _isArabic ? TextAlign.right : TextAlign.left,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _isArabic ? item.contentAr : item.content,
                  textAlign: _isArabic ? TextAlign.right : TextAlign.left,
                  style: const TextStyle(
                    color: Color(0xFF344054),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _user?.firstName.trim();
    final displayName = (firstName == null || firstName.isEmpty)
        ? _t('Guest', 'المستخدم')
        : firstName;
    final avatarText = displayName[0].toUpperCase();
    final notifications = _filteredNotifications;
    final unreadCount = NotificationService.unreadCount;
    final readCount = NotificationService.readCount;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            _buildTopBar(avatarText),
            const SizedBox(height: 14),
            _buildViewTabs(
              unreadCount: unreadCount,
              readCount: readCount,
            ),
            const SizedBox(height: 18),
            if (notifications.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE7E9EF)),
                ),
                child: Text(
                  _t(
                    'No notifications match the selected filters.',
                    'لا توجد إشعارات تطابق الفلاتر المحددة.',
                  ),
                  textAlign: _isArabic ? TextAlign.right : TextAlign.left,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              ...notifications.asMap().entries.map((entry) {
                final item = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.key == notifications.length - 1 ? 0 : 12,
                  ),
                  child: _NotificationCard(
                    isArabic: _isArabic,
                    item: item,
                    categoryLabel: _categoryLabel(item.category),
                    categoryColor: _categoryColor(),
                    categoryBackground: _categoryBackground(),
                    onTap: () => _showDetails(item),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSummary(int unreadCount) {
    return Column(
      crossAxisAlignment:
          _isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          _t(
            '$unreadCount unread notifications',
            '$unreadCount إشعارات غير مقروءة',
          ),
          textAlign: _isArabic ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(String avatarText) {
    final canPop = Navigator.of(context).canPop();
    final leadingIcon = _isArabic
        ? Icons.arrow_forward_ios_rounded
        : Icons.arrow_back_ios_new_rounded;

    return SizedBox(
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _TopCircleButton(
              icon: canPop ? leadingIcon : Icons.notifications_none_rounded,
              onTap: canPop ? () => Navigator.of(context).pop() : null,
              foreground: const Color(0xFF6E7688),
              background: Colors.white,
              borderColor: _surfaceBorder,
            ),
          ),
          const Center(child: _BrandMark()),
          Align(
            alignment: AlignmentDirectional.centerEnd,
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

  Widget _buildViewTabs({
    required int unreadCount,
    required int readCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        gradient: _brandGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Expanded(
            child: _NotificationTabButton(
              label: _t('Unread', 'غير مقروءة'),
              count: unreadCount,
              selected: _selectedTab == _NotificationViewTab.unread,
              onTap: () => setState(
                () => _selectedTab = _NotificationViewTab.unread,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _NotificationTabButton(
              label: _t('Read', 'مقروءة'),
              count: readCount,
              selected: _selectedTab == _NotificationViewTab.read,
              onTap: () => setState(
                () => _selectedTab = _NotificationViewTab.read,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _NotificationViewTab { unread, read }

class _NotificationCard extends StatelessWidget {
  final bool isArabic;
  final AppNotificationItem item;
  final String categoryLabel;
  final Color categoryColor;
  final Color categoryBackground;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.isArabic,
    required this.item,
    required this.categoryLabel,
    required this.categoryColor,
    required this.categoryBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel =
        item.isRead ? (isArabic ? 'مقروءة' : 'Read') : (isArabic ? 'غير مقروءة' : 'Unread');
    final statusColor =
        item.isRead ? const Color(0xFF667085) : const Color(0xFF175CD3);
    final statusBackground =
        item.isRead ? const Color(0xFFF2F4F7) : const Color(0xFFEFF8FF);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: item.isRead ? Colors.white : const Color(0xFFF8FBFF),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: item.isRead
                  ? const Color(0xFFE7E9EF)
                  : const Color(0xFFD8E5FF),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? item.titleAr : item.title,
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                style: const TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isArabic ? item.contentAr : item.content,
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                style: const TextStyle(
                  color: Color(0xFF475467),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isArabic ? item.timeLabelAr : item.timeLabel,
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 12,
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

class _NotificationTabButton extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _NotificationTabButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? Colors.white
                  : Colors.white.withOpacity(0.16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            textDirection:
                Directionality.of(context),
            children: [
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? AppColors.primaryDark : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withOpacity(0.12)
                      : Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? AppColors.primaryDark : Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
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

class _DetailChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _DetailChip({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
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
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
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
