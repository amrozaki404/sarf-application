import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/http/app_http_client.dart';
import '../models/transaction_models.dart';

class TransactionService {
  static Future<List<Transaction>> getTransactions() async {
    try {
      final response = await AppHttpClient.get(
        '${AppConstants.baseUrl}${AppConstants.transactionsEndpoint}',
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>?;
      if (data == null) return [];
      return data
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('getTransactions error: $e');
      return [];
    }
  }
}
