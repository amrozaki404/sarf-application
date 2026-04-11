// ── Request Models ───────────────────────────────────────────────────────────

class LoginRequest {
  final String countryCode;
  final String phoneNumber;
  final String password;
  final String? deviceId;
  final String? deviceName;
  final String? fcmToken;

  LoginRequest({
    required this.countryCode,
    required this.phoneNumber,
    required this.password,
    this.deviceId,
    this.deviceName,
    this.fcmToken,
  });

  Map<String, dynamic> toJson() => {
        'countryCode': countryCode,
        'phoneNumber': phoneNumber,
        'password': password,
        if (deviceId != null) 'deviceId': deviceId,
        if (deviceName != null) 'deviceName': deviceName,
        if (fcmToken != null) 'fcmToken': fcmToken,
      };
}

class RequestOtpRequest {
  final String countryCode;
  final String phoneNumber;

  RequestOtpRequest({required this.countryCode, required this.phoneNumber});

  Map<String, dynamic> toJson() => {
        'countryCode': countryCode,
        'phoneNumber': phoneNumber,
      };
}

class ConfirmOtpRequest {
  final String countryCode;
  final String phoneNumber;
  final String otpCode;

  ConfirmOtpRequest({
    required this.countryCode,
    required this.phoneNumber,
    required this.otpCode,
  });

  Map<String, dynamic> toJson() => {
        'countryCode': countryCode,
        'phoneNumber': phoneNumber,
        'otpCode': otpCode,
      };
}

class SubmitRegistrationRequest {
  final String registrationToken;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String gender; // MALE or FEMALE
  final String? email;
  final String password;
  final String? deviceId;
  final String? deviceName;
  final String? fcmToken;

  SubmitRegistrationRequest({
    required this.registrationToken,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    this.email,
    required this.password,
    this.deviceId,
    this.deviceName,
    this.fcmToken,
  });

  SubmitRegistrationRequest copyWith({
    String? email,
    String? deviceId,
    String? deviceName,
    String? fcmToken,
  }) =>
      SubmitRegistrationRequest(
        registrationToken: registrationToken,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        gender: gender,
        email: email ?? this.email,
        password: password,
        deviceId: deviceId ?? this.deviceId,
        deviceName: deviceName ?? this.deviceName,
        fcmToken: fcmToken ?? this.fcmToken,
      );

  Map<String, dynamic> toJson() => {
        'registrationToken': registrationToken,
        'firstName': firstName,
        'lastName': lastName,
        'dateOfBirth': '${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}',
        'gender': gender,
        if (email != null) 'email': email,
        'password': password,
        if (deviceId != null) 'deviceId': deviceId,
        if (deviceName != null) 'deviceName': deviceName,
        if (fcmToken != null) 'fcmToken': fcmToken,
      };
}

class GoogleAuthRequest {
  final String idToken;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? email;
  final String? countryCode;
  final String? phoneNumber;
  final String? deviceId;
  final String? deviceName;
  final String? fcmToken;

  GoogleAuthRequest({
    required this.idToken,
    this.dateOfBirth,
    this.gender,
    this.email,
    this.countryCode,
    this.phoneNumber,
    this.deviceId,
    this.deviceName,
    this.fcmToken,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'idToken': idToken,
    };
    if (dateOfBirth != null) {
      map['dateOfBirth'] =
          '${dateOfBirth!.year.toString().padLeft(4, '0')}-${dateOfBirth!.month.toString().padLeft(2, '0')}-${dateOfBirth!.day.toString().padLeft(2, '0')}';
    }
    if (gender != null) map['gender'] = gender;
    if (email != null) map['email'] = email;
    if (countryCode != null) map['countryCode'] = countryCode;
    if (phoneNumber != null) map['phoneNumber'] = phoneNumber;
    if (deviceId != null) map['deviceId'] = deviceId;
    if (deviceName != null) map['deviceName'] = deviceName;
    if (fcmToken != null) map['fcmToken'] = fcmToken;
    return map;
  }
}

// ── Response Models ───────────────────────────────────────────────────────────

class GenericResponse {
  final String responseCode;
  final String responseMessage;

  GenericResponse({required this.responseCode, required this.responseMessage});

  bool get isSuccess => responseCode == '0' || responseCode == '1';

  factory GenericResponse.fromJson(Map<String, dynamic> json) => GenericResponse(
        responseCode: json['responseCode']?.toString() ?? '-1',
        responseMessage: json['responseMessage']?.toString() ?? 'Unknown error',
      );
}

class ConfirmOtpResponse extends GenericResponse {
  final String? registrationToken;

  ConfirmOtpResponse({
    required super.responseCode,
    required super.responseMessage,
    this.registrationToken,
  });

  factory ConfirmOtpResponse.fromJson(Map<String, dynamic> json) =>
      ConfirmOtpResponse(
        responseCode: json['responseCode']?.toString() ?? '-1',
        responseMessage: json['responseMessage']?.toString() ?? 'Unknown error',
        registrationToken: json['data']?['registrationToken'],
      );
}

class AuthData {
  final String token;
  final String? refreshToken;
  final String accountNumber;
  final String firstName;
  final String lastName;
  final String? countryCode;
  final String? phoneNumber;
  final String registrationType;

  AuthData({
    required this.token,
    this.refreshToken,
    required this.accountNumber,
    required this.firstName,
    required this.lastName,
    this.countryCode,
    this.phoneNumber,
    required this.registrationType,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) => AuthData(
        token: json['token'] ?? '',
        refreshToken: json['refreshToken'],
        accountNumber: json['accountNumber'] ?? '',
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
        countryCode: json['countryCode'],
        phoneNumber: json['phoneNumber'],
        registrationType: json['registrationType'] ?? 'PHONE',
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        if (refreshToken != null) 'refreshToken': refreshToken,
        'accountNumber': accountNumber,
        'firstName': firstName,
        'lastName': lastName,
        'countryCode': countryCode,
        'phoneNumber': phoneNumber,
        'registrationType': registrationType,
      };

  String get fullName => '$firstName $lastName';
}

class AuthResponse extends GenericResponse {
  final AuthData? data;

  AuthResponse({
    required super.responseCode,
    required super.responseMessage,
    this.data,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        responseCode: json['responseCode']?.toString() ?? '-1',
        responseMessage: json['responseMessage']?.toString() ?? 'Unknown error',
        data: json['data'] != null ? AuthData.fromJson(json['data']) : null,
      );
}
