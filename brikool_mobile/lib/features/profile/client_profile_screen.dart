import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/theme_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final uid = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Profile not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final firstName = data['firstName'] ?? '';
          final lastName = data['lastName'] ?? '';
          final phone = data['phone'] ?? 'Not provided';
          final role = data['role'] ?? 'unknown';

          final fullName =
              ('$firstName $lastName').trim().isEmpty
                  ? 'Unnamed user'
                  : '$firstName $lastName';

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Avatar
                CircleAvatar(
                  radius: 40,
                  child: Text(
                    fullName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 32),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  fullName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),

                const SizedBox(height: 8),

                Text(
                  user.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 8),

                Text(
                  phone,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 12),

                Chip(
                  label: Text(role.toString().toUpperCase()),
                ),

                const Spacer(),

                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: const Text('Theme'),
                  subtitle: ValueListenableBuilder<ThemeMode>(
                    valueListenable: ThemeService.instance.modeNotifier,
                    builder: (context, mode, _) {
                      final label = mode == ThemeMode.light ? 'Light' : mode == ThemeMode.system ? 'System' : 'Dark';
                      return Text(label);
                    },
                  ),
                  onTap: () => _showThemeDialog(context),
                ),

                ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                value: ThemeMode.light,
                groupValue: ThemeService.instance.modeNotifier.value,
                title: const Text('Light'),
                onChanged: (v) {
                  if (v != null) {
                    ThemeService.instance.setTheme(v);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: ThemeService.instance.modeNotifier.value,
                title: const Text('Dark'),
                onChanged: (v) {
                  if (v != null) {
                    ThemeService.instance.setTheme(v);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.system,
                groupValue: ThemeService.instance.modeNotifier.value,
                title: const Text('System'),
                onChanged: (v) {
                  if (v != null) {
                    ThemeService.instance.setTheme(v);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
