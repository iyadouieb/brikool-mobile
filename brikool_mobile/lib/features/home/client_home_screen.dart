import 'package:brikool_mobile/features/requests/client_requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/services.dart';
import '../../widgets/service_card.dart';
import '../../widgets/app_logo.dart';
import '../profile/client_profile_screen.dart';
import '../requests/job_request_screen.dart';



class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: AppLogo(),
      ),
      body: _buildBody(),
      bottomNavigationBar: StreamBuilder<QuerySnapshot?>(
        stream: FirebaseAuth.instance.currentUser == null
            ? null
            : FirebaseFirestore.instance.collection('jobs').where('clientId', isEqualTo: FirebaseAuth.instance.currentUser!.uid).snapshots(),
        builder: (context, snap) {
          bool hasNew = false;
          if (snap.hasData) {
            final docs = snap.data!.docs;
            hasNew = docs.any((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final clientLastSeen = data['clientLastSeenAt'] as Timestamp?;
              final offersUpdated = data['offersUpdatedAt'] as Timestamp?;
              final statusUpdated = data['statusUpdatedAt'] as Timestamp?;
              final offerIsNew = offersUpdated != null && (clientLastSeen == null || offersUpdated.compareTo(clientLastSeen) > 0);
              final statusIsNew = statusUpdated != null && (clientLastSeen == null || statusUpdated.compareTo(clientLastSeen) > 0);
              return offerIsNew || statusIsNew;
            });
          }

          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.assignment),
                    if (hasNew)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: CircleAvatar(
                          radius: 6,
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
                label: 'Requests',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildCategoriesGrid();
      case 1:
        return const Center(child: Text('Search – coming soon'));
      case 2:
        return const ClientRequestsScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const SizedBox();
    }
  }

  Widget _buildCategoriesGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: serviceCategories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final category = serviceCategories[index];
          return ServiceCard(
            category: category,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JobRequestScreen(
                    category: category.title,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
