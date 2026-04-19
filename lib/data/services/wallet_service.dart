import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/http/app_http_client.dart';

class WalletService {
  static Future<double> getBalance() async {
    try {
      final response = await AppHttpClient.get(
        '${AppConstants.baseUrl}${AppConstants.walletBalanceEndpoint}',
      );
      final json = AppHttpClient.decodeJsonMap(response, inspectReceipt: false);
      if (json['responseCode']?.toString() == AppConstants.successCode) {
        final data = json['data'] as Map<String, dynamic>?;
        final raw = data?['balance'];
        if (raw != null) return (raw as num).toDouble();
      }
    } catch (e) {
      debugPrint('WalletService.getBalance error: $e');
    }
    return 0.0;
  }
}
