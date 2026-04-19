import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/auth_models.dart';
import '../../data/services/auth_service.dart';
import '../../core/constants/app_constants.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/app_strings.dart';
import '../../core/localization/locale_service.dart';
import 'register_page.dart';
import 'widgets/gradient_button.dart';
import 'widgets/auth_input.dart';
import 'widgets/country_code_picker.dart';
import '../pages/main_shell_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _countryCodeCtrl = TextEditingController(text: '249');
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '420777617459-17g6ee7fgh72ce0ao6ifkf2bq26ce7c5.apps.googleusercontent.com',
  );

  @override
  void dispose() {
    _countryCodeCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await AuthService.login(LoginRequest(
      countryCode: _countryCodeCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      password: _passwordCtrl.text,
    ));

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.responseCode == AppConstants.successCode &&
        response.data != null) {
      _navigateToHome(response.data!);
    } else {
      setState(() => _errorMessage = response.responseMessage);
    }
  }

  Future<void> _googleLogin() async {
    if (!_googleSignInSupported) {
      setState(() => _errorMessage = 'Google sign-in is not supported here.');
      return;
    }

    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });
    try {
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) {
        setState(() => _isGoogleLoading = false);
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        setState(() {
          _isGoogleLoading = false;
          _errorMessage = 'Google sign-in failed.';
        });
        return;
      }
      final initialResponse = await AuthService.googleAuth(
        GoogleAuthRequest(
          idToken: idToken,
          email: account.email,
        ),
      );
      if (!mounted) return;

      if (initialResponse.responseCode == AppConstants.successCode &&
          initialResponse.data != null) {
        setState(() => _isGoogleLoading = false);
        _navigateToHome(initialResponse.data!);
        return;
      }

      if (_requiresGoogleSignupDetails(initialResponse)) {
        final googleDetails = await _collectGoogleDetails(account.email);
        if (googleDetails == null) {
          setState(() => _isGoogleLoading = false);
          return;
        }

        final response = await AuthService.googleAuth(
          GoogleAuthRequest(
            idToken: idToken,
            dateOfBirth: googleDetails.dateOfBirth,
            gender: googleDetails.gender,
            email: googleDetails.email,
            countryCode: googleDetails.countryCode,
            phoneNumber: googleDetails.phoneNumber,
          ),
        );
        if (!mounted) return;
        setState(() => _isGoogleLoading = false);
        if (response.responseCode == AppConstants.successCode &&
            response.data != null) {
          _navigateToHome(response.data!);
        } else {
          setState(() => _errorMessage = response.responseMessage);
        }
        return;
      }

      if (!mounted) return;
      setState(() => _isGoogleLoading = false);
      setState(() => _errorMessage = initialResponse.responseMessage);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGoogleLoading = false;
        _errorMessage = 'Google sign-in failed.';
      });
    }
  }

  Future<void> _navigateToHome(AuthData user) async {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const MainShellPage(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (_) => false,
    );
  }

  Future<_GoogleSignupDetails?> _collectGoogleDetails(String? email) async {
    return showModalBottomSheet<_GoogleSignupDetails>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GoogleSignupSheet(initialEmail: email),
    );
  }

  bool _requiresGoogleSignupDetails(AuthResponse response) {
    if (response.responseCode == AppConstants.googleExistsCode) return true;

    final message = response.responseMessage.toLowerCase();
    return message.contains('date of birth') ||
        message.contains('gender') ||
        response.responseMessage.contains('تاريخ الميلاد') ||
        response.responseMessage.contains('الجنس');
  }

  void _openRegisterPage() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const RegisterPage(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: anim,
              curve: Curves.easeOut,
            ),
          ),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _toggleLanguage() async {
    await LocaleService.toggle();
    if (!mounted) return;
    await context.setLocale(LocaleService.locale);
  }

  @override
  Widget build(BuildContext context) {
    final ui.TextDirection textDirection =
        _isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr;

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.localeNotifier,
      builder: (context, _, __) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Directionality(
          textDirection: textDirection,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                _buildHeaderBackground(),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                    child: Column(
                      children: [
                        _buildHeaderActions(),
                        const SizedBox(height: 48),
                        _buildBrandLockup(),
                        const SizedBox(height: 90),
                        _buildLoginPanel(),
                        const SizedBox(height: 14),
                        _buildVersionLabel(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBackground() {
    return Container(
      height: 350,
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(
        ),
      ),
    );
  }

  Widget _buildBrandLockup() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/app_icon.png', width: 70, height: 70),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isArabic ? 'صرف' : 'Sarf',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isArabic ? 'Sarf' : 'Pay instantly',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.86),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _TopActionButton(
          label: _isArabic ? 'الدعم' : 'Support',
          icon: Icons.headset_mic_outlined,
          onTap: _showSupportInfo,
        ),
        _LanguageButton(
          isArabic: _isArabic,
          onTap: _toggleLanguage,
        ),
      ],
    );
  }

  Widget _buildLoginPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment:
              _isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Row(
                children: [
                  CountryCodePicker(controller: _countryCodeCtrl),
                  const SizedBox(width: 10),
                  Expanded(child: _buildPhoneField()),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildPasswordField(),
            const SizedBox(height: 12),
            Row(
              textDirection:
                  _isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _openRegisterPage,
                  child: Text(
                    _isArabic ? 'إنشاء حساب جديد' : 'Create new account',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _showForgotPasswordInfo,
                  child: Text(
                    _isArabic ? 'نسيت كلمة المرور؟' : 'Forgot password?',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              _buildError(_errorMessage!),
            ],
            const SizedBox(height: 24),
            GradientButton(
              label: S.signIn,
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _login,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: _buildGoogleButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionLabel() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Center(
          child: Text(
            _isArabic
                ? 'الإصدار ${AppConstants.appVersion}'
                : 'Version ${AppConstants.appVersion}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneCtrl,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(12),
      ],
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      decoration: _inputDecoration(
        hint: 'XXX-XXX-XXX',
      ),
      validator: (value) {
        if (value == null || value.trim().length < 5) {
          return S.enterValidNumber;
        }
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordCtrl,
      obscureText: _obscurePassword,
      textAlign: _isArabic ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      decoration: _inputDecoration(
        hint: _isArabic ? 'كلمة المرور' : 'Password',
        suffixIcon: IconButton(
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
      validator: (value) => value == null || value.isEmpty
          ? S.enterValidPassword
          : null,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _login(),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: const Color(0xFFF1F3F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1.3),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildGoogleButton() {
    final isEnabled = _googleSignInSupported && !_isLoading;

    return OutlinedButton(
      onPressed: isEnabled ? _googleLogin : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: BorderSide(
          color: _googleSignInSupported
              ? AppColors.primary.withOpacity(0.35)
              : AppColors.inputBorder,
          width: 1.2,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: _isGoogleLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.primary,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'G',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _isArabic ? 'تسجيل الدخول عبر Google' : 'Continue with Google',
                  style: TextStyle(
                    color: _googleSignInSupported
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).shakeX();
  }

  void _showForgotPasswordInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isArabic
              ? 'استعادة كلمة المرور غير متاحة حالياً.'
              : 'Password recovery is not available yet.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSupportInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isArabic
              ? 'سيتم ربط صفحة الدعم قريباً.'
              : 'Support page will be connected soon.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool get _isArabic => LocaleService.locale.languageCode == 'ar';

  bool get _googleSignInSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

class _TopActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _TopActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'EN',
                style: TextStyle(
                  color: isArabic
                      ? Colors.white.withOpacity(0.72)
                      : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '/',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'AR',
                style: TextStyle(
                  color: isArabic
                      ? Colors.white
                      : Colors.white.withOpacity(0.72),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _GoogleSignupDetails {
  final DateTime dateOfBirth;
  final String gender;
  final String? email;
  final String countryCode;
  final String phoneNumber;

  const _GoogleSignupDetails({
    required this.dateOfBirth,
    required this.gender,
    this.email,
    required this.countryCode,
    required this.phoneNumber,
  });
}

class _GoogleSignupSheet extends StatefulWidget {
  final String? initialEmail;

  const _GoogleSignupSheet({this.initialEmail});

  @override
  State<_GoogleSignupSheet> createState() => _GoogleSignupSheetState();
}

class _GoogleSignupSheetState extends State<_GoogleSignupSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  late final TextEditingController _countryCodeCtrl;
  late final TextEditingController _phoneCtrl;

  String _selectedGender = 'MALE';
  DateTime? _selectedDob;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail ?? '');
    _countryCodeCtrl = TextEditingController(text: '249');
    _phoneCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _countryCodeCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 18),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDob = picked;
        _errorMessage = null;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDob == null) {
      setState(() => _errorMessage = S.selectDateOfBirth);
      return;
    }
    Navigator.of(context).pop(
      _GoogleSignupDetails(
        dateOfBirth: _selectedDob!,
        gender: _selectedGender,
        email: _normalizedEmail(_emailCtrl.text),
        countryCode: _countryCodeCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.completeGoogleProfile,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    S.completeGoogleProfileDesc,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  AuthInput(
                    label: S.email,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.alternate_email_rounded,
                    enabled: false,
                    readOnly: true,
                    validator: (value) {
                      final normalized = _normalizedEmail(value);
                      if (normalized == null) return S.enterValidEmail;
                      return _isValidEmail(normalized)
                          ? null
                          : S.enterValidEmail;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _GoogleCountryPicker(controller: _countryCodeCtrl),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AuthInput(
                          label: S.phoneNumber,
                          hint: '9X XXX XXXX',
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(12),
                          ],
                          prefixIcon: Icons.phone_outlined,
                          validator: (value) {
                            if (value == null || value.trim().length < 5) {
                              return S.enterValidNumber;
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    S.dateOfBirth,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickDob,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedDob == null
                                  ? S.select
                                  : _formatDate(_selectedDob!),
                              style: TextStyle(
                                color: _selectedDob == null
                                    ? AppColors.textHint
                                    : AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    S.gender,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: ['MALE', 'FEMALE'].map((gender) {
                        final selected = _selectedGender == gender;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedGender = gender),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                gradient:
                                    selected ? AppGradients.exchangeButton : null,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Center(
                                child: Text(
                                  gender == 'MALE' ? S.male : S.female,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 17,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  GradientButton(
                    label: S.continueAction,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  String? _normalizedEmail(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }
}

class _GoogleCountryPicker extends StatefulWidget {
  final TextEditingController controller;

  const _GoogleCountryPicker({required this.controller});

  @override
  State<_GoogleCountryPicker> createState() => _GoogleCountryPickerState();
}

class _GoogleCountryPickerState extends State<_GoogleCountryPicker> {
  late CountryItem _selected;

  @override
  void initState() {
    super.initState();
    _selected = kCountries.firstWhere(
      (country) => country.code == widget.controller.text,
      orElse: () => kCountries.first,
    );
    widget.controller.text = _selected.code;
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inputBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Country',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...kCountries.map(
              (country) => ListTile(
                leading: Text(
                  country.flag,
                  style: const TextStyle(fontSize: 26),
                ),
                title: Text(
                  country.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Text(
                  '+${country.code}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: _selected.code == country.code,
                selectedColor: AppColors.exchangeDark,
                selectedTileColor: AppColors.exchangeDark.withOpacity(0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onTap: () {
                  setState(() {
                    _selected = country;
                    widget.controller.text = country.code;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showPicker,
      child: Container(
        height: 56,
        constraints: const BoxConstraints(minWidth: 120, maxWidth: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_selected.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selected.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
