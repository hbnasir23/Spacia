import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../constants/app_colors.dart';
import '../../../auth/login_screen.dart';

class BusinessProfileScreen extends StatefulWidget {
  final String businessId;

  const BusinessProfileScreen({super.key, required this.businessId});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? _businessData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  Future<void> _loadBusinessData() async {
    try {
      final doc = await _firestore.collection('businesses').doc(widget.businessId).get();
      if (doc.exists) {
        final data = doc.data();
        // Convert all fields to strings to avoid type errors
        setState(() {
          _businessData = {
            'businessName': data?['businessName']?.toString() ?? '',
            'ownerName': data?['ownerName']?.toString() ?? '',
            'email': data?['email']?.toString() ?? data?['businessEmail']?.toString() ?? '',
            'businessEmail': data?['businessEmail']?.toString() ?? data?['email']?.toString() ?? '',
            'businessPhone': data?['businessPhone']?.toString() ?? '',
            'businessAddress': data?['businessAddress']?.toString() ?? data?['address']?.toString() ?? '',
            'address': data?['address']?.toString() ?? data?['businessAddress']?.toString() ?? '',
          };
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editField(String field, String label) async {
    final controller = TextEditingController(text: _businessData?[field] ?? '');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit $label', style: const TextStyle(fontFamily: 'Poppins')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: label),
          maxLines: field == 'businessAddress' ? 3 : 1,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkBrown),
            onPressed: () async {
              await _firestore.collection('businesses').doc(widget.businessId).update({field: controller.text.trim()});
              setState(() => _businessData?[field] = controller.text.trim());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Updated successfully!'), backgroundColor: AppColors.darkBrown),
              );
            },
            child: const Text('Save',  style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout', style: TextStyle(fontFamily: 'Poppins')),
        content: const Text('Are you sure you want to logout?', style: TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBrown,
      appBar: AppBar(
        backgroundColor: AppColors.darkBrown,
        title: const Text('Business Profile', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.darkBrown))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.darkBrown,
                          child: Icon(Icons.business, size: 50, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _businessData?['businessName'] ?? 'Business',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkBrown),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _businessData?['businessEmail'] ?? '',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildInfoCard('Business Name', _businessData?['businessName'] ?? 'Not set', 'businessName'),
                  const SizedBox(height: 12),
                  _buildInfoCard('Email', _businessData?['businessEmail'] ?? 'Not set', null, editable: false),
                  const SizedBox(height: 12),
                  _buildInfoCard('Phone', _businessData?['businessPhone'] ?? 'Not set', 'businessPhone'),
                  const SizedBox(height: 12),
                  _buildInfoCard('Address', _businessData?['businessAddress'] ?? 'Not set', 'businessAddress'),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(String label, String value, String? field, {bool editable = true}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (editable && field != null)
            IconButton(
              onPressed: () => _editField(field, label),
              icon: const Icon(Icons.edit, color: AppColors.darkBrown, size: 20),
            ),
        ],
      ),
    );
  }
}

