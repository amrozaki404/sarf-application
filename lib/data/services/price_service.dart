import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/http/app_http_client.dart';
import '../models/price_models.dart';

class PriceService {
  static Future<PricesResponse?> getRates({
    String base = 'SDG',
    required List<String> targets,
  }) async {
    try {
      final String targetParams = targets.join(",");
      final url = '${AppConstants.baseUrl}${AppConstants.ratesEndpoint}'
          '?base=${Uri.encodeComponent(base)}&targets=${Uri.encodeComponent(targetParams)}';

      final response = await AppHttpClient.get(url);

      if (response.statusCode != 200) return null;

      final dynamic decodedJson = jsonDecode(response.body);
      if (decodedJson is List) {
        final rates = decodedJson
            .map((e) => RateItem.fromJson(e as Map<String, dynamic>))
            .toList();
        return PricesResponse(rates: rates);
      }
      if (decodedJson is Map<String, dynamic>) {
        return PricesResponse.fromJson(decodedJson);
      }

      return null;
    } catch (e) {
      debugPrint('[PriceService] error: $e');
      return null;
    }
  }
}
