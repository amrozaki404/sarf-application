import '../models/notification_models.dart';

class NotificationService {
  static const List<AppNotificationItem> _notifications = [
    AppNotificationItem(
      category: NotificationCategory.transfer,
      title: 'Transfer completed',
      titleAr: 'اكتملت الحوالة',
      content:
          'Your international transfer was completed successfully and is ready for pickup.',
      contentAr: 'تم إكمال الحوالة الدولية بنجاح وأصبحت جاهزة للاستلام.',
      timeLabel: 'Today, 08:45 PM',
      timeLabelAr: 'اليوم، 08:45 م',
      isRead: true,
    ),
    AppNotificationItem(
      category: NotificationCategory.account,
      title: 'Profile update required',
      titleAr: 'مطلوب تحديث الملف الشخصي',
      content:
          'Please review your account information to keep transfers running without delays.',
      contentAr: 'يرجى مراجعة بيانات حسابك للحفاظ على تنفيذ الحوالات بدون تأخير.',
      timeLabel: 'Today, 06:10 PM',
      timeLabelAr: 'اليوم، 06:10 م',
      isRead: false,
    ),
    AppNotificationItem(
      category: NotificationCategory.security,
      title: 'New sign in detected',
      titleAr: 'تم اكتشاف تسجيل دخول جديد',
      content:
          'A new device signed in to your account. Review your activity if this was not you.',
      contentAr:
          'تم تسجيل الدخول إلى حسابك من جهاز جديد. راجع نشاطك إذا لم يكن هذا أنت.',
      timeLabel: 'Yesterday, 11:30 AM',
      timeLabelAr: 'أمس، 11:30 ص',
      isRead: false,
    ),
    AppNotificationItem(
      category: NotificationCategory.promotion,
      title: 'Priority processing available',
      titleAr: 'خدمة المعالجة السريعة متاحة',
      content:
          'Priority processing is now available for selected transfer requests.',
      contentAr: 'خدمة المعالجة السريعة متاحة الآن لطلبات تحويل محددة.',
      timeLabel: 'Yesterday, 09:20 AM',
      timeLabelAr: 'أمس، 09:20 ص',
      isRead: true,
    ),
    AppNotificationItem(
      category: NotificationCategory.transfer,
      title: 'Transfer under review',
      titleAr: 'الحوالة قيد المراجعة',
      content:
          'Your local transfer is being reviewed. We will notify you once it is approved.',
      contentAr:
          'الحوالة المحلية الخاصة بك قيد المراجعة. سنقوم بإشعارك عند اعتمادها.',
      timeLabel: 'Mar 31, 01:05 PM',
      timeLabelAr: '31 مارس، 01:05 م',
      isRead: true,
    ),
  ];

  static List<AppNotificationItem> get notifications =>
      List<AppNotificationItem>.unmodifiable(_notifications);

  static int get unreadCount =>
      _notifications.where((item) => !item.isRead).length;

  static int get readCount =>
      _notifications.where((item) => item.isRead).length;
}
