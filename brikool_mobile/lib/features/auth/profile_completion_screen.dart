import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/app_logo.dart';

class ProfileCompletionScreen extends StatefulWidget {
  final String role;
  final bool isEdit;

  const ProfileCompletionScreen({
    super.key,
    required this.role,
    this.isEdit = false,
  });

  

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {

  String? selectedTrade;

  final trades = [
    {
      'name': 'Electrician',
      'icon': Icons.electrical_services,
      'desc': 'Handles electrical wiring, lighting, and power systems.'
    },
    {
      'name': 'Plumber',
      'icon': Icons.plumbing,
      'desc': 'Installs and repairs water, gas, and drainage systems.'
    },
    {
      'name': 'Painter',
      'icon': Icons.format_paint,
      'desc': 'Paints and finishes walls, ceilings, and surfaces.'
    },
    {
      'name': 'Carpenter',
      'icon': Icons.handyman,
      'desc': 'Works with wood, builds furniture, and structures.'
    },
    {
      'name': 'HVAC',
      'icon': Icons.ac_unit,
      'desc': 'Installs and maintains heating, ventilation, and air conditioning.'
    },
    {
      'name': 'Other',
      'icon': Icons.build,
      'desc': 'Other trade or service not listed.'
    },
  ];
  final _formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final tradeController = TextEditingController();

  bool _isSaving = false;

  

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    tradeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final data = {
      'firstName': firstNameController.text.trim(),
      'lastName': lastNameController.text.trim(),
      'phone': phoneController.text.trim(),
      'profileCompleted': true,
    };

    if (widget.role == 'provider') {
      data['trade'] = selectedTrade as Object;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update(data);

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: AppLogo(),
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
        automaticallyImplyLeading: widget.isEdit,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Text(
                    widget.role == 'provider'
                        ? 'Complete your profile to start offering your services and connect with clients.'
                        : 'Complete your profile to find and hire professionals for your needs.',
                    style: const TextStyle(fontSize: 17, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: firstNameController,
                          decoration: InputDecoration(
                            labelText: 'First name',
                            filled: true,
                            fillColor: Colors.grey.shade800,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: lastNameController,
                          decoration: InputDecoration(
                            labelText: 'Last name',
                            filled: true,
                            fillColor: Colors.grey.shade800,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone',
                            filled: true,
                            fillColor: Colors.grey.shade800,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        if (widget.role == 'provider') ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedTrade,
                            items: trades
                                .map((trade) => DropdownMenuItem(
                                      value: trade['name'] as String,
                                      child: Row(
                                        children: [
                                          Icon(trade['icon'] as IconData, color: Colors.white, size: 24),
                                          const SizedBox(width: 12),
                                          Text(trade['name'] as String),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => selectedTrade = value);
                            },
                            decoration: InputDecoration(
                              labelText: 'Trade',
                              filled: true,
                              fillColor: Colors.grey.shade800,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                          if (selectedTrade != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  trades.firstWhere((t) => t['name'] == selectedTrade)['desc'] as String,
                                  style: const TextStyle(fontSize: 15, color: Colors.white70),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                                        )
                                      : const Text('Continue'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final uid = FirebaseAuth.instance.currentUser?.uid;
                                  if (uid != null) {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(uid)
                                        .update({'role': null});
                                  }
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                label: const Text('Back', style: TextStyle(color: Colors.white)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
