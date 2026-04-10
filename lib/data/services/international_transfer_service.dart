import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../core/http/app_http_client.dart';
import '../models/international_transfer_models.dart';

class InternationalTransferService {
  // ── Exchanges ──────────────────────────────────────────────────────────────

  static Future<List<ExchangeOption>> getExchanges() async {
    final url = '${AppConstants.baseUrl}${AppConstants.exchangesEndpoint}';
    final response = await AppHttpClient.get(url);
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (json['responseCode'] == AppConstants.successCode) {
      return (json['data'] as List)
          .map((e) => ExchangeOption.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── Providers for an exchange ──────────────────────────────────────────────

  static Future<List<ProviderOption>> getProviders(String exchangeCode) async {
    final url =
        '${AppConstants.baseUrl}${AppConstants.exchangesEndpoint}/$exchangeCode/providers';
    final response = await AppHttpClient.get(url);
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (json['responseCode'] == AppConstants.successCode) {
      return (json['data'] as List)
          .map((e) => ProviderOption.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── Rate ──────────────────────────────────────────────────────────────────

  static Future<RateInfo?> getRate({
    required String exchangeCode,
    required String sendCurrency,
    String receiveCurrency = 'SDG',
    double? sendAmount,
  }) async {
    final params = {
      'exchangeCode': exchangeCode,
      'sendCurrency': sendCurrency,
      'receiveCurrency': receiveCurrency,
      if (sendAmount != null) 'sendAmount': sendAmount.toString(),
    };
    final uri = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.intlRatesEndpoint}').replace(
      queryParameters: params,
    );

    final response = await AppHttpClient.get(uri.toString());
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (json['responseCode'] == AppConstants.successCode) {
      return RateInfo.fromJson(json['data'] as Map<String, dynamic>);
    }
    return null;
  }

  // ── Create order (with optional KYC file in same request) ────────────────

  static Future<IntlOrder?> createOrder(
    IntlOrderRequest request, {
    File? file,
  }) async {
    final uri = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.intlOrdersEndpoint}');

    final multipart = await AppHttpClient.multipart(uri);

    // Order fields
    multipart.fields.addAll({
      'exchangeCode': request.exchangeCode,
      'providerCode': request.providerCode,
      if (request.providerReference != null)
        'providerReference': request.providerReference!,
      'sendCurrencyCode': request.sendCurrencyCode,
      'sendAmount': request.sendAmount.toString(),
      'senderName': request.senderName,
      'receiverName': request.receiverName,
      'receiveMethodCode': request.receiveMethodCode,
      'destinationAccountNumber': request.destinationAccountNumber,
      'destinationAccountHolder': request.destinationAccountHolder,
    });

    // Optional KYC file
    if (file != null) {
      multipart.files.add(await http.MultipartFile.fromPath('file', file.path));
    }

    final streamed = await multipart.send();
    final response = await http.Response.fromStream(streamed);
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (json['responseCode'] == AppConstants.successCode ||
        json['responseCode'] == AppConstants.orderCreatedCode) {
      return IntlOrder.fromJson(json['data'] as Map<String, dynamic>);
    }
    return null;
  }

  // ── Order history ─────────────────────────────────────────────────────────

  static Future<List<IntlOrder>> getOrders() async {
    final url =
        '${AppConstants.baseUrl}${AppConstants.intlOrdersEndpoint}';
    final response = await AppHttpClient.get(url);
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (json['responseCode'] == AppConstants.successCode) {
      return (json['data'] as List)
          .map((e) => IntlOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── Currencies available for an exchange ──────────────────────────────────

  static Future<List<CurrencyOption>> getCurrencies(String exchangeCode) async {
    final url =
        '${AppConstants.baseUrl}${AppConstants.exchangesEndpoint}/$exchangeCode/currencies';
    final response = await AppHttpClient.get(url);
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (json['responseCode'] == AppConstants.successCode) {
      return (json['data'] as List)
          .map((e) => CurrencyOption.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── Receive methods for an exchange ───────────────────────────────────────

  static Future<List<ReceiveMethodOption>> getReceiveMethods(
      String exchangeCode) async {
    final url =
        '${AppConstants.baseUrl}${AppConstants.exchangesEndpoint}/$exchangeCode/receive-methods';
    final response = await AppHttpClient.get(url);
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (json['responseCode'] == AppConstants.successCode) {
      return (json['data'] as List)
          .map((e) => ReceiveMethodOption.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── Transfer services (home catalog) ─────────────────────────────────────

  static Future<List<TransferService>> getServices() async {
    final url = '${AppConstants.baseUrl}${AppConstants.servicesEndpoint}';
    final response = await AppHttpClient.get(url);
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (json['responseCode'] == AppConstants.successCode) {
      return (json['data'] as List)
          .map((e) => TransferService.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
