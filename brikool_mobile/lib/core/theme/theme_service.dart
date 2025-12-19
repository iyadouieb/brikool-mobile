import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ThemeService {
  ThemeService._privateConstructor();
  static final ThemeService instance = ThemeService._privateConstructor();

  final ValueNotifier<ThemeMode> modeNotifier = ValueNotifier(ThemeMode.dark);

  StreamSubscription<DocumentSnapshot<Object?>>? _userSub;
  StreamSubscription<User?>? _authSub;

  void init() {
    // Listen to auth changes and attach/detach document listeners
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _userSub?.cancel();
      if (user == null) {
        // default to dark
        modeNotifier.value = ThemeMode.dark;
        return;
      }

      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      _userSub = docRef.snapshots().listen((snap) {
        if (!snap.exists) return;
        final data = snap.data();
        final theme = data?['theme'] as String?;
        if (theme == 'light') modeNotifier.value = ThemeMode.light;
        else if (theme == 'system') modeNotifier.value = ThemeMode.system;
        else modeNotifier.value = ThemeMode.dark;
      });
    });
  }

  Future<void> setTheme(ThemeMode mode) async {
    modeNotifier.value = mode;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final val = mode == ThemeMode.light ? 'light' : mode == ThemeMode.system ? 'system' : 'dark';
    await docRef.set({'theme': val}, SetOptions(merge: true));
  }

  void dispose() {
    _userSub?.cancel();
    _authSub?.cancel();
    modeNotifier.dispose();
  }
}
