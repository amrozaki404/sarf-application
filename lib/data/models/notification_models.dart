enum NotificationCategory { transfer, account, security, promotion }

class AppNotificationItem {
  final NotificationCategory category;
  final String title;
  final String titleAr;
  final String content;
  final String contentAr;
  final String timeLabel;
  final String timeLabelAr;
  final bool isRead;

  const AppNotificationItem({
    required this.category,
    required this.title,
    required this.titleAr,
    required this.content,
    required this.contentAr,
    required this.timeLabel,
    required this.timeLabelAr,
    required this.isRead,
  });
}
