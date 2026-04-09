class AppNotification {
  final int id;
  final String category;
  final String title;
  final String content;
  final bool isRead;
  final String createdAt;
  final String? readAt;

  const AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      category: json['category'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] as String,
      readAt: json['readAt'] as String?,
    );
  }
}
