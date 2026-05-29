import 'package:flutter/material.dart';

/// Красивый переход страницы — slide + fade
Route<T> slideTransition<T>(Widget page,
    {Duration duration = const Duration(milliseconds: 300)}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, value, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: value,
          curve: Curves.easeOutCubic,
        )),
        child: FadeTransition(
          opacity: value,
          child: child,
        ),
      );
    },
    transitionDuration: duration,
  );
}

/// Переход снизу вверх (bottom sheet style)
Route<T> bottomUpTransition<T>(Widget page,
    {Duration duration = const Duration(milliseconds: 350)}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, value, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: value,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      );
    },
    transitionDuration: duration,
  );
}

/// Fade переход
Route<T> fadeTransition<T>(Widget page,
    {Duration duration = const Duration(milliseconds: 400)}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, value, secondaryAnimation, child) {
      return FadeTransition(
        opacity: value,
        child: child,
      );
    },
    transitionDuration: duration,
  );
}

/// Scale переход
Route<T> scaleTransition<T>(Widget page,
    {Duration duration = const Duration(milliseconds: 300)}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, value, secondaryAnimation, child) {
      return ScaleTransition(
        scale: Tween<double>(
          begin: 0.9,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: value,
          curve: Curves.easeOutCubic,
        )),
        child: FadeTransition(
          opacity: value,
          child: child,
        ),
      );
    },
    transitionDuration: duration,
  );
}
