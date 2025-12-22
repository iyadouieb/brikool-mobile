import 'package:brikool_mobile/features/requests/request_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/services.dart';


class ClientRequestsScreen extends StatelessWidget {
  const ClientRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('clientId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'You have not created any job requests yet.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final jobs = snapshot.data!.docs;

          final inProgress = jobs.where((job) {
            final data = job.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'open';
            return status != 'completed';
          }).toList();

          // Helper to get icon for a category
          IconData _iconForCategory(String category) {
            final match = serviceCategories.firstWhere(
              (c) => c.title.toLowerCase() == category.toLowerCase(),
              orElse: () => ServiceCategory(id: 'other', title: 'Other', icon: Icons.handyman),
            );
            return match.icon;
          }

          final completed = jobs.where((job) {
            final data = job.data() as Map<String, dynamic>;
            final status = data['status'] ?? '';
            return status == 'completed';
          }).toList();

          Widget buildTile(DocumentSnapshot doc) {
            final data = doc.data() as Map<String, dynamic>;
            final category = data['category'] ?? 'Unknown';
            final status = data['status'] ?? 'open';
            final urgent = data['urgent'] == true;
            final createdAt = data['createdAt'] as Timestamp?;

            final clientLastSeen = data['clientLastSeenAt'] as Timestamp?;
            final offersUpdated = data['offersUpdatedAt'] as Timestamp?;
            final statusUpdated = data['statusUpdatedAt'] as Timestamp?;

            final hasNewOffer = offersUpdated != null && (clientLastSeen == null || offersUpdated.compareTo(clientLastSeen) > 0);
            final hasStatusChange = statusUpdated != null && (clientLastSeen == null || statusUpdated.compareTo(clientLastSeen) > 0);
            final isNew = hasNewOffer || hasStatusChange;

            final iconData = _iconForCategory(category);
            return Card(
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Icon(iconData, color: Theme.of(context).colorScheme.primary, size: 20),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        category,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isNew)
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Status: ${_formatStatus(status)}'),
                    if (urgent)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Urgent',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (createdAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Created: ${_formatDate(createdAt)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RequestDetailsScreen(jobId: doc.id),
                    ),
                  );
                },
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('In progress', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              if (inProgress.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('No in-progress requests', style: TextStyle(color: Colors.grey[600])),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                      child: buildTile(inProgress[index]),
                    );
                  }, childCount: inProgress.length),
                ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Completed', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              if (completed.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('No completed requests', style: TextStyle(color: Colors.grey[600])),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                      child: buildTile(completed[index]),
                    );
                  }, childCount: completed.length),
                ),
            ],
          );
        },
      );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'open':
        return 'Open';
      case 'assigned':
        return 'Assigned';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}
