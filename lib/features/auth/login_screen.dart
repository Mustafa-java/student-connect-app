import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../services/api_service.dart';
import 'register_screen.dart';

/// Экран входа — стиль Instagram 2025
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorText = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    debugPrint('=== LOGIN ATTEMPT ===');
    debugPrint('Email: $email');
    debugPrint('Current userId: ${ApiService.instance.currentUserId}');

    try {
      final success = await ref.read(authStatusProvider.notifier).login(
            email,
            password,
          );

      debugPrint('Login success: $success');
      debugPrint('After login userId: ${ApiService.instance.currentUserId}');

      if (!success || !mounted) {
        setState(() {
          _errorText = 'Не удалось войти. Проверьте подключение к серверу.';
        });
        debugPrint('=====================');
        return;
      }

      // Принудительно обновляем currentUserProvider
      ref.invalidate(currentUserProvider);
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('After invalidate, current userId: ${ApiService.instance.currentUserId}');
      debugPrint('=====================');

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (e) {
      debugPrint('Login exception: $e');
      debugPrint('=====================');
      if (mounted) {
        setState(() {
          // Показываем более понятное сообщение об ошибке
          String errorMessage = 'Произошла ошибка при входе';
          final errorStr = e.toString().toLowerCase();
          
          if (errorStr.contains('network') || errorStr.contains('connection') || errorStr.contains('socket')) {
            errorMessage = 'Не удалось подключиться к серверу. Проверьте интернет-соединение.';
          } else if (errorStr.contains('401') || errorStr.contains('неверный')) {
            errorMessage = 'Неверный email или пароль';
          } else if (errorStr.contains('пустой ответ') || errorStr.contains('empty')) {
            errorMessage = 'Сервер не отвечает. Попробуйте позже.';
          } else if (errorStr.contains('500')) {
            errorMessage = 'Ошибка сервера. Попробуйте позже.';
          } else {
            errorMessage = e.toString();
            if (errorMessage.length > 100) {
              errorMessage = errorMessage.substring(0, 100) + '...';
            }
          }
          
          _errorText = errorMessage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = ref.watch(authStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Логотип
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ).animate().scale(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                      ),

                  const SizedBox(height: 20),

                  // Название
                  const Text(
                    'СтудХаб',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ).animate().fadeIn(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 200),
                      ),

                  const SizedBox(height: 8),

                  const Text(
                    'Войдите в свой аккаунт',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textDarkSecondary,
                    ),
                  ).animate().fadeIn(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 300),
                      ),

                  const SizedBox(height: 40),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      filled: true,
                      fillColor: AppColors.surfaceDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите email';
                      }
                      if (!value.contains('@')) {
                        return 'Некорректный email';
                      }
                      return null;
                    },
                  ).animate().fadeIn(
                        duration: const Duration(milliseconds: 400),
                        delay: const Duration(milliseconds: 400),
                      ),

                  const SizedBox(height: 16),

                  // Пароль
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Пароль',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите пароль';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _handleLogin(),
                  ).animate().fadeIn(
                        duration: const Duration(milliseconds: 400),
                        delay: const Duration(milliseconds: 500),
                      ),

                  // Ошибка
                  if (_errorText != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorText!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Кнопка входа
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authStatus == AuthStatus.loading
                          ? null
                          : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: authStatus == AuthStatus.loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Войти',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ).animate().fadeIn(
                        duration: const Duration(milliseconds: 400),
                        delay: const Duration(milliseconds: 600),
                      ),

                  const SizedBox(height: 24),

                  // Разделитель
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: AppColors.divider.withValues(alpha: 0.5),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'или',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textDarkSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: AppColors.divider.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Регистрация
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Нет аккаунта? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textDarkSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const RegisterScreen(),
                              transitionsBuilder:
                                  (context, value, secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: value,
                                  child: child,
                                );
                              },
                              transitionDuration:
                                  const Duration(milliseconds: 300),
                            ),
                          );
                        },
                        child: const Text(
                          'Зарегистрироваться',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
