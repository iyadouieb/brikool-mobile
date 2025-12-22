import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/app_logo.dart';
import '../requests/request_details_screen.dart';

class ProviderJobsScreen extends StatelessWidget {
  const ProviderJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('jobs')
        .where('assignedProviderId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'assigned')
        .orderBy('assignedAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: AppLogo(),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No assigned jobs'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final category = data['category'] ?? 'Unknown';
              final description = data['description'] ?? '';
              final price = data['assignedPrice'] != null ? '${data['assignedPrice']} MAD' : '';

              return Card(
                elevation: 2,
                child: ListTile(
                  title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(description),
                      if (price.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('Price: $price', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RequestDetailsScreen(jobId: doc.id)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
