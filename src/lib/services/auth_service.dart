import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
// import 'package:flutter/foundation.dart' show kDebugMode;
import '../utils/logger_util.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );
      return userCredential;
    } catch (e) {
      LoggerUtil.error('Error signing in', e);
      rethrow;
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'displayName': displayName.trim(),
        'email': email.trim(),
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update display name
      await userCredential.user!.updateDisplayName(displayName.trim());

      return userCredential;
    } catch (e) {
      LoggerUtil.error('Error signing up', e);
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      LoggerUtil.error('Error signing out', e);
      rethrow;
    }
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    try {
      final userData = await getUserData();
      LoggerUtil.info('Checking admin status for user data: $userData');
      return userData?['role'] == 'admin';
    } catch (e) {
      LoggerUtil.error('Error checking admin status', e);
      return false;
    }
  }

  // Create admin user (should be called only once during initial setup)
  Future<void> createAdminUser(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      // Check if admin already exists in Firestore
      final QuerySnapshot adminQuery =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'admin')
              .get();

      if (adminQuery.docs.isNotEmpty) {
        LoggerUtil.info('Admin already exists in Firestore');
        return;
      }

      UserCredential userCredential;
      try {
        // Try to create new user
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // If user exists, try to sign in
          LoggerUtil.info('Admin exists in Auth, trying to sign in...');
          userCredential = await _auth.signInWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );
        } else {
          rethrow;
        }
      }

      // Create or update admin document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'displayName': displayName.trim(),
        'email': email.trim(),
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update display name
      await userCredential.user!.updateDisplayName(displayName.trim());

      LoggerUtil.info('Admin user setup completed successfully');
    } catch (e) {
      LoggerUtil.error('Error creating admin user', e);
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      LoggerUtil.error('Error resetting password', e);
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? photoURL,
  }) async {
    try {
      if (currentUser == null) throw Exception('No user logged in');

      final Map<String, dynamic> updates = {};

      if (displayName != null) {
        updates['displayName'] = displayName.trim();
        await currentUser!.updateDisplayName(displayName.trim());
      }

      if (phoneNumber != null) {
        updates['phoneNumber'] = phoneNumber.trim();
      }

      if (photoURL != null) {
        updates['photoURL'] = photoURL;
        // Remove the Firebase Auth photoURL update since we're storing in Firestore only
      }

      if (updates.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .update(updates);
      }
    } catch (e) {
      LoggerUtil.error('Error updating profile', e);
      rethrow;
    }
  }

  // Pick and update profile picture
  Future<void> updateProfilePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);

        // Update only in Firestore
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'photoURL': base64String,
        });
      }
    } catch (e) {
      LoggerUtil.error('Error updating profile picture', e);
      rethrow;
    }
  }

  // Get user additional data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (_auth.currentUser == null) {
        LoggerUtil.warning('Cannot fetch user data: No authenticated user');
        return null;
      }

      LoggerUtil.info('Fetching user data for: ${_auth.currentUser!.uid}');

      final docSnapshot =
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .get();

      if (!docSnapshot.exists) {
        LoggerUtil.warning('No user document found in Firestore');
        return null;
      }

      final data = docSnapshot.data();
      LoggerUtil.info('User data found in Firestore: $data');
      return data;
    } catch (e) {
      LoggerUtil.error('Error in getUserData', e);
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      LoggerUtil.info('Attempting to send password reset email to: $email');

      // Validate email
      if (email.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Email cannot be empty',
        );
      }

      // Send password reset email
      await _auth.sendPasswordResetEmail(email: email);

      LoggerUtil.info('Password reset email sent successfully to: $email');
    } catch (e) {
      LoggerUtil.error('Error sending password reset email', e);
      if (e is FirebaseAuthException) {
        LoggerUtil.error('Firebase Auth Error Code: ${e.code}');
        LoggerUtil.error('Firebase Auth Error Message: ${e.message}');
      }
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(dynamic e) {
    LoggerUtil.debug('Handling auth exception: $e');

    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email. Please check your email or sign up.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-credential':
          return 'Incorrect email or password. Please try again.';
        case 'invalid-email':
          return 'The email address is invalid. Please enter a valid email.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'email-already-in-use':
          return 'This email is already registered. Please use a different email or try logging in.';
        case 'weak-password':
          return 'Password is too weak. Please use a stronger password.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection and try again.';
        case 'operation-not-allowed':
          return 'This operation is not allowed. Please contact support.';
        case 'too-many-requests':
          return 'Too many unsuccessful login attempts. Please try again later.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with the same email but different sign-in credentials.';
        default:
          // For any other Firebase Auth errors, provide a generic but friendly message
          if (e.message != null &&
              e.message.toString().contains('credential')) {
            return 'Incorrect email or password. Please try again.';
          }
          return 'Authentication error. Please try again.';
      }
    } else if (e is FirebaseException) {
      return 'Firebase error: Please try again later.';
    } else if (e is Exception) {
      return 'An error occurred. Please try again.';
    }
    return 'An error occurred. Please try again.';
  }
}
