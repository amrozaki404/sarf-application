import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/auth_models.dart';
import '../../data/services/auth_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_strings.dart';
import '../../core/localization/locale_service.dart';
import 'otp_page.dart';
import 'widgets/gradient_button.dart';
import 'widgets/auth_input.dart';
import 'widgets/country_code_picker.dart';
import 'widgets/auth_shell.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _countryCodeCtrl = TextEditingController(text: '249');
  final _phoneCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _countryCodeCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await AuthService.requestOtp(RequestOtpRequest(
      countryCode: _countryCodeCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
    ));

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.responseCode == AppConstants.otpSentCode ||
        response.responseCode == AppConstants.successCode) {
      Navigator.of(context).push(PageRouteBuilder(
        pageBuilder: (_, anim, __) => OtpPage(
          countryCode: _countryCodeCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim(),
        ),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ));
    } else {
      setState(() => _errorMessage = response.responseMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.localeNotifier,
      builder: (context, _, __) => AuthShell(
        title: S.createAccount,
        subtitle: S.enterPhoneDesc,
        eyebrow: AuthEyebrow(
          label: S.step1of3,
          icon: Icons.looks_one_outlined,
        ),
        onBack: () => Navigator.pop(context),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CountryCodePicker(controller: _countryCodeCtrl),
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
                      validator: (v) => (v == null || v.trim().length < 5)
                          ? S.enterValidNumber
                          : null,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _requestOtp(),
                    ),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppColors.error.withOpacity(0.25)),
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
              const SizedBox(height: 22),
              GradientButton(
                label: S.sendVerificationCode,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _requestOtp,
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    '${S.alreadyHaveAccount} ${S.signIn}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
