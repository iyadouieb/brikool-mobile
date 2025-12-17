import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class JobRequestScreen extends StatefulWidget {
  final String category;

  const JobRequestScreen({super.key, required this.category});

  @override
  State<JobRequestScreen> createState() => _JobRequestScreenState();
}

class _JobRequestScreenState extends State<JobRequestScreen> {
  final TextEditingController descriptionController =
      TextEditingController();

  String? address;
  DateTime? selectedDate;
  bool urgent = false;
  bool loadingLocation = true;
  LatLng? selectedLocation;

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  Future<void> _detectLocation() async {
    try {
      debugPrint('Checking permission...');
      LocationPermission permission =
          await Geolocator.checkPermission();

      debugPrint('Permission: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('Requested permission: $permission');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permission denied forever');
      }

      debugPrint('Getting position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      debugPrint(
          'Position: ${position.latitude}, ${position.longitude}');     

      setState(() {
        selectedLocation = LatLng(
          position.latitude,
          position.longitude,
        );
        loadingLocation = false;
      });
    } catch (e) {
      debugPrint('LOCATION ERROR: $e');
      setState(() {
        address = 'Unable to detect location';
        loadingLocation = false;
      });
    }
  }


  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  void _submitRequest() {
    if (descriptionController.text.trim().isEmpty) {
      _showMessage('Please describe the job');
      return;
    }

    if (!urgent && selectedDate == null) {
      _showMessage('Please select a date or mark as urgent');
      return;
    }

    if (address == null) {
      _showMessage('Location required');
      return;
    }

    _showMessage('Searching for nearby professionals...');
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
      ),

      // 🔘 FIXED BUTTON
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _submitRequest,
            child: const Text('Find a pro'),
          ),
        ),
      ),

      body: loadingLocation
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📍 Location
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      SizedBox(
                        height: 180,
                        child: selectedLocation == null
                            ? const Center(child: CircularProgressIndicator())
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: FlutterMap(
                                  options: MapOptions(
                                    initialCenter: selectedLocation!,
                                    initialZoom: 15,
                                    onTap: (tapPosition, point) {
                                      setState(() {
                                        selectedLocation = point;
                                      });
                                    },
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName:
                                          'com.example.brikool_mobile',
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: selectedLocation!,
                                          width: 40,
                                          height: 40,
                                          child: const Icon(
                                            Icons.location_pin,
                                            color: Colors.red,
                                            size: 40,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                      ),

                      const SizedBox(height: 8),
                      const Text(
                        'Tap on the map to adjust your location',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Description
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Describe the job',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Photos (placeholder)
                  OutlinedButton.icon(
                    onPressed: () {
                      _showMessage('Photo upload coming soon');
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Add photos'),
                  ),

                  const SizedBox(height: 24),

                  // Urgent switch
                  SwitchListTile(
                    title: const Text('Urgent'),
                    subtitle: const Text(
                        'A pro will come as soon as possible'),
                    value: urgent,
                    onChanged: (value) {
                      setState(() {
                        urgent = value;
                        if (urgent) selectedDate = null;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Date picker
                  GestureDetector(
                    onTap: urgent ? null : pickDate,
                    child: AbsorbPointer(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Preferred date',
                          border: const OutlineInputBorder(),
                          filled: urgent,
                          fillColor: urgent
                              ? Colors.grey.shade300
                              : null,
                          hintText: selectedDate == null
                              ? 'Select a date'
                              : selectedDate!
                                  .toLocal()
                                  .toString()
                                  .split(' ')[0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

}
