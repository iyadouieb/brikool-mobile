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
    'Electrician',
    'Plumber',
    'Painter',
    'Carpenter',
    'HVAC',
    'Other',
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
        // Allow back navigation when opened for editing
        automaticallyImplyLeading: widget.isEdit,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: 'First name'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: 'Last name'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),

              if (widget.role == 'provider') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedTrade,
                  items: trades
                      .map(
                        (trade) => DropdownMenuItem(
                          value: trade,
                          child: Text(trade),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedTrade = value);
                  },
                  decoration: const InputDecoration(labelText: 'Trade'),
                  validator: (v) => v == null ? 'Required' : null,
                ),
              ],

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
