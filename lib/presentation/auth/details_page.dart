import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/auth_models.dart';
import '../../data/services/auth_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_strings.dart';
import '../pages/main_shell_page.dart';
import 'widgets/gradient_button.dart';
import 'widgets/auth_input.dart';
import 'widgets/auth_shell.dart';

class DetailsPage extends StatefulWidget {
  final String registrationToken;

  const DetailsPage({super.key, required this.registrationToken});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  String _selectedGender = 'MALE';
  DateTime? _selectedDob;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
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
    if (picked != null) setState(() => _selectedDob = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDob == null) {
      setState(() => _errorMessage = S.selectDateOfBirth);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await AuthService.submitRegistration(
      SubmitRegistrationRequest(
        registrationToken: widget.registrationToken,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        dateOfBirth: _selectedDob!,
        gender: _selectedGender,
        email: _normalizedEmail(_emailCtrl.text),
        password: _passwordCtrl.text,
      ),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.responseCode == AppConstants.successCode &&
        response.data != null) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => const MainShellPage(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
        (_) => false,
      );
    } else {
      setState(() => _errorMessage = response.responseMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: S.personalDetails,
      subtitle: S.almostDone,
      eyebrow: AuthEyebrow(
        label: S.step3of3,
        icon: Icons.looks_3_outlined,
      ),
      onBack: () => Navigator.pop(context),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthInput(
              label: S.firstName,
              controller: _firstNameCtrl,
              prefixIcon: Icons.badge_outlined,
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? S.min2Chars : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            AuthInput(
              label: S.lastName,
              controller: _lastNameCtrl,
              prefixIcon: Icons.badge_outlined,
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? S.min2Chars : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            AuthInput(
              label: S.emailOptional,
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.alternate_email_rounded,
              validator: (value) {
                final email = _normalizedEmail(value);
                if (email == null) return null;
                return _isValidEmail(email) ? null : S.enterValidEmail;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            _buildDobPicker(),
            const SizedBox(height: 14),
            _buildGenderSelector(),
            const SizedBox(height: 18),
            _divider(),
            const SizedBox(height: 18),
            AuthInput(
              label: S.password,
              controller: _passwordCtrl,
              obscure: true,
              prefixIcon: Icons.lock_outline_rounded,
              validator: (v) =>
                  (v == null || v.length < 8) ? S.min8Chars : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            AuthInput(
              label: S.confirmPassword,
              controller: _confirmPasswordCtrl,
              obscure: true,
              prefixIcon: Icons.lock_outline_rounded,
              validator: (v) =>
                  v != _passwordCtrl.text ? S.passwordsNotMatch : null,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
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
            const SizedBox(height: 24),
            GradientButton(
              label: S.createAccount,
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDobPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                const Icon(Icons.calendar_today_outlined,
                    color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedDob == null
                        ? S.select
                        : '${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: _selectedDob == null
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            children: ['MALE', 'FEMALE'].map((g) {
              final selected = _selectedGender == g;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedGender = g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.buttonGradient : null,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            g == 'MALE'
                                ? Icons.male_rounded
                                : Icons.female_rounded,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            g == 'MALE' ? S.male : S.female,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.inputBorder,
            Colors.transparent
          ],
        ),
      ),
    );
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
