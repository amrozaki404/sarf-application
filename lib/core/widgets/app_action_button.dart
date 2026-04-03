import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool dark;
  final double width;
  final double height;

  const AppActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.dark = false,
    this.width = 48,
    this.height = 46,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        dark ? Colors.white.withOpacity(0.14) : AppColors.borderSoft;
    final iconColor = dark ? Colors.white : AppColors.exchangeDark;

    return Material(
      color: dark ? Colors.white.withOpacity(0.08) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: dark ? Colors.white.withOpacity(0.06) : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
