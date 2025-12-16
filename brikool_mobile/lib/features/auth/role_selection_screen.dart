import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Widget roleTile(String role, String title, IconData icon) {
    final isSelected = selectedRole == role;

    return GestureDetector(
      onTap: () => setState(() => selectedRole = role),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.redAccent : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontSize: 18, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose your role')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            roleTile('client', 'Find a Pro', Icons.search),
            const SizedBox(height: 16),
            roleTile('provider', 'Become a Pro', Icons.build),
            const Spacer(),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: selectedRole == null ? null : saveRole,
                    child: const Text('Continue'),
                  ),
          ],
        ),
      ),
    );
  }
}
