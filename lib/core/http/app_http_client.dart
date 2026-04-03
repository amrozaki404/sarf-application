import 'dart:convert';
import 'dart:math';
import 'package:alice/alice.dart';
import 'package:alice/model/alice_configuration.dart';
import 'package:alice/model/alice_http_call.dart';
import 'package:alice/model/alice_http_request.dart';
import 'package:alice/model/alice_http_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../localization/locale_service.dart';
import '../services/navigation_service.dart';

class AppHttpClient {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _deviceIdKey = 'app_device_id';
  static const _deviceIdChannel = MethodChannel('com.sarf.app/device_id');
  static final _client = http.Client();

  // ── Alice inspector (debug only) ─────────────────────────────────────────
  // Shake device to open, or call AppHttpClient.alice.showInspector()

  static final alice = kDebugMode
      ? Alice(
          configuration: AliceConfiguration(
            navigatorKey: NavigationService.navigatorKey,
            showNotification: true,
            showInspectorOnShake: true,
          ),
        )
      : null;

  static int _callId = 0;

  // ── Device ID ────────────────────────────────────────────────────────────

  static String? _cachedDeviceId;

  static Future<String> _getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    final prefs = await SharedPreferences.getInstance();
    var id = await _getPlatformDeviceId();
    id ??= prefs.getString(_deviceIdKey);
    if (id == null || id.isEmpty) {
      id = _generateId();
    }
    await prefs.setString(_deviceIdKey, id);
    _cachedDeviceId = id;
    return id;
  }

  static Future<String> getDeviceId() => _getDeviceId();

  static String _generateId() {
    final rand = Random.secure();
    return List.generate(32, (_) => rand.nextInt(16).toRadixString(16)).join();
  }

  static Future<String?> _getPlatformDeviceId() async {
    if (kIsWeb) return null;

    try {
      final id = await _deviceIdChannel.invokeMethod<String>('getDeviceId');
      final trimmed = id?.trim();
      if (trimmed == null || trimmed.isEmpty) return null;
      return trimmed;
    } on MissingPluginException {
      return null;
    } catch (e) {
      debugPrint('[AppHttpClient] platform device ID fallback: $e');
      return null;
    }
  }

  // ── Headers ──────────────────────────────────────────────────────────────

  static Future<Map<String, String>> _buildHeaders() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Device-Id': await _getDeviceId(),
      'language': LocaleService.locale.languageCode,
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ── Alice logging ─────────────────────────────────────────────────────────

  static void _logToAlice({
    required String method,
    required String url,
    required Map<String, String> headers,
    required Map<String, dynamic>? body,
    required http.Response response,
    required int durationMs,
  }) {
    if (alice == null) return;
    final uri = Uri.parse(url);
    final call = AliceHttpCall(_callId++)
      ..method = method
      ..endpoint = uri.path.isEmpty ? '/' : uri.path
      ..server = uri.host
      ..uri = url
      ..secure = uri.scheme == 'https'
      ..loading = false
      ..duration = durationMs;

    final req = AliceHttpRequest()
      ..headers = headers
      ..body = body ?? {}
      ..contentType = headers['Content-Type'] ?? ''
      ..size = (jsonEncode(body ?? {})).length
      ..queryParameters = uri.queryParameters;

    dynamic responseBody;
    try {
      responseBody = jsonDecode(response.body);
    } catch (_) {
      responseBody = response.body;
    }

    final res = AliceHttpResponse()
      ..status = response.statusCode
      ..body = responseBody
      ..headers = response.headers
      ..size = response.bodyBytes.length
      ..time = DateTime.now();

    call.request = req;
    call.response = res;
    alice!.addHttpCall(call);
  }

  // ── Request ───────────────────────────────────────────────────────────────

  static Future<http.Response> post(
    String url, {
    Map<String, dynamic>? body,
    bool showValidationDialog = true,
  }) async {
    try {
      final headers = await _buildHeaders();
      final start = DateTime.now();
      final response = await _client
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body ?? {}),
          )
          .timeout(const Duration(seconds: 15));

      _logToAlice(
        method: 'POST',
        url: url,
        headers: headers,
        body: body,
        response: response,
        durationMs: DateTime.now().difference(start).inMilliseconds,
      );
      await _intercept(response, showValidationDialog: showValidationDialog);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> get(String url) async {
    try {
      final headers = await _buildHeaders();
      final start = DateTime.now();
      final response = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      _logToAlice(
        method: 'GET',
        url: url,
        headers: headers,
        body: null,
        response: response,
        durationMs: DateTime.now().difference(start).inMilliseconds,
      );
      await _intercept(response);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.MultipartRequest> multipart(Uri uri) async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    return http.MultipartRequest('POST', uri)
      ..headers.addAll({
        'Accept': 'application/json',
        'X-Device-Id': await _getDeviceId(),
        'language': LocaleService.locale.languageCode,
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      });
  }

  // ── Global response interceptor ───────────────────────────────────────────

  static Future<void> _intercept(
    http.Response response, {
    bool showValidationDialog = true,
  }) async {
    if (response.statusCode == 401) {
      // Only redirect to login if the user had an active session
      final token = await _storage.read(key: AppConstants.tokenKey);
      if (token != null && token.isNotEmpty) {
        debugPrint('[AppHttpClient] 401 on authenticated request → logout');
        await _storage.delete(key: AppConstants.tokenKey);
        await _storage.delete(key: AppConstants.userKey);
        NavigationService.goToLogin();
      }
    } else if (response.statusCode == 422 && showValidationDialog) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final message = json['responseMessage']?.toString() ?? 'Invalid input';
        debugPrint('[AppHttpClient] 422 → dialog: $message');
        await NavigationService.showErrorDialog(message);
      } catch (_) {}
    }
  }
}
