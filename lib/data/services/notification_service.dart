import 'dart:convert';
import '../../core/constants/app_constants.dart';
import '../../core/http/app_http_client.dart';
import '../models/notification_models.dart';

class NotificationService {
  // ── Unread count (used by home badge) ─────────────────────────────────────

  static Future<int> getUnreadCount() async {
    try {
      final url = '${AppConstants.baseUrl}${AppConstants.notificationCountEndpoint}';
      final response = await AppHttpClient.get(url);
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['responseCode'] == AppConstants.successCode) {
        final data = json['data'] as Map<String, dynamic>;
        return (data['unreadCount'] as num).toInt();
      }
    } catch (e) {
      // Return 0 on failure — badge just won't show
    }
    return 0;
  }

  // ── Full notification list ─────────────────────────────────────────────────

  static Future<List<AppNotification>> getAll() async {
    try {
      final url = '${AppConstants.baseUrl}${AppConstants.notificationsEndpoint}';
      final response = await AppHttpClient.get(url);
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['responseCode'] == AppConstants.successCode) {
        final list = json['data'] as List<dynamic>;
        return list
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // Return empty list on failure
    }
    return [];
  }

  // ── Mark one notification as read ─────────────────────────────────────────

  static Future<bool> markAsRead(int id) async {
    try {
      final url =
          '${AppConstants.baseUrl}${AppConstants.notificationsEndpoint}/$id/read';
      final response = await AppHttpClient.patch(url);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['responseCode'] == AppConstants.successCode;
    } catch (_) {
      return false;
    }
  }
}
