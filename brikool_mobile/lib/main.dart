import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'core/theme/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // initialize theme service so it listens to user theme preference
  // (fires immediately if user is signed in)
  // Initialize ThemeService in a microtask so it doesn't block startup
  Future.microtask(() => ThemeService.instance.init());

  runApp(const BrikoolApp());
}
