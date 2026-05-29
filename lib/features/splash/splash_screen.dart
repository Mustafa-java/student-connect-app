import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import '../auth/onboarding_screen.dart';
import '../main_screen.dart';

/// Экран заставки с проверкой авторизации
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    debugPrint('SplashScreen: hasSeenOnboarding=$hasSeenOnboarding');
    debugPrint('SplashScreen: ApiService.isAuthenticated=${ApiService.instance.isAuthenticated}');
    debugPrint('SplashScreen: ApiService.token=${ApiService.instance.token != null}');

    if (!hasSeenOnboarding) {
      await prefs.setBool('has_seen_onboarding', true);
      _navigateTo(const OnboardingScreen());
      return;
    }

    // Проверяем авторизацию напрямую через API сервис
    // AuthNotifier._checkAuth() асинхронный, поэтому проверяем напрямую
    final isAuthenticated = ApiService.instance.isAuthenticated;

    if (isAuthenticated) {
      // Проверяем что токен валидный
      try {
        debugPrint('SplashScreen: validating token...');
        await ApiService.instance.getCurrentUser();
        if (!mounted) return;
        debugPrint('SplashScreen: token valid, navigating to MainScreen');
        final _ = ref.refresh(currentUserProvider);
        _navigateTo(const MainScreen());
      } catch (e) {
        debugPrint('SplashScreen: Token validation failed: $e');
        if (!mounted) return;
        _navigateTo(const LoginScreen());
      }
    } else {
      debugPrint('SplashScreen: not authenticated, navigating to LoginScreen');
      if (!mounted) return;
      _navigateTo(const LoginScreen());
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, value, secondaryAnimation, child) {
          return FadeTransition(opacity: value, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF121212),
              Color(0xFF1E1E2E),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              )
                  .animate()
                  .scale(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                  )
                  .then()
                  .shimmer(
                    duration: const Duration(milliseconds: 1200),
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              )
                  .animate()
                  .fadeIn(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 300),
                  )
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 8),
              Text(
                AppConstants.appTagline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                  letterSpacing: 0.3,
                ),
              )
                  .animate()
                  .fadeIn(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 600),
                  )
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 48),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
                  .animate()
                  .fadeIn(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 900),
                  )
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                    duration: const Duration(milliseconds: 400),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
