import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/receipt_models.dart';
import '../../presentation/pages/transaction_receipt_page.dart';
import '../localization/locale_service.dart';
import '../widgets/error_dialog.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Set in main.dart to avoid circular imports with LoginPage
  static VoidCallback? _goToLoginCallback;
  static final List<TransactionReceipt> _receiptQueue = [];
  static bool _isShowingReceipt = false;
  static bool _isShowingSessionExpired = false;
  static final Set<String> _queuedReceiptKeys = {};

  static void setLoginCallback(VoidCallback cb) => _goToLoginCallback = cb;

  static void goToLogin() => _goToLoginCallback?.call();

  static Future<void> showSessionExpiredDialog() async {
    if (_isShowingSessionExpired) return;
    final context = navigatorKey.currentContext;
    if (context == null) {
      goToLogin();
      return;
    }
    _isShowingSessionExpired = true;
    final isAr = LocaleService.isArabic;
    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            contentPadding:
                const EdgeInsets.fromLTRB(24, 28, 24, 8),
            actionsPadding:
                const EdgeInsets.fromLTRB(16, 0, 16, 16),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.lock_clock_outlined,
                      size: 28, color: Color(0xFFB45309)),
                ),
                const SizedBox(height: 16),
                Text(
                  isAr ? 'انتهت الجلسة' : 'Session Expired',
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAr
                      ? 'انتهت صلاحية جلستك. يرجى تسجيل الدخول مجدداً.'
                      : 'Your session has expired. Please sign in again.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: const Color(0xFF667085),
                    height: 1.5,
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006BFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: () =>
                      Navigator.of(_, rootNavigator: true).pop(),
                  child: Text(
                    isAr ? 'تسجيل الدخول' : 'Sign In',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } finally {
      _isShowingSessionExpired = false;
      goToLogin();
    }
  }

  static Future<void> showErrorDialog(String message) {
    final context = navigatorKey.currentContext;
    if (context == null) return Future.value();
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ErrorDialog(message: message),
    );
  }

  static void showTransactionReceipt(TransactionReceipt receipt) {
    final key = receipt.uniqueKey;
    if (!receipt.shouldShow) return;
    if (key.isNotEmpty && _queuedReceiptKeys.contains(key)) return;

    _receiptQueue.add(receipt);
    if (key.isNotEmpty) _queuedReceiptKeys.add(key);
    _drainReceiptQueue();
  }

  static Future<void> _drainReceiptQueue() async {
    if (_isShowingReceipt || _receiptQueue.isEmpty) return;

    final context = navigatorKey.currentContext ??
        navigatorKey.currentState?.overlay?.context;
    if (context == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _drainReceiptQueue());
      return;
    }

    final receipt = _receiptQueue.removeAt(0);
    final key = receipt.uniqueKey;
    _isShowingReceipt = true;

    try {
      // Dismiss any open bottom sheets before showing the receipt
      navigatorKey.currentState
          ?.popUntil((route) => route is! ModalBottomSheetRoute);

      await Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute(
          builder: (_) => TransactionReceiptPage(receipt: receipt),
          fullscreenDialog: true,
        ),
      );
    } finally {
      if (key.isNotEmpty) _queuedReceiptKeys.remove(key);
      _isShowingReceipt = false;
      if (_receiptQueue.isNotEmpty) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _drainReceiptQueue());
      }
    }
  }
}
