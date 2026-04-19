import '../../core/constants/app_constants.dart';
import '../../core/http/app_http_client.dart';
import '../models/digital_subscription_models.dart';

class DigitalSubscriptionService {
  // ── List ──────────────────────────────────────────────────────────────────

  static Future<List<DigitalSubscription>> getSubscriptions({
    String? category,
  }) async {
    final base = '${AppConstants.baseUrl}${AppConstants.digitalSubsEndpoint}';
    final uri = Uri.parse(base).replace(
      queryParameters: (category != null &&
              category.isNotEmpty &&
              category != 'all')
          ? {'category': category}
          : null,
    );

    final response = await AppHttpClient.get(uri.toString());
    final json = AppHttpClient.decodeJsonMap(response);

    if (json['responseCode'] == AppConstants.successCode) {
      return (json['data'] as List)
          .map((e) => DigitalSubscription.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── Single ────────────────────────────────────────────────────────────────

  static Future<DigitalSubscription?> getSubscription(String id) async {
    final url =
        '${AppConstants.baseUrl}${AppConstants.digitalSubsEndpoint}/$id';
    final response = await AppHttpClient.get(url);
    final json = AppHttpClient.decodeJsonMap(response);

    if (json['responseCode'] == AppConstants.successCode) {
      return DigitalSubscription.fromJson(
          json['data'] as Map<String, dynamic>);
    }
    return null;
  }

  // ── Create order ──────────────────────────────────────────────────────────

  static Future<bool> createOrder({
    required String subscriptionId,
    required String planId,
    Map<String, String> fieldValues = const {},
  }) async {
    final url =
        '${AppConstants.baseUrl}${AppConstants.digitalSubOrdersEndpoint}';
    final body = <String, dynamic>{
      'subscriptionId': subscriptionId,
      'planId': planId,
      if (fieldValues.isNotEmpty) 'fieldValues': fieldValues,
    };

    final response = await AppHttpClient.post(url, body: body);
    final json = AppHttpClient.decodeJsonMap(response);

    final code = json['responseCode'] as String?;
    return code == AppConstants.successCode ||
        code == AppConstants.digitalSubOrderCreatedCode;
  }

  // ── Get reviews ──────────────────────────────────────────────────────────

  static Future<List<SubReview>> getReviews(String subscriptionId) async {
    final url =
        '${AppConstants.baseUrl}${AppConstants.digitalSubsEndpoint}/$subscriptionId/reviews';
    final response = await AppHttpClient.get(url);
    final json = AppHttpClient.decodeJsonMap(response);

    if (json['responseCode'] == AppConstants.successCode) {
      return (json['data'] as List)
          .map((e) => SubReview.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── Submit review ─────────────────────────────────────────────────────────

  static Future<bool> submitReview({
    required String subscriptionId,
    required int rating,
    String? comment,
  }) async {
    final url =
        '${AppConstants.baseUrl}${AppConstants.digitalSubsEndpoint}/$subscriptionId/reviews';
    final body = <String, dynamic>{
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    };

    final response = await AppHttpClient.post(url, body: body);
    final json = AppHttpClient.decodeJsonMap(response);

    final code = json['responseCode'] as String?;
    return code == AppConstants.successCode ||
        code == AppConstants.digitalSubReviewCreatedCode;
  }
}
