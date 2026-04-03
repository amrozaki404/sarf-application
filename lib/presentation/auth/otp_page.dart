import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/auth_models.dart';
import '../../data/services/auth_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_strings.dart';
import '../../core/localization/locale_service.dart';
import 'details_page.dart';
import 'widgets/gradient_button.dart';
import 'widgets/auth_shell.dart';

class OtpPage extends StatefulWidget {
  final String countryCode;
  final String phoneNumber;

  const OtpPage({
    super.key,
    required this.countryCode,
    required this.phoneNumber,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _otpController = TextEditingController();
  String _otpCode = '';
  bool _isLoading = false;
  String? _errorMessage;

  int _secondsRemaining = 300;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = 300;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining <= 0) {
        _timer?.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  String get _timerText {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _confirm() async {
    if (_otpCode.length < 5) {
      setState(() => _errorMessage = S.enter5DigitFirst);
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await AuthService.confirmOtp(ConfirmOtpRequest(
      countryCode: widget.countryCode,
      phoneNumber: widget.phoneNumber,
      otpCode: _otpCode,
    ));

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.responseCode == AppConstants.successCode &&
        response.registrationToken != null) {
      Navigator.of(context).push(PageRouteBuilder(
        pageBuilder: (_, anim, __) => DetailsPage(
          registrationToken: response.registrationToken!,
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

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    final response = await AuthService.requestOtp(RequestOtpRequest(
      countryCode: widget.countryCode,
      phoneNumber: widget.phoneNumber,
    ));
    if (!mounted) return;
    if (response.isSuccess) {
      _startTimer();
      _otpController.clear();
      setState(() => _otpCode = '');
    } else {
      setState(() => _errorMessage = response.responseMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.localeNotifier,
      builder: (context, _, __) => AuthShell(
        title: S.verifyPhone,
        subtitle: '${S.codeSentTo} +${widget.countryCode} ${widget.phoneNumber}',
        eyebrow: AuthEyebrow(
          label: S.step2of3,
          icon: Icons.looks_two_outlined,
        ),
        onBack: () => Navigator.pop(context),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF5FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      S.enter5DigitCode,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PinCodeTextField(
              appContext: context,
              length: 5,
              controller: _otpController,
              onChanged: (v) => setState(() => _otpCode = v),
              onCompleted: (v) {
                setState(() => _otpCode = v);
                _confirm();
              },
              keyboardType: TextInputType.number,
              animationType: AnimationType.fade,
              animationDuration: const Duration(milliseconds: 200),
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(16),
                fieldHeight: 58,
                fieldWidth: 52,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.inputBorder,
                selectedColor: AppColors.primary,
                activeFillColor: AppColors.inputFill,
                inactiveFillColor: AppColors.inputFill,
                selectedFillColor: AppColors.primary.withOpacity(0.08),
              ),
              enableActiveFill: true,
              textStyle: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              cursorColor: AppColors.primary,
              backgroundColor: Colors.transparent,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withOpacity(0.25)),
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
              label: S.confirmCode,
              isLoading: _isLoading,
              onPressed: (_isLoading || _otpCode.length < 5) ? null : _confirm,
            ),
            const SizedBox(height: 18),
            !_canResend
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: AppColors.textHint,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${S.resendIn} $_timerText',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: _resendOtp,
                    child: Text(
                      S.resendCode,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
