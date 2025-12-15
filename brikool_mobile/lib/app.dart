import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';

class BrikoolApp extends StatelessWidget {
  const BrikoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BRIKOOL',
      debugShowCheckedModeBanner: true,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
