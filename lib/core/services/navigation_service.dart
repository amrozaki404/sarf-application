import 'package:flutter/material.dart';

import '../../data/models/receipt_models.dart';
import '../../presentation/pages/transaction_receipt_page.dart';
import '../widgets/error_dialog.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Set in main.dart to avoid circular imports with LoginPage
  static VoidCallback? _goToLoginCallback;
  static final List<TransactionReceipt> _receiptQueue = [];
  static bool _isShowingReceipt = false;
  static final Set<String> _queuedReceiptKeys = {};

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
