import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import '../profile/provider_profile_screen.dart';
import 'provider_jobs_screen.dart';
import 'provider_earnings_screen.dart';
import '../../widgets/animated_entrance.dart';
import '../../widgets/app_logo.dart';
import '../requests/request_details_screen.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  bool available = true;

  int _currentIndex = 0;
  bool _loadingLocation = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: AppLogo(),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const ProviderJobsScreen();
      case 2:
        return const ProviderEarningsScreen();
      case 3:
        return const ProviderProfileScreen();
      default:
        return const SizedBox();
    }
  }

  /// 🏠 DASHBOARD (UNCHANGED UI)
  Widget _buildDashboard() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔁 AVAILABILITY SWITCH
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Availability',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Switch(
                        value: available,
                        onChanged: (value) {
                          setState(() => available = value);
                        },
                        activeColor: Theme.of(context).colorScheme.secondary,
                      ),
                      Text(
                        available ? 'You are available' : 'You are offline',
                        style: TextStyle(
                          color: available ? Theme.of(context).colorScheme.secondary : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                /// 📊 STATS GRID (live)
                StreamBuilder<QuerySnapshot>(
                  stream: (() {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return const Stream<QuerySnapshot>.empty();
                    final now = DateTime.now();
                    final startOfDay = DateTime(now.year, now.month, now.day);
                    return FirebaseFirestore.instance
                        .collection('jobs')
                        .where('assignedProviderId', isEqualTo: user.uid)
                        .where('status', isEqualTo: 'completed')
                        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                        .snapshots();
                  })(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      // show empty stats on error
                      return Row(
                        children: const [
                          Expanded(child: _StatCard(title: "Today's Jobs", value: '0', icon: Icons.check_circle)),
                          SizedBox(width: 12),
                          Expanded(child: _StatCard(title: "Today's Earnings", value: '0 MAD', icon: Icons.payments)),
                        ],
                      );
                    }

                    if (!snapshot.hasData) {
                      // loading placeholder
                      return Row(
                        children: const [
                          Expanded(child: _StatCard(title: "Today's Jobs", value: '—', icon: Icons.check_circle)),
                          SizedBox(width: 12),
                          Expanded(child: _StatCard(title: "Today's Earnings", value: '—', icon: Icons.payments)),
                        ],
                      );
                    }

                    final docs = snapshot.data!.docs;
                    final completedCount = docs.length;
                    double earningsSum = 0.0;
                    for (final doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final price = data['assignedPrice'];
                      if (price != null) {
                        if (price is num) earningsSum += price.toDouble();
                        else if (price is String) earningsSum += double.tryParse(price) ?? 0.0;
                      }
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: AnimatedEntrance(
                            child: _StatCard(
                              title: "Today's Jobs",
                              value: completedCount.toString(),
                              icon: Icons.check_circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AnimatedEntrance(
                            delay: const Duration(milliseconds: 70),
                            child: _StatCard(
                              title: "Today's Earnings",
                              value: '${earningsSum.toStringAsFixed(0)} MAD',
                              icon: Icons.payments,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                /// 📍 NEARBY JOBS
                AnimatedEntrance(
                  delay: const Duration(milliseconds: 140),
                  child: const Text(
                    'Nearby Jobs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // Nearby jobs: filter by provider trade first (fetched from users/{uid}.trade)
        if (_loadingLocation)
          SliverFillRemaining(hasScrollBody: false, child: const Center(child: CircularProgressIndicator()))
        else
          Builder(builder: (context) {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) {
              return const SliverToBoxAdapter(
                child: Padding(padding: EdgeInsets.all(16), child: Center(child: Text('Not authenticated'))),
              );
            }

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()));
                }

                final userData = userSnap.data?.data() as Map<String, dynamic>?;
                final trade = (userData?['trade'] as String?)?.trim();

                if (trade == null || trade.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('You have not set your trade yet. Please complete your profile to receive matching requests.'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProviderProfileScreen())),
                            child: const Text('Complete profile'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Query only jobs that match the provider's trade
                final stream = FirebaseFirestore.instance
                    .collection('jobs')
                    .where('status', isEqualTo: 'open')
                    .where('category', isEqualTo: trade)
                    .snapshots();

                return StreamBuilder<QuerySnapshot>(
                  stream: stream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()));
                    }

                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(child: Text(snapshot.error.toString())),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: Text('No nearby jobs found')),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    // Map documents to jobs with distance and filter by radius (e.g., 20 km)
                    final jobsWithDistance = docs
                        .map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          // Double-check category matches trade (case-insensitive fallback)
                          final cat = (data['category'] as String?) ?? '';
                          if (cat.toLowerCase() != trade.toLowerCase()) return null;

                          final loc = data['location'] as Map<String, dynamic>?;
                          if (loc == null) return null;
                          final lat = (loc['lat'] as num).toDouble();
                          final lng = (loc['lng'] as num).toDouble();
                          if (_currentPosition == null) return null;
                          final distanceKm = _calculateDistanceKm(
                              _currentPosition!.latitude, _currentPosition!.longitude, lat, lng);
                          return {
                            'id': doc.id,
                            'category': data['category'] ?? 'Unknown',
                            'description': data['description'] ?? '',
                            'distanceKm': distanceKm,
                          };
                        })
                        .where((e) => e != null)
                        .cast<Map<String, dynamic>>()
                        .where((e) => (e['distanceKm'] as double) <= 20.0)
                        .toList();

                    if (jobsWithDistance.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: Text('No nearby jobs within 20 km')),
                        ),
                      );
                    }

                    jobsWithDistance.sort((a, b) => (a['distanceKm'] as double).compareTo(b['distanceKm'] as double));

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final job = jobsWithDistance[index];
                          final distanceLabel = '${(job['distanceKm'] as double).toStringAsFixed(1)} km';
                          return Padding(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                            child: AnimatedEntrance(
                              delay: Duration(milliseconds: 60 * (index % 6)),
                              child: _NearbyJobTile(
                                jobId: job['id'],
                                category: job['category'],
                                description: job['description'],
                                distance: distanceLabel,
                              ),
                            ),
                          );
                        },
                        childCount: jobsWithDistance.length,
                      ),
                    );
                  },
                );
              },
            );
          }),
      ],
    );
  }

  Future<void> _detectLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _loadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        _loadingLocation = false;
      });
    } catch (e) {
      setState(() => _loadingLocation = false);
    }
  }

  double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) * math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);
}

/// 📦 STAT CARD
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// 📍 NEARBY JOB TILE
class _NearbyJobTile extends StatelessWidget {
  final String category;
  final String description;
  final String distance;
  final String jobId;

  const _NearbyJobTile({
    required this.jobId,
    required this.category,
    required this.description,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.location_on, color: Theme.of(context).colorScheme.secondary),
        title: Text(category),
        subtitle: Text(description),
        trailing: Text(distance),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RequestDetailsScreen(jobId: jobId),
            ),
          );
        },
      ),
    );
  }
}
