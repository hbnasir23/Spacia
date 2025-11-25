import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import 'widgets/custom_topbar.dart';
import '../../../business/business_main_screen.dart';
import 'signup_user_screen.dart';
import 'signup_business_screen.dart';
import '../../screens/main_navigation_screen.dart';
import '../../../admin/admin_main_screen.dart';
import '../../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  bool googleLoading = false;
  bool showPassword = false;

  Future<void> _login() async {
    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    // Admin quick-login
    if (email.toLowerCase() == 'admin@spacia.com' && password == 'spacia.admin.123') {
      setState(() => loading = false);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminMainScreen()),
        );
      }
      return;
    }

    setState(() => loading = true);

    try {
      // Check if email exists in businesses collection (they don't use Firebase Auth)
      final businessQuery = await _firestore
          .collection('businesses')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (businessQuery.docs.isNotEmpty) {
        // Business user found
        final businessDoc = businessQuery.docs.first;
        final businessData = businessDoc.data();
        final storedPassword = businessData['password'] ?? '';
        final approved = businessData['approved'] ?? false;

        if (storedPassword != password) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid password')),
          );
          setState(() => loading = false);
          return;
        }

        if (!approved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your business account is pending approval'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => loading = false);
          return;
        }

        // Business login successful
        setState(() => loading = false);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BusinessMainScreen(businessId: businessDoc.id),
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Welcome back, Business Owner!'),
              backgroundColor: AppColors.darkBrown,
            ),
          );
        }
        return;
      }

      // Not a business, try regular Firebase Auth for users
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Check users collection
      final userDoc = await _firestore.collection('users').doc(uid).get();

      setState(() => loading = false);

      if (userDoc.exists) {
        final role = userDoc.data()?['role'] ?? 'consumer';

        if (mounted) {
          if (role == 'consumer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Welcome back!'),
                backgroundColor: AppColors.darkBrown,
              ),
            );
          } else if (role == 'admin') {
            // If role is admin in users collection, send to admin panel
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminMainScreen()),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User data not found')),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => loading = false);
      String message = 'Login failed';

      if (e.code == 'user-not-found') {
        message = 'No account found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Invalid password';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled';
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

  Future<void> _loginWithGoogle() async {
    setState(() {
      googleLoading = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Starting Google sign-in...')));
    try {
      final cred = await AuthService.signInWithGoogle(context);
      setState(() => googleLoading = false);
      if (cred == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google sign-in cancelled')));
        return;
      }

      final user = cred.user;
      if (user == null) return;

      final email = user.email ?? '';

      // Check businesses collection
      final businessQuery = await _firestore.collection('businesses').where('email', isEqualTo: email).limit(1).get();
      if (businessQuery.docs.isNotEmpty) {
        final doc = businessQuery.docs.first;
        final approved = doc.data()['approved'] ?? false;
        if (!approved) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Business account pending approval'), backgroundColor: Colors.orange));
          await AuthService.signOut();
          return;
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BusinessMainScreen(businessId: doc.id),
            ),
          );
        }
        return;
      }

      // Not a business: check users collection for role (AuthService created/updated it)
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final role = userDoc.data()?['role'] ?? 'consumer';
        if (mounted) {
          if (role == 'consumer') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen()));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Welcome!'), backgroundColor: AppColors.darkBrown));
          } else if (role == 'admin') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminMainScreen()));
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => googleLoading = false);
      String msg = e.message ?? 'Google Sign-in failed';
      if (e.code == 'business-not-approved') {
        msg = 'Your business account is pending approval';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    } catch (e) {
      setState(() => googleLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error during Google sign-in: $e'), backgroundColor: Colors.red));
      }
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
                  SizedBox(height: AppSizes.h(context, 0.05)),
                  const Text(
                    "Login",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  SizedBox(height: AppSizes.h(context, 0.05)),

                  // Email field
                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      labelText: "Email",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSizes.h(context, 0.03)),

                  // Password field
                  TextField(
                    controller: passCtrl,
                    obscureText: !showPassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: IconButton(
                        icon: Icon(
                          showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: AppColors.darkBrown,
                        ),
                        onPressed: () {
                          setState(() => showPassword = !showPassword);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  SizedBox(height: AppSizes.h(context, 0.05)),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkBrown,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            vertical: AppSizes.h(context, 0.018)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSizes.h(context, 0.02)),
                  // Google Sign-In button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (loading || googleLoading) ? null : _loginWithGoogle,

                  icon: googleLoading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Image.asset(
                    "assets/google_logo.png",         // <-- your google logo file
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
                    padding: EdgeInsets.symmetric(vertical: AppSizes.h(context, 0.018)),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSizes.h(context, 0.03)),

                  // Sign up links
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          "Don’t have an account?",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignUpUserScreen()),
                          ),
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              color: AppColors.darkBrown,
                            ),
                          ),
                        ),
                        const Text(
                          "Want to list your business?",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignUpBusinessScreen()),
                          ),
                          child: const Text(
                            "Sign Up as Business Owner",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
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
}
