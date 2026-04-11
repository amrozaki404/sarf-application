import '../../core/constants/app_constants.dart';
import '../../core/http/app_http_client.dart';
import '../models/like_card_models.dart';

class LikeCardService {
  // ── Categories ─────────────────────────────────────────────────────────────

  static Future<List<LikeCardCategory>> getCategories() async {
    final url =
        '${AppConstants.baseUrl}${AppConstants.giftCardCategoriesEndpoint}';
    final response = await AppHttpClient.get(url);
    final json = AppHttpClient.decodeJsonMap(response);

    if (json['responseCode'] == AppConstants.successCode) {
      return (json['data'] as List)
          .map((e) => LikeCardCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── Products by category ──────────────────────────────────────────────────

  static Future<List<LikeCardProduct>> getProductsByCategory(
      String categoryId) async {
    final url =
        '${AppConstants.baseUrl}${AppConstants.giftCardCategoriesEndpoint}/$categoryId/products';
    final response = await AppHttpClient.get(url);
    final json = AppHttpClient.decodeJsonMap(response);

    if (json['responseCode'] == AppConstants.successCode) {
      return (json['data'] as List)
          .map((e) => LikeCardProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── All products (with optional search) ───────────────────────────────────

  static Future<List<LikeCardProduct>> searchProducts(String query) async {
    final uri = Uri.parse(
            '${AppConstants.baseUrl}${AppConstants.giftCardProductsEndpoint}')
        .replace(queryParameters: query.isEmpty ? null : {'q': query});

    final response = await AppHttpClient.get(uri.toString());
    final json = AppHttpClient.decodeJsonMap(response);

    if (json['responseCode'] == AppConstants.successCode) {
      return (json['data'] as List)
          .map((e) => LikeCardProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── Popular products ──────────────────────────────────────────────────────

  static Future<List<LikeCardProduct>> getPopularProducts() async {
    final url =
        '${AppConstants.baseUrl}${AppConstants.giftCardProductsEndpoint}/popular';
    final response = await AppHttpClient.get(url);
    final json = AppHttpClient.decodeJsonMap(response);

    if (json['responseCode'] == AppConstants.successCode) {
      return (json['data'] as List)
          .map((e) => LikeCardProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── Single product (with denominations) ───────────────────────────────────

  static Future<LikeCardProduct?> getProduct(String productId) async {
    final url =
        '${AppConstants.baseUrl}${AppConstants.giftCardProductsEndpoint}/$productId';
    final response = await AppHttpClient.get(url);
    final json = AppHttpClient.decodeJsonMap(response);

    if (json['responseCode'] == AppConstants.successCode) {
      return LikeCardProduct.fromJson(json['data'] as Map<String, dynamic>);
    }
    return null;
  }

  // ── Create order ──────────────────────────────────────────────────────────

  static Future<LikeCardOrder?> createOrder({
    required String productId,
    required String denominationId,
    String? recipient,
  }) async {
    final url =
        '${AppConstants.baseUrl}${AppConstants.giftCardOrdersEndpoint}';
    final body = <String, dynamic>{
      'productId': productId,
      'denominationId': denominationId,
      if (recipient != null && recipient.isNotEmpty) 'recipient': recipient,
    };

    final response = await AppHttpClient.post(url, body: body);
    final json = AppHttpClient.decodeJsonMap(response);

    if (json['responseCode'] == AppConstants.successCode ||
        json['responseCode'] == AppConstants.giftCardOrderCreatedCode) {
      return LikeCardOrder.fromJson(json['data'] as Map<String, dynamic>);
    }
    return null;
  }
}
