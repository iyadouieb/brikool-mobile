import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/role_selection_screen.dart';
import 'client_home_screen.dart';
import 'provider_home_screen.dart';
import '../auth/profile_completion_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('User profile not found')),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        final role = data['role'];
        final profileCompleted = data['profileCompleted'] ?? false;

        if (role == null) {
          return const RoleSelectionScreen();
        }

        if (!profileCompleted) {
          return ProfileCompletionScreen(role: role);
        }

        if (role == 'provider') {
          return const ProviderHomeScreen();
        }

        return const ClientHomeScreen();
      },
    );
  }
}
