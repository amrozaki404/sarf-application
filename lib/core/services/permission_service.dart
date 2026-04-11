import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request all permissions that are needed at app startup.
  /// Call this once from main() after Flutter binding is initialized.
  static Future<void> requestStartupPermissions() async {
    if (kIsWeb) return;

    // Push notifications (required on Android 13+ and iOS)
    final notifStatus = await Permission.notification.status;
    if (notifStatus.isDenied) {
      await Permission.notification.request();
    }
  }
}
