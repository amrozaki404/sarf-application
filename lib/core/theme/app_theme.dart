import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF006BFF);
  static const Color primaryDark = Color(0xFF0057D1);
  static const Color primaryDeep = Color(0xFF0044A7);
  static const Color secondary = Color(0xFF56C51F);

  static const Color background = Color(0xFFF4F7FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFF2F5FA);
  static const Color inputBorder = Color(0xFFE3EAF5);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF667085);
  static const Color textHint = Color(0xFF98A2B3);

  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF56C51F);
  static const Color exchangeDark = Color(0xFF0057D1);
  static const Color exchangeDarkSoft = Color(0xFF006BFF);
  static const Color surfaceMuted = Color(0xFFF7FAFB);
  static const Color borderSoft = Color(0xFFE5EDF0);
  static const Color skeletonBase = Color(0xFFF1F5F7);
  static const Color skeletonHighlight = Color(0xFFF7FAFB);

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF071C3F), Color(0xFF0057D1)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF005DE3), Color(0xFF006BFF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1B78FF), Color(0xFF0057D1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppGradients {
  static const LinearGradient exchangeHeader = LinearGradient(
    colors: [AppColors.exchangeDark, AppColors.exchangeDarkSoft],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient exchangeButton = LinearGradient(
    colors: [AppColors.exchangeDark, AppColors.exchangeDarkSoft],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient disabledButton = LinearGradient(
    colors: [Color(0xFFBDC3C7), Color(0xFF95A5A6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class AppRadii {
  static const BorderRadius md = BorderRadius.all(Radius.circular(12));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(20));
  static const BorderRadius xxl = BorderRadius.all(Radius.circular(24));
}

class AppShadows {
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> action = [
    BoxShadow(
      color: Colors.black.withOpacity(0.025),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> exchange = [
    BoxShadow(
      color: AppColors.exchangeDark.withOpacity(0.18),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> button = [
    BoxShadow(
      color: AppColors.exchangeDark.withOpacity(0.28),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}

class AppTheme {
  static TextTheme get _cairoTextTheme => GoogleFonts.cairoTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          headlineLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textSecondary),
        ),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: _cairoTextTheme,
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          titleTextStyle: GoogleFonts.cairo(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceMuted,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.borderSoft),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.borderSoft),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.exchangeDark,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          labelStyle: GoogleFonts.cairo(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
          hintStyle: GoogleFonts.cairo(
            color: AppColors.textHint,
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      );
}
