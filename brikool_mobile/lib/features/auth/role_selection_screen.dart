import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/app_logo.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? selectedRole;
  bool loading = false;

  Future<void> saveRole() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .update({'role': selectedRole});
  }

  Widget roleTile(String role, String title, IconData icon, String description) {
    final isSelected = selectedRole == role;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.grey.shade900,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => selectedRole = role),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 36),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(description, style: const TextStyle(fontSize: 15, color: Colors.white70)),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.white, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: AppLogo(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            roleTile(
              'client',
              'Find a Pro',
              Icons.search,
              'Browse and hire skilled professionals for your needs. Post jobs, review offers, and manage your requests easily.'
            ),
            roleTile(
              'provider',
              'Become a Pro',
              Icons.build,
              'Offer your services, respond to job requests, and grow your business by connecting with new clients.'
            ),
            const SizedBox(height: 32),
            if (selectedRole != null)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    selectedRole == 'client'
                        ? 'As a client, you can find and hire professionals for any job.'
                        : 'As a provider, you can offer your services and get hired for jobs.',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            const SizedBox(height: 32),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: selectedRole == null ? null : saveRole,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Continue'),
                  ),
          ],
        ),
      ),
    );
  }
}
