import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthService {
  AuthService._();
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sign in with Google and ensure Firestore user doc exists for consumers.
  /// Returns the Firebase [UserCredential] on success, or null if the user canceled.
  static Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      // Debug log
      // ignore: avoid_print
      print('[AuthService] start signInWithGoogle');
      // 1) Create a GoogleSignIn instance (local)
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: <String>['email'],
      );

      // 2) Start the sign-in flow
      GoogleSignInAccount? googleUser;
      try {
        // attempt to open Google account chooser
        // ignore: avoid_print
        print('[AuthService] calling googleSignIn.signIn()');
        googleUser = await googleSignIn.signIn();
        // ignore: avoid_print
        print('[AuthService] returned from googleSignIn.signIn(): $googleUser');
      } on PlatformException catch (e) {
        // Common: API not available on emulator, or configuration issue
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Google Sign-In failed: ${e.message ?? e.code}. Make sure the device has Google Play services and the app is configured in Firebase.'),
          backgroundColor: Colors.red,
        ));
        // ignore: avoid_print
        print('[AuthService] PlatformException during googleSignIn.signIn(): ${e.message}');
        return null;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Google Sign-In failed: $e'),
          backgroundColor: Colors.red,
        ));
        // ignore: avoid_print
        print('[AuthService] Exception during googleSignIn.signIn(): $e');
        return null;
      }

      if (googleUser == null) {
        // ignore: avoid_print
        print('[AuthService] googleUser is null -> user cancelled');
        // User aborted the sign-in
        return null;
      }

      // 3) Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth;
      try {
        googleAuth = await googleUser.authentication;
        // ignore: avoid_print
        print('[AuthService] obtained googleAuth tokens');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to obtain Google authentication tokens.'),
          backgroundColor: Colors.red,
        ));
        // ignore: avoid_print
        print('[AuthService] Exception obtaining googleAuth: $e');
        return null;
      }

      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Google Sign-In did not return tokens. Check Firebase configuration and SHA-1.'),
          backgroundColor: Colors.red,
        ));
        // ignore: avoid_print
        print('[AuthService] tokens missing: idToken=${googleAuth.idToken} accessToken=${googleAuth.accessToken}');
        return null;
      }

      // 4) Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // ignore: avoid_print
      print('[AuthService] signing in to Firebase with Google credential');
      // 5) Sign in to Firebase with the credential
      final userCred = await _auth.signInWithCredential(credential);
      // ignore: avoid_print
      print('[AuthService] firebase signInWithCredential returned: user=${userCred.user}');
      final user = userCred.user;
      if (user == null) return userCred;

      // --- FIRESTORE LOGIC ---
      final email = user.email ?? '';

      // Check businesses collection for this email
      final businessQuery = await _firestore.collection('businesses').where('email', isEqualTo: email).limit(1).get();
      if (businessQuery.docs.isNotEmpty) {
        final doc = businessQuery.docs.first;
        final data = doc.data();
        final approved = data['approved'] ?? false;

        if (!approved) {
          // Not approved yet: sign out and surface an error via FirebaseAuthException
          await signOut();
          throw FirebaseAuthException(code: 'business-not-approved', message: 'Business account pending approval');
        }

        // Approved business -> return credential; UI caller will route to business screen
        return userCred;
      }

      // Consumer: ensure users collection has a doc
      final userRef = _firestore.collection('users').doc(user.uid);
      final snapshot = await userRef.get();

      if (!snapshot.exists) {
        await userRef.set({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'role': 'consumer',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await userRef.update({
          'name': user.displayName ?? snapshot.data()?['name'] ?? '',
          'photoUrl': user.photoURL ?? snapshot.data()?['photoUrl'] ?? '',
          'email': user.email ?? snapshot.data()?['email'] ?? '',
        });
      }

      return userCred;
    } on FirebaseAuthException {
      // Let callers handle FirebaseAuthException (for business-not-approved etc.)
      rethrow;
    } catch (e) {
      // Unexpected error: show feedback and rethrow
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Unexpected sign-in error: $e'),
        backgroundColor: Colors.red,
      ));
      rethrow;
    }
  }

  /// Sign out from Firebase and Google (if signed in)
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {}
  }
}