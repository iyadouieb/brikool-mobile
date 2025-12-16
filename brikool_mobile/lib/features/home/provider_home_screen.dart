import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ProviderHomeScreen extends StatelessWidget {
  const ProviderHomeScreen({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> resetRole() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .update({'role': null, 'profileCompleted' : null});
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BRIKOOL'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
          TextButton(
            onPressed: resetRole,
            child: const Text('Reset role (dev)'),
          ),
        ],
      ),
      body: Center(
        
        child: Text(
          'Provider Home',
          style: TextStyle(fontSize: 22),
        ),
        
      ),
      
    );
  }
}
