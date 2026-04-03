import 'package:flutter/material.dart';
import '../widgets/error_dialog.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Set in main.dart to avoid circular imports with LoginPage
  static VoidCallback? _goToLoginCallback;

  static void setLoginCallback(VoidCallback cb) => _goToLoginCallback = cb;

  static void goToLogin() => _goToLoginCallback?.call();

  static Future<void> showErrorDialog(String message) {
    final context = navigatorKey.currentContext;
    if (context == null) return Future.value();
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ErrorDialog(message: message),
    );
  }
}
