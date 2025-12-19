import 'package:brikool_mobile/features/auth/auth_gate.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_service.dart';

class BrikoolApp extends StatelessWidget {
  const BrikoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.modeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'BRIKOOL',
          debugShowCheckedModeBanner: true,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          home: const AuthGate(),
        );
      },
    );
  }
}
