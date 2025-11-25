import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import 'widgets/custom_topbar.dart';
import '../../../services/auth_service.dart';
import '../consumer/screens/main_navigation_screen.dart';
import '../../../admin/admin_main_screen.dart';
import '../../../business/business_main_screen.dart';

class SignUpUserScreen extends StatefulWidget {
  const SignUpUserScreen({super.key});

  @override
  State<SignUpUserScreen> createState() => _SignUpUserScreenState();
}

class _SignUpUserScreenState extends State<SignUpUserScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  bool loading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  Future<void> _signUp() async {
    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();
    final confirmPassword = confirmPassCtrl.text.trim();

    // Validation
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    // Prevent registering with reserved admin email
    if (email.toLowerCase() == 'admin@spacia.com') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This email is reserved and cannot be used')),
      );
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
              content: Text('This email is already registered as a business account'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Create Firebase Auth user
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save to Firestore users collection
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'name': name,
        'email': email,
        'role': 'consumer',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => loading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signup successful! Please login.'),
            backgroundColor: Colors.green,
          ),
        );

        // Return to Login screen (caller pushed this screen)
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => loading = false);
      String message = 'Signup failed';

      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
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

  Future<void> _googleSignUp() async {
    setState(() => loading = true);
    try {
      final cred = await AuthService.signInWithGoogle(context);
      setState(() => loading = false);
      if (cred == null) return; // cancelled
      final user = cred.user;
      if (user == null) return;

      // After successful Google sign-in, route same as login
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final role = userDoc.data()?['role'] ?? 'consumer';
        if (mounted) {
          if (role == 'consumer') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen()));
          } else if (role == 'admin') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminMainScreen()));
          }
        }
      } else {
        // AuthService should have created the user doc; if not, create minimally
        await _firestore.collection('users').doc(user.uid).set({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'role': 'consumer',
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen()));
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Google sign-in failed'), backgroundColor: Colors.red));
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
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.w(context, 0.08),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSizes.h(context, 0.05)),
                  const Text(
                    "Sign Up",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  SizedBox(height: AppSizes.h(context, 0.05)),

                  // Full Name
                  _inputField("Full Name", nameCtrl),
                  SizedBox(height: AppSizes.h(context, 0.03)),

                  // Email
                  _inputField("Email", emailCtrl),
                  SizedBox(height: AppSizes.h(context, 0.03)),

                  // Password
                  _passwordField(
                    "Password",
                    passCtrl,
                    showPassword,
                        () => setState(() => showPassword = !showPassword),
                  ),
                  SizedBox(height: AppSizes.h(context, 0.03)),

                  // Confirm Password
                  _passwordField(
                    "Confirm Password",
                    confirmPassCtrl,
                    showConfirmPassword,
                        () => setState(() =>
                    showConfirmPassword = !showConfirmPassword),
                  ),
                  SizedBox(height: AppSizes.h(context, 0.05)),

                  // Sign Up button
                  _mainButton("Sign Up", _signUp, loading),
                  SizedBox(height: AppSizes.h(context, 0.02)),
                  // Google Sign-Up
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: loading ? null : _googleSignUp,

                  icon: Image.asset(
                    "assets/google_logo.png",   // <-- your custom logo file
                    width: 22,
                    height: 22,
                  ),

                  label: const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: AppSizes.h(context, 0.018),
                    ),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              SizedBox(height: AppSizes.h(context, 0.04)),

                  // Already have an account?
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
