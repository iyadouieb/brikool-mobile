import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/theme_service.dart';
import '../../widgets/app_logo.dart';
import '../home/provider_earnings_screen.dart';
import '../auth/profile_completion_screen.dart';

class ProviderProfileScreen extends StatelessWidget {
  const ProviderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final uid = user.uid;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        //title: const Text('Profile'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
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
          final role = data['role'] ?? 'provider';
          final trade = data['trade'] ?? 'Not set';

          final fullName = (('$firstName $lastName').trim().isEmpty) ? 'Unnamed user' : '$firstName $lastName';

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 44,
                              child: Text(fullName[0].toUpperCase(), style: const TextStyle(fontSize: 36)),
                            ),
                            const SizedBox(height: 12),
                            Text(fullName, style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 6),
                            Text(trade, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                            const SizedBox(height: 12),

                            // Rating and quick actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('jobs')
                                      .where('assignedProviderId', isEqualTo: uid)
                                      .where('providerRating', isGreaterThan: 0)
                                      .snapshots(),
                                  builder: (context, snap) {
                                    if (!snap.hasData || snap.data!.docs.isEmpty) return const SizedBox.shrink();
                                    final docs = snap.data!.docs;
                                    double sum = 0;
                                    for (final d in docs) {
                                      final data = d.data() as Map<String, dynamic>;
                                      final r = data['providerRating'];
                                      if (r is num) sum += r.toDouble();
                                    }
                                    final avg = (sum / docs.length);
                                    return Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber),
                                        const SizedBox(width: 6),
                                        Text(avg.toStringAsFixed(1)),
                                        const SizedBox(width: 6),
                                        Text('(${docs.length})', style: const TextStyle(color: Colors.grey)),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const ProviderEarningsScreen()),
                                    );
                                  },
                                  icon: const Icon(Icons.attach_money),
                                  label: const Text('Earnings'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    minimumSize: const Size(110, 40),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => ProfileCompletionScreen(role: 'provider', isEdit: true)),
                                    );
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit'),                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    minimumSize: const Size(90, 40),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Contact and role/trade
                      Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Contact', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text('Email: ${user.email ?? ''}'),
                              const SizedBox(height: 6),
                              Text('Phone: $phone'),
                              const SizedBox(height: 8),
                              Chip(label: Text(role.toString().toUpperCase())),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Theme and logout
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
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      ),
                    ],
                  ),
                ),
              ),

              // Recent completed jobs and earnings
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Recent completed jobs', style: Theme.of(context).textTheme.titleMedium),
                ),
              ),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('jobs')
                    .where('assignedProviderId', isEqualTo: uid)
                    .where('status', isEqualTo: 'completed')
                    .orderBy('completedAt', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const SliverToBoxAdapter(child: SizedBox.shrink());
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Text('No recent jobs')));

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final doc = docs[index];
                      final d = doc.data() as Map<String, dynamic>;
                      final category = d['category'] ?? 'Unknown';
                      final price = d['assignedPrice'] ?? '';
                      final completedAt = d['completedAt'] as Timestamp?;

                      String dateText = '';
                      if (completedAt != null) {
                        final dt = completedAt.toDate();
                        dateText = '${dt.day}/${dt.month}/${dt.year}';
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Card(
                          child: ListTile(
                            title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(dateText),
                            trailing: price != null ? Text('${price} MAD', style: const TextStyle(fontWeight: FontWeight.bold)) : null,
                          ),
                        ),
                      );
                    }, childCount: docs.length),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showThemeDialog(BuildContext context) async {
    final selected = ThemeService.instance.modeNotifier.value;

    final choice = await showDialog<ThemeMode>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: selected,
                title: const Text('Dark'),
                onChanged: (v) => Navigator.pop(context, v),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.light,
                groupValue: selected,
                title: const Text('Light'),
                onChanged: (v) => Navigator.pop(context, v),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.system,
                groupValue: selected,
                title: const Text('System'),
                onChanged: (v) => Navigator.pop(context, v),
              ),
            ],
          ),
        );
      },
    );

    if (choice != null) {
      await ThemeService.instance.setTheme(choice);
    }
  }
}
