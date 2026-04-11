import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';

import 'core/theme/app_theme.dart';
import 'core/services/navigation_service.dart';
import 'core/services/biometric_service.dart';
import 'core/services/permission_service.dart';
import 'core/localization/locale_service.dart';
import 'data/services/auth_service.dart';
import 'presentation/auth/login_page.dart';
import 'presentation/pages/main_shell_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseReady = await _initializeFirebase();

  if (firebaseReady) {
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  await LocaleService.init();
  await EasyLocalization.ensureInitialized();

  await PermissionService.requestStartupPermissions();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  NavigationService.setLoginCallback(() {
    NavigationService.navigatorKey.currentState?.pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const LoginPage(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (_) => false,
    );
  });
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      startLocale: LocaleService.locale,
      saveLocale: false,
      child: const SarfApp(),
    ),
  );
}

Future<bool> _initializeFirebase() async {
  try {
    debugPrint(
      'Firebase init started for project: '
      '${DefaultFirebaseOptions.currentPlatform.projectId}',
    );
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase init completed successfully.');
    return true;
  } catch (error) {
    debugPrint('Firebase initialization skipped: $error');
    return false;
  }
}

class SarfApp extends StatelessWidget {
  const SarfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sarf',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: const _SplashRouter(),
    );
  }
}

class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    final loggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;

    if (loggedIn) {
      // If biometric login is enabled, require the user to authenticate before
      // entering the app. Session validity is determined by the token alone —
      // the user-data cache is not required here.
      final biometricEnabled = await BiometricService.isEnabled();
      final biometricAvailable = await BiometricService.isAvailable();
      if (!mounted) return;
      if (biometricEnabled && biometricAvailable) {
        final authenticated = await BiometricService.authenticate();
        if (!mounted) return;
        if (!authenticated) {
          // Biometric failed or cancelled → fall through to login page.
          _goToLogin();
          return;
        }
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => const MainShellPage(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
      return;
    }

    _goToLogin();
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const LoginPage(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.exchangeHeader,
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 120,
                height: 120,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
