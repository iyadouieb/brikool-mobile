import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/app_logo.dart';

class RequestDetailsScreen extends StatefulWidget {
  final String jobId;

  const RequestDetailsScreen({super.key, required this.jobId});

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _markClientSeenOnOpen();
  }

  Future<void> _markClientSeenOnOpen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final jobRef = FirebaseFirestore.instance.collection('jobs').doc(widget.jobId);
    final snap = await jobRef.get();
    if (!snap.exists) return;
    final data = snap.data();
    if (data == null) return;
    final clientId = data['clientId'] as String?;
    if (clientId == user.uid) {
      await jobRef.update({'clientLastSeenAt': FieldValue.serverTimestamp()});
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobRef = FirebaseFirestore.instance.collection('jobs').doc(widget.jobId);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

    final roleFuture = FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();

    return FutureBuilder<DocumentSnapshot>(
      future: roleFuture,
      builder: (context, roleSnap) {
        if (roleSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final roleData = roleSnap.data?.data() as Map<String, dynamic>?;
        final role = roleData?['role'] as String?;
        final isProvider = role == 'provider';

        return StreamBuilder<DocumentSnapshot>(
          stream: jobRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Scaffold(body: Center(child: Text('Something went wrong')));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final status = data['status'] as String? ?? 'open';
            final assignedProviderId = data['assignedProviderId'] as String?;
            final clientId = data['clientId'] as String?;
            final isAssignedToCurrentProvider = isProvider && assignedProviderId == currentUser.uid;
            final isClient = !isProvider && clientId == currentUser.uid;

            Widget? fab;
            if (isProvider) {
              if (status == 'assigned' && isAssignedToCurrentProvider) {
                fab = FloatingActionButton.extended(
                  onPressed: () => _markCompleted(jobRef),
                  label: const Text('Mark Completed'),
                  icon: const Icon(Icons.check),
                );
              } else if (status == 'open') {
                fab = _submitting
                    ? FloatingActionButton(
                        onPressed: null,
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Theme.of(context).colorScheme.onSecondary,
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                      )
                    : FloatingActionButton.extended(
                        onPressed: _showMakeOfferDialog,
                        label: const Text('Make Offer'),
                        icon: const Icon(Icons.send),
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Theme.of(context).colorScheme.onSecondary,
                      );
              }
            }

            return Scaffold(
              appBar: AppBar(
                centerTitle: true,
                title: AppLogo(),
              ),
              floatingActionButton: fab,
              body: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _jobHeader(context, data),
                          const SizedBox(height: 12),
                          _statusIndicator(data, isClient),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  // Offers (as a Sliver)
                  _offersSliver(jobRef, isProvider, data),

                  if (!isProvider && status == 'assigned')
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: _assignedInfo(data),
                      ),
                    ),

                  // Rating actions for completed jobs
                  if (status == 'completed')
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (isClient && data['providerRating'] == null)
                              ElevatedButton.icon(
                                onPressed: () => _showRatingDialog(jobRef, target: 'provider'),
                                icon: const Icon(Icons.star),
                                label: const Text('Rate provider'),
                              ),
                            if (isProvider && isAssignedToCurrentProvider && data['clientRating'] == null)
                              ElevatedButton.icon(
                                onPressed: () => _showRatingDialog(jobRef, target: 'client'),
                                icon: const Icon(Icons.star),
                                label: const Text('Rate client'),
                              ),

                            // Show existing ratings (read-only)
                            const SizedBox(height: 12),
                            if (data['providerRating'] != null)
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber),
                                  const SizedBox(width: 8),
                                  Text('Provider rating: ${data['providerRating']}'),
                                ],
                              ),
                            if (data['clientRating'] != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber),
                                  const SizedBox(width: 8),
                                  Text('Client rating: ${data['clientRating']}'),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _jobHeader(BuildContext context, Map<String, dynamic> data) {
    final loc = data['location'] as Map<String, dynamic>?;
    final double? lat = loc != null ? (loc['lat'] as num?)?.toDouble() : null;
    final double? lng = loc != null ? (loc['lng'] as num?)?.toDouble() : null;

    // Determine an icon for the category
    final rawCategory = (data['category'] ?? 'Service').toString();
    final catLower = rawCategory.toLowerCase();
    IconData categoryIcon;
    if (catLower.contains('plumb')) categoryIcon = Icons.plumbing;
    else if (catLower.contains('elect')) categoryIcon = Icons.electrical_services;
    else if (catLower.contains('clean')) categoryIcon = Icons.cleaning_services;
    else categoryIcon = Icons.handyman;

    final displayTitle = '${rawCategory[0].toUpperCase()}${rawCategory.substring(1)} needed';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon + title centered
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(categoryIcon, size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                displayTitle,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Description centered
        if ((data['description'] as String?)?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              data['description'] ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),

        const SizedBox(height: 12),

        // Urgency chip centered (rename 'Standard' -> 'Scheduled' and include preferred date if present)
        Center(
          child: Builder(builder: (context) {
            final preferred = data['preferredDate'];
            DateTime? preferredDate;
            if (preferred is Timestamp) preferredDate = preferred.toDate();
            else if (preferred is DateTime) preferredDate = preferred;

            final isUrgent = data['urgent'] == true;
            String chipLabel;
            if (isUrgent) {
              chipLabel = 'Urgent';
            } else if (preferredDate != null) {
              final pd = preferredDate;
              chipLabel = 'Scheduled · ${pd.day}/${pd.month}/${pd.year}';
            } else {
              chipLabel = 'Scheduled';
            }

            final bgColor = isUrgent ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.secondary;
            // Use onSecondary for readable text on yellow-like backgrounds
            final textColor = isUrgent ? Colors.white : Theme.of(context).colorScheme.onSecondary;

            return Chip(
              backgroundColor: bgColor,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isUrgent) Icon(Icons.calendar_today, size: 14, color: textColor),
                  if (!isUrgent) const SizedBox(width: 6),
                  Text(
                    chipLabel,
                    style: TextStyle(color: textColor, fontWeight: isUrgent ? FontWeight.bold : FontWeight.w600),
                  ),
                ],
              ),
            );
          }),
        ),

        const SizedBox(height: 12),

        if (lat != null && lng != null)
          Center(
            child: Column(
              children: [
                SizedBox(
                  height: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(lat, lng),
                        initialZoom: 15,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.brikool_mobile',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(lat, lng),
                              width: 40,
                              height: 40,
                              child: Icon(Icons.location_pin, color: Theme.of(context).colorScheme.secondary, size: 40),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _openInMaps(lat, lng),
                  icon: Icon(Icons.map, color: Theme.of(context).colorScheme.secondary),
                  label: const Text('Open in Maps'),
                ),
              ],
            ),
          )
        else if (loc != null)
          Text('Location: (${loc['lat']}, ${loc['lng']})', style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _offersSliver(DocumentReference jobRef, bool isProvider, Map<String, dynamic> jobData) {
    if (isProvider) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('Offers are hidden for providers'),
        ),
      );
    }

    final jobStatus = jobData['status'] as String? ?? 'open';
    final jobClientId = jobData['clientId'] as String?;

    return StreamBuilder<QuerySnapshot>(
      stream: jobRef.collection('offers').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: Text('Failed to load offers')));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No offers yet'),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final doc = docs[index];
              final offer = doc.data() as Map<String, dynamic>;
              final offerId = doc.id;
              final providerName = offer['providerName'] ?? 'Provider';
              final message = offer['message'] ?? '';
              final price = offer['price'] ?? '';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  child: ListTile(
                    title: Text(providerName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(message),
                        const SizedBox(height: 6),
                        Text('Price: $price MAD', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: jobStatus == 'open' && FirebaseAuth.instance.currentUser?.uid == jobClientId
                        ? ElevatedButton(
                            onPressed: () => _acceptOffer(jobRef, offerId, offer),
                            child: const Text('Accept'),
                          )
                        : null,
                  ),
                ),
              );
            },
            childCount: docs.length,
          ),
        );
      },
    );
  }

  Future<void> _showMakeOfferDialog() async {
    final priceController = TextEditingController();
    final messageController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make an offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (MAD)'),
            ),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send')),
        ],
      ),
    );

    if (result == true) {
      final priceText = priceController.text.trim();
      final message = messageController.text.trim();
      if (priceText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a price')));
        return;
      }

      final price = double.tryParse(priceText);
      if (price == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid price')));
        return;
      }

      await _submitOffer(price, message);
    }
  }

  Future<void> _submitOffer(double price, String message) async {
    setState(() => _submitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final jobRef = FirebaseFirestore.instance.collection('jobs').doc(widget.jobId);
      await jobRef.collection('offers').add({
        'providerId': user.uid,
        'providerName': user.displayName ?? 'Provider',
        'price': price,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Mark that offers were updated so the client can be notified
      await jobRef.update({'offersUpdatedAt': FieldValue.serverTimestamp()});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer sent')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send offer: $e')));
    } finally {
      setState(() => _submitting = false);
    }
  }

  Future<void> _showRatingDialog(DocumentReference jobRef, {required String target}) async {
    // target: 'provider' (client rates provider) or 'client' (provider rates client)
    int rating = 5;
    final commentController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(target == 'provider' ? 'Rate provider' : 'Rate client'),
          content: StatefulBuilder(builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final starIndex = i + 1;
                    return IconButton(
                      onPressed: () => setState(() => rating = starIndex),
                      icon: Icon(
                        starIndex <= rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                    );
                  }),
                ),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(labelText: 'Comment (optional)'),
                ),
              ],
            );
          }),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
          ],
        );
      },
    );

    if (result == true) {
      await _submitRating(jobRef, target: target, rating: rating, comment: commentController.text.trim());
    }
  }

  Future<void> _submitRating(DocumentReference jobRef, {required String target, required int rating, String? comment}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final Map<String, Object?> update = {};
      final now = FieldValue.serverTimestamp();

      if (target == 'provider') {
        update['providerRating'] = rating;
        update['providerRatingComment'] = comment;
        update['providerRatedAt'] = now;
        update['providerRatedBy'] = user.uid;
      } else {
        update['clientRating'] = rating;
        update['clientRatingComment'] = comment;
        update['clientRatedAt'] = now;
        update['clientRatedBy'] = user.uid;
      }

      await jobRef.update(update);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rating submitted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit rating: $e')));
    }
  }

  Future<void> _openInMaps(double lat, double lng) async {
    final encoded = Uri.encodeComponent('$lat,$lng');
    final googleUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');

    try {
      if (!await launchUrl(googleUrl, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open maps')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening maps: $e')));
    }
  }

  Future<void> _acceptOffer(DocumentReference jobRef, String offerId, Map<String, dynamic> offer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept offer'),
        content: const Text('Are you sure you want to accept this offer? This will assign the job to the provider.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Accept')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final providerId = offer['providerId'] as String?;
      if (providerId == null) throw Exception('Invalid provider');

      await jobRef.update({
        'status': 'assigned',
        'assignedProviderId': providerId,
        'assignedOfferId': offerId,
        'assignedProviderName': offer['providerName'] ?? null,
        'assignedPrice': offer['price'] ?? null,
        'assignedAt': FieldValue.serverTimestamp(),
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });

      await jobRef.collection('offers').doc(offerId).update({'accepted': true, 'acceptedAt': FieldValue.serverTimestamp()});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer accepted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to accept offer: $e')));
    }
  }

  Future<void> _markCompleted(DocumentReference jobRef) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as completed'),
        content: const Text('Are you sure the job is completed? This will mark the job as completed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await jobRef.update({'status': 'completed', 'completedAt': FieldValue.serverTimestamp(), 'statusUpdatedAt': FieldValue.serverTimestamp()});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job marked completed')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to mark completed: $e')));
    }
  }

  Widget _assignedInfo(Map<String, dynamic> data) {
    final providerName = data['assignedProviderName'] ?? 'Provider';
    final price = data['assignedPrice'] ?? '';
    final assignedAt = data['assignedAt'] as Timestamp?;

    String dateText = '';
    if (assignedAt != null) {
      final dt = assignedAt.toDate();
      dateText = '${dt.day}/${dt.month}/${dt.year}';
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Assigned', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Provider: $providerName'),
            const SizedBox(height: 4),
            Text('Price: $price MAD'),
            if (dateText.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Assigned: $dateText', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusIndicator(Map<String, dynamic> data, bool isClient) {
    final status = data['status'] as String? ?? 'open';

    switch (status) {
      case 'open':
        return Row(
          children: [
            Chip(
              label: Text('Waiting for offers', style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.w600)),
              avatar: const Icon(Icons.hourglass_top, color: Colors.orange),
              backgroundColor: const Color(0xFFFFF3E0),
            ),
            const SizedBox(width: 8),
            if (isClient)
              Expanded(
                child: Text(
                  'Your request is open and waiting for offers.',
                  style: const TextStyle(color: Colors.grey),
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        );
      case 'assigned':
        final providerName = data['assignedProviderName'] ?? 'Provider';
        final price = data['assignedPrice'] != null ? '${data['assignedPrice']} MAD' : '';
        return Row(
          children: [
            const Chip(
              label: Text('Assigned'),
              avatar: Icon(Icons.person, color: Colors.blue),
              backgroundColor: Color(0xFFE3F2FD),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Assigned to $providerName ${price.isNotEmpty ? '· $price' : ''}',
                softWrap: true,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case 'completed':
        final completedAt = data['completedAt'] as Timestamp?;
        String dateText = '';
        if (completedAt != null) {
          final dt = completedAt.toDate();
          dateText = '${dt.day}/${dt.month}/${dt.year}';
        }
        return Row(
          children: [
            Chip(
              label: const Text('Completed'),
              avatar: Icon(Icons.check_circle, color: Theme.of(context).colorScheme.secondary),
              backgroundColor: Theme.of(context).chipTheme.backgroundColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                dateText.isNotEmpty ? 'Completed on $dateText' : 'Completed',
                style: const TextStyle(color: Colors.grey),
                softWrap: true,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }
}
