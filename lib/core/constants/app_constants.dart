class AppConstants {
  // Local dev — physical device must use the host machine's LAN IP
  static const String baseUrl = 'http://10.102.228.98:4500';
  static const String appVersion = '1.0.0';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String loginEndpoint = '/api/auth/login';
  static const String googleAuthEndpoint = '/api/auth/google';

  // ── Registration ──────────────────────────────────────────────────────────
  static const String requestOtpEndpoint = '/api/registration/request-otp';
  static const String confirmOtpEndpoint = '/api/registration/confirm-otp';
  static const String submitEndpoint = '/api/registration/submit';

  // ── Home ──────────────────────────────────────────────────────────────────
  static const String servicesEndpoint = '/api/home/services';
  static const String notificationsEndpoint = '/api/home/notifications';
  static const String notificationCountEndpoint =
      '/api/home/notifications/count';
  static const String transactionsEndpoint = '/api/home/transactions';
  // mark as read: PATCH $notificationsEndpoint/{id}/read

  // ── International Transfer ────────────────────────────────────────────────
  static const String exchangesEndpoint = '/api/international/exchanges';
  // providers:       GET $exchangesEndpoint/{code}/providers
  // currencies:      GET $exchangesEndpoint/{code}/currencies
  // receive-methods: GET $exchangesEndpoint/{code}/receive-methods
  static const String intlRatesEndpoint = '/api/international/rates';
  static const String intlOrdersEndpoint = '/api/international/orders';
  // attachments:  POST $intlOrdersEndpoint/{uuid}/attachments

  // ── Gift Card ─────────────────────────────────────────────────────────────
  static const String giftCardCategoriesEndpoint = '/api/giftcard/categories';
  // products by category: GET $giftCardCategoriesEndpoint/{categoryId}/products
  static const String giftCardProductsEndpoint = '/api/giftcard/products';
  // popular: GET $giftCardProductsEndpoint/popular
  // single:  GET $giftCardProductsEndpoint/{productId}
  static const String giftCardOrdersEndpoint = '/api/giftcard/orders';

  // ── Auth token refresh ────────────────────────────────────────────────────
  static const String refreshTokenEndpoint = '/api/auth/refresh';

  // ── Storage keys ──────────────────────────────────────────────────────────
  static const String tokenKey = 'jwt_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String biometricEnabledKey = 'biometric_enabled';

  // ── Response codes ────────────────────────────────────────────────────────
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
  static const String exchangeNotFoundCode = '11';
  static const String rateNotFoundCode = '12';
  static const String orderCreatedCode = '13';
  static const String orderNotFoundCode = '14';
  static const String notificationNotFoundCode = '17';
  static const String giftCardCategoryNotFoundCode = '20';
  static const String giftCardProductNotFoundCode = '21';
  static const String giftCardDenominationNotFoundCode = '22';
  static const String giftCardOrderCreatedCode = '23';
  static const String giftCardOrderNotFoundCode = '24';
}
