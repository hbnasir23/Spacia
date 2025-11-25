import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import 'widgets/custom_topbar.dart';
import 'login_screen.dart';
import '../../../business/business_main_screen.dart';
import '../../../services/auth_service.dart';

class SignUpBusinessScreen extends StatefulWidget {
  const SignUpBusinessScreen({super.key});

  @override
  State<SignUpBusinessScreen> createState() => _SignUpBusinessScreenState();
}

class _SignUpBusinessScreenState extends State<SignUpBusinessScreen> {
  final _firestore = FirebaseFirestore.instance;

  final businessNameCtrl = TextEditingController();
  final ownerNameCtrl = TextEditingController();
  final businessEmailCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  bool loading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  Future<void> _requestListing() async {
    final businessName = businessNameCtrl.text.trim();
    final ownerName = ownerNameCtrl.text.trim();
    final email = businessEmailCtrl.text.trim();
    final address = addressCtrl.text.trim();
    final password = passwordCtrl.text.trim();
    final confirmPassword = confirmPasswordCtrl.text.trim();

    // Validation
    if (businessName.isEmpty || ownerName.isEmpty || email.isEmpty ||
        address.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (email.toLowerCase() == 'admin@spacia.com') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This email is reserved and cannot be used')));
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // Check if email already exists in users collection
      final usersSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (usersSnapshot.docs.isNotEmpty) {
        setState(() => loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This email is already registered as a user account'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check if email already exists in businesses collection
      final businessQuery = await _firestore
          .collection('businesses')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (businessQuery.docs.isNotEmpty) {
        setState(() => loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This email is already registered'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Create business account
      await _firestore.collection('businesses').add({
        'businessName': businessName,
        'ownerName': ownerName,
        'email': email, // Use 'email' field for consistency
        'businessEmail': email, // Keep for backward compatibility
        'businessAddress': address,
        'address': address, // Keep for backward compatibility
        'businessPhone': '', // Optional field
        'password': password,
        'approved': false, // Needs admin approval
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => loading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business registration submitted! Awaiting admin approval.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        // Return to login (caller screen)
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _googleSignUpBusiness() async {
    setState(() => loading = true);
    try {
      final cred = await AuthService.signInWithGoogle(context);
      setState(() => loading = false);
      if (cred == null) return;
      final user = cred.user;
      if (user == null) return;

      final email = user.email ?? '';
      final businessQuery = await _firestore.collection('businesses').where('email', isEqualTo: email).limit(1).get();
      if (businessQuery.docs.isNotEmpty) {
        final doc = businessQuery.docs.first;
        final approved = doc.data()['approved'] ?? false;
        if (!approved) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your business account is pending approval'), backgroundColor: Colors.orange));
          await AuthService.signOut();
          return;
        }
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BusinessMainScreen(businessId: doc.id)));
        }
        return;
      }

      // No matching business found — sign out and inform user
      await AuthService.signOut();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No business found for this Google account. Please request listing using the form.'), backgroundColor: Colors.orange));
    } catch (e) {
      setState(() => loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBrown,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomTopBar(title: "Spacia"),
          Expanded(
            child: SingleChildScrollView(
              padding:
              EdgeInsets.symmetric(horizontal: AppSizes.w(context, 0.08)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSizes.h(context, 0.025)),
                  const Text(
                    "Business Registration",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  SizedBox(height: AppSizes.h(context, 0.03)),
                  _inputField("Business Name", businessNameCtrl),
                  SizedBox(height: AppSizes.h(context, 0.03)),
                  _inputField("Owner Name", ownerNameCtrl),
                  SizedBox(height: AppSizes.h(context, 0.03)),
                  _inputField("Business Email", businessEmailCtrl),
                  SizedBox(height: AppSizes.h(context, 0.03)),
                  _inputField("Business Address", addressCtrl),
                  SizedBox(height: AppSizes.h(context, 0.03)),

                  // Password
                  _passwordField("Password", passwordCtrl, showPassword,
                          () => setState(() => showPassword = !showPassword)),
                  SizedBox(height: AppSizes.h(context, 0.03)),

                  // Confirm Password
                  _passwordField(
                      "Confirm Password",
                      confirmPasswordCtrl,
                      showConfirmPassword,
                          () => setState(
                              () => showConfirmPassword = !showConfirmPassword)),

                  SizedBox(height: AppSizes.h(context, 0.05)),
                  _mainButton("Request for Listing", _requestListing, loading),
                  SizedBox(height: AppSizes.h(context, 0.02)),
                  // Google Sign-In for business
                  // SizedBox(
                  //   width: double.infinity,
                  //   child: OutlinedButton.icon(
                  //     onPressed: loading ? null : _googleSignUpBusiness,
                  //     icon: const Icon(Icons.login, color: Colors.red),
                  //     label: const Text('Continue with Google', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                  //     style: OutlinedButton.styleFrom(
                  //       padding: EdgeInsets.symmetric(vertical: AppSizes.h(context, 0.018)),
                  //       backgroundColor: Colors.white,
                  //       side: const BorderSide(color: Colors.grey),
                  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  //     ),
                  //   ),
                  // ),
                  // SizedBox(height: AppSizes.h(context, 0.04)),
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          "Already have an account?",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkBrown,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _passwordField(String label, TextEditingController ctrl, bool visible,
      VoidCallback toggleVisibility) {
    return TextField(
      controller: ctrl,
      obscureText: !visible,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Icons.visibility : Icons.visibility_off,
            color: AppColors.darkBrown,
          ),
          onPressed: toggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _mainButton(String text, Function() onTap, bool loading) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkBrown,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: AppSizes.h(context, 0.018)),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}
