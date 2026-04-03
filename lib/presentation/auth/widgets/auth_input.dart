import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/app_input_field.dart';

class AuthInput extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscure;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;
  final bool enabled;
  final bool readOnly;

  const AuthInput({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.obscure = false,
    this.prefixIcon,
    this.prefixWidget,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.inputFormatters,
    this.textInputAction,
    this.onFieldSubmitted,
    this.focusNode,
    this.enabled = true,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppInputField(
      label: label,
      hint: hint,
      controller: controller,
      obscure: obscure,
      prefixIcon: prefixIcon,
      prefixWidget: prefixWidget,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      focusNode: focusNode,
      enabled: enabled,
      readOnly: readOnly,
    );
  }
}
