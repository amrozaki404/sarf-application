class AppConstants {
  static const String baseUrl = 'https://sdg-exchange-backend.fg-tech.net';
  static const String appVersion = '1.0.0';

  // Auth endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String googleAuthEndpoint = '/api/auth/google';

  // Registration
  static const String requestOtpEndpoint = '/api/registration/request-otp';
  static const String confirmOtpEndpoint = '/api/registration/confirm-otp';
  static const String submitEndpoint = '/api/registration/submit';

  // Market endpoints
  static const String currenciesEndpoint = '/api/price/currencies/v1';
  static const String ratesEndpoint = '/api/price/market/v1/rates';
  static const String ratesAllEndpoint = '/api/price/market/v1/rates';

  // P2P endpoints
  static const String p2pMethodsEndpoint = '/api/p2p/v1/methods';
  static const String p2pQuoteEndpoint = '/api/p2p/v1/quote';
  static const String p2pOrdersEndpoint = '/api/p2p/v1/orders';
  static const String p2pActiveOrderEndpoint = '/api/p2p/v1/orders/active';

  // Storage
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'user_data';
  static const String selectedBaseKey = 'selected_base_currency';

  // Response codes
  static const String successCode = '0';
  static const String otpSentCode = '1';
  static const String phoneExistsCode = '2';
  static const String invalidOtpCode = '3';
  static const String otpExpiredCode = '4';
  static const String noPendingRegistrationCode = '5';
  static const String invalidCredentialsCode = '6';
  static const String googleAuthFailedCode = '7';
  static const String googleExistsCode = '8';
  static const String registrationTokenInvalidCode = '9';
}
