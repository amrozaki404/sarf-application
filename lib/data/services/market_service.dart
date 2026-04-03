import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/http/app_http_client.dart';
import '../models/market_models.dart';

class MarketService {
  static Future<List<CurrencyItem>> getCurrencies() async {
    try {
      final url = '${AppConstants.baseUrl}${AppConstants.currenciesEndpoint}';
      final response = await AppHttpClient.get(url);

      if (response.statusCode != 200) {
        debugPrint(
            '[MarketService][getCurrencies] HTTP ${response.statusCode}');
        return [];
      }

      final dynamic decodedJson = jsonDecode(response.body);

      if (decodedJson is List) {
        return decodedJson
            .map((e) => CurrencyItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('[MarketService][getCurrencies] error: $e');
      return [];
    }
  }

  static Future<List<RateItem>> getRatesForAll({
    required String base,
    required List<String> targets,
  }) async {
    try {
      final targetParams = targets.map(Uri.encodeComponent).join(",");
      final url = '${AppConstants.baseUrl}${AppConstants.ratesAllEndpoint}'
          '?base=${Uri.encodeComponent(base)}'
          '&targets=$targetParams';
      final response = await AppHttpClient.get(url);

      if (response.statusCode != 200) {
        debugPrint(
            '[MarketService][getRatesForAll] HTTP ${response.statusCode}');
        return [];
      }

      final dynamic decodedJson = jsonDecode(response.body);

      if (decodedJson is List) {
        return decodedJson
            .map((e) => RateItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (decodedJson is Map && decodedJson.containsKey('rates')) {
        final List rates = decodedJson['rates'];
        return rates
            .map((e) => RateItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('[MarketService][getRatesForAll] error: $e');
      return [];
    }
  }

}
