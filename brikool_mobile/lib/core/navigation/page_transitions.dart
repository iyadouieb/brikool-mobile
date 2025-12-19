import 'package:flutter/material.dart';

PageRouteBuilder<T> fadeSlideRoute<T>({required Widget page, Offset beginOffset = const Offset(0, 0.04), Duration duration = const Duration(milliseconds: 350)}) {
  return PageRouteBuilder<T>(
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offsetAnim = Tween<Offset>(begin: beginOffset, end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);
      final fadeAnim = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
      return SlideTransition(
        position: offsetAnim,
        child: FadeTransition(opacity: fadeAnim, child: child),
      );
    },
  );
}
