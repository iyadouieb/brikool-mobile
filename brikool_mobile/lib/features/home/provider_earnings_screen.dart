import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/animated_entrance.dart';
import '../../widgets/app_logo.dart';
import '../../core/navigation/page_transitions.dart';
import '../requests/request_details_screen.dart';

class ProviderEarningsScreen extends StatelessWidget {
  const ProviderEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

    final stream = FirebaseFirestore.instance
        .collection('jobs')
        .where('assignedProviderId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'completed')
        .orderBy('completedAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        //title: AppLogo(),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          double total = 0.0;
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final price = data['assignedPrice'];
            if (price != null) {
              if (price is num) total += price.toDouble();
              else if (price is String) total += double.tryParse(price) ?? 0.0;
            }
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: AnimatedEntrance(
                    delay: const Duration(milliseconds: 50),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.85)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total earnings', style: TextStyle(color: Colors.white70)),
                                  const SizedBox(height: 8),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 350),
                                    transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
                                    child: Text(
                                      '${total.toStringAsFixed(0)} MAD',
                                      key: ValueKey<double>(total),
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Completed jobs', style: TextStyle(color: Colors.white70)),
                                const SizedBox(height: 8),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 350),
                                  transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
                                  child: Text(
                                    '${docs.length}',
                                    key: ValueKey<int>(docs.length),
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (docs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: AnimatedEntrance(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.inbox, size: 60, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No completed jobs yet', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final category = data['category'] ?? 'Unknown';
                      final price = data['assignedPrice'] != null ? '${data['assignedPrice']} MAD' : '';
                      final completedAt = data['completedAt'] as Timestamp?;
                      String dateText = '';
                      if (completedAt != null) {
                        final d = completedAt.toDate();
                        dateText = '${d.day}/${d.month}/${d.year}';
                      }

                      return Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                        child: AnimatedEntrance(
                          delay: Duration(milliseconds: 80 * (index % 6)),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  if (dateText.isNotEmpty) Text(dateText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              trailing: Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
                              onTap: () {
                                Navigator.of(context).push(fadeSlideRoute(page: RequestDetailsScreen(jobId: doc.id)));
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: docs.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
