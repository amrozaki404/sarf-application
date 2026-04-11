import 'dart:convert';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_models.dart';
import '../../core/constants/app_constants.dart';
import '../../core/http/app_http_client.dart';

class AuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Step 1: Request OTP ───────────────────────────────────────────────────

  static Future<GenericResponse> requestOtp(RequestOtpRequest request) async {
    try {
      final response = await AppHttpClient.post(
        '${AppConstants.baseUrl}${AppConstants.requestOtpEndpoint}',
        body: request.toJson(),
      );
      return GenericResponse.fromJson(AppHttpClient.decodeJsonMap(response));
    } catch (e) {
      debugPrint('requestOtp error: $e');
      return GenericResponse(
          responseCode: '-99',
          responseMessage: 'Connection failed. Check your internet.');
    }
  }

  // ── Step 2: Confirm OTP → registrationToken ───────────────────────────────

  static Future<ConfirmOtpResponse> confirmOtp(
      ConfirmOtpRequest request) async {
    try {
      final response = await AppHttpClient.post(
        '${AppConstants.baseUrl}${AppConstants.confirmOtpEndpoint}',
        body: request.toJson(),
      );
      return ConfirmOtpResponse.fromJson(AppHttpClient.decodeJsonMap(response));
    } catch (e) {
      debugPrint('confirmOtp error: $e');
      return ConfirmOtpResponse(
          responseCode: '-99',
          responseMessage: 'Connection failed. Check your internet.');
    }
  }

  // ── Step 3: Submit registration ───────────────────────────────────────────

  static Future<AuthResponse> submitRegistration(
      SubmitRegistrationRequest request) async {
    try {
      final deviceId = await AppHttpClient.getDeviceId();
      final deviceName = await _getDeviceName();
      final fcmToken = await _getFcmToken();
      final response = await AppHttpClient.post(
        '${AppConstants.baseUrl}${AppConstants.submitEndpoint}',
        body: request
            .copyWith(
              deviceId: deviceId,
              deviceName: deviceName,
              fcmToken: fcmToken,
            )
            .toJson(),
      );
      final json = AppHttpClient.decodeJsonMap(response);
      final authResponse = AuthResponse.fromJson(json);
      if (authResponse.responseCode == AppConstants.successCode &&
          authResponse.data != null) {
        await _saveSession(authResponse.data!);
      }
      return authResponse;
    } catch (e) {
      debugPrint('submitRegistration error: $e');
      return AuthResponse(
          responseCode: '-99',
          responseMessage: 'Connection failed. Check your internet.');
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  static Future<AuthResponse> login(LoginRequest request) async {
    try {
      final deviceId = await AppHttpClient.getDeviceId();
      final deviceName = await _getDeviceName();
      final fcmToken = await _getFcmToken();
      final response = await AppHttpClient.post(
        '${AppConstants.baseUrl}${AppConstants.loginEndpoint}',
        body: LoginRequest(
          countryCode: request.countryCode,
          phoneNumber: request.phoneNumber,
          password: request.password,
          deviceId: deviceId,
          deviceName: deviceName,
          fcmToken: fcmToken,
        ).toJson(),
      );
      final json = AppHttpClient.decodeJsonMap(response);
      final authResponse = AuthResponse.fromJson(json);
      if (authResponse.responseCode == AppConstants.successCode &&
          authResponse.data != null) {
        await _saveSession(authResponse.data!);
      }
      return authResponse;
    } catch (e) {
      debugPrint('login error: $e');
      return AuthResponse(
          responseCode: '-99',
          responseMessage: 'Connection failed. Check your internet.');
    }
  }

  // ── Google Auth ───────────────────────────────────────────────────────────

  static Future<AuthResponse> googleAuth(GoogleAuthRequest request) async {
    try {
      final deviceId = await AppHttpClient.getDeviceId();
      final deviceName = await _getDeviceName();
      final fcmToken = await _getFcmToken();
      final response = await AppHttpClient.post(
        '${AppConstants.baseUrl}${AppConstants.googleAuthEndpoint}',
        showValidationDialog: false,
        body: GoogleAuthRequest(
          idToken: request.idToken,
          dateOfBirth: request.dateOfBirth,
          gender: request.gender,
          email: request.email,
          countryCode: request.countryCode,
          phoneNumber: request.phoneNumber,
          deviceId: deviceId,
          deviceName: deviceName,
          fcmToken: fcmToken,
        ).toJson(),
      );
      final json = AppHttpClient.decodeJsonMap(response);
      final authResponse = AuthResponse.fromJson(json);
      if (authResponse.responseCode == AppConstants.successCode &&
          authResponse.data != null) {
        await _saveSession(authResponse.data!);
      }
      return authResponse;
    } catch (e) {
      debugPrint('googleAuth error: $e');
      return AuthResponse(
          responseCode: '-99',
          responseMessage: 'Connection failed. Check your internet.');
    }
  }

  // ── Session management ────────────────────────────────────────────────────

  static Future<void> _saveSession(AuthData user) async {
    await _storage.write(key: AppConstants.tokenKey, value: user.token);
    if (user.refreshToken != null) {
      await _storage.write(
          key: AppConstants.refreshTokenKey, value: user.refreshToken!);
    }
    await _storage.write(
        key: AppConstants.userKey, value: jsonEncode(user.toJson()));
  }

  static Future<String?> getToken() =>
      _storage.read(key: AppConstants.tokenKey);

  static Future<String?> getRefreshToken() =>
      _storage.read(key: AppConstants.refreshTokenKey);

  static Future<AuthData?> getUser() async {
    final raw = await _storage.read(key: AppConstants.userKey);
    if (raw == null) return null;
    return AuthData.fromJson(jsonDecode(raw));
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<String?> _getFcmToken() async {
    try {
      debugPrint('FCM token request started.');
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint(
        token == null
            ? 'FCM token request completed with null token.'
            : 'FCM token request completed successfully.',
      );
      return token;
    } catch (e) {
      debugPrint('getFcmToken skipped: $e');
      return null;
    }
  }

  static Future<String> _getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        return _firstNonEmpty([
              webInfo.platform,
              webInfo.userAgent,
              webInfo.appName,
              'Web Browser',
            ]) ??
            'Web Browser';
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final info = await deviceInfo.androidInfo;
          return _joinDeviceParts([info.manufacturer, info.model, info.device]);
        case TargetPlatform.iOS:
          final info = await deviceInfo.iosInfo;
          return _firstNonEmpty([info.name, info.model, info.localizedModel]) ??
              'iPhone';
        case TargetPlatform.macOS:
          final info = await deviceInfo.macOsInfo;
          return _firstNonEmpty(
                  [info.computerName, info.modelName, info.model]) ??
              'macOS';
        case TargetPlatform.windows:
          final info = await deviceInfo.windowsInfo;
          return _firstNonEmpty(
                [info.computerName, info.productName, info.deviceId],
              ) ??
              'Windows';
        case TargetPlatform.linux:
          final info = await deviceInfo.linuxInfo;
          return _firstNonEmpty([info.prettyName, info.name, info.variant]) ??
              'Linux';
        case TargetPlatform.fuchsia:
          return 'Fuchsia';
      }
    } catch (e) {
      debugPrint('getDeviceName fallback: $e');
    }

    return kIsWeb ? 'Web Browser' : Platform.operatingSystem;
  }

  static String _joinDeviceParts(List<String?> parts) {
    final values = parts
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    if (values.isEmpty) {
      return 'Android';
    }

    final uniqueValues = <String>[];
    for (final value in values) {
      if (!uniqueValues.any(
        (existing) => existing.toLowerCase() == value.toLowerCase(),
      )) {
        uniqueValues.add(value);
      }
    }

    return uniqueValues.join(' ');
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }
}
