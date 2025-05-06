import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger_util.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'landing_page.dart';
import 'admin/admin_screen.dart';

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        LoggerUtil.info('Auth state changed: ${snapshot.data?.uid}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          LoggerUtil.info('Waiting for auth state...');
          return const Scaffold(
            backgroundColor: Color(0xFFFFAB40),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF004D40)),
            ),
          );
        }

        if (!snapshot.hasData) {
          LoggerUtil.info('No user logged in, showing landing page');
          return const LandingPage();
        }

        // User is logged in, check if admin
        return FutureBuilder<Map<String, dynamic>?>(
          future: _authService.getUserData(),
          builder: (context, userDataSnapshot) {
            LoggerUtil.info('Checking user data: ${userDataSnapshot.data}');

            if (userDataSnapshot.connectionState == ConnectionState.waiting) {
              LoggerUtil.info('Waiting for user data...');
              return const Scaffold(
                backgroundColor: Color(0xFFFFAB40),
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF004D40)),
                ),
              );
            }

            if (userDataSnapshot.hasError) {
              LoggerUtil.error(
                'Error fetching user data',
                userDataSnapshot.error,
              );
              return const HomeScreen();
            }

            final userData = userDataSnapshot.data;
            final isAdmin = userData?['role'] == 'admin';
            LoggerUtil.info(
              'User role: ${userData?['role']}, isAdmin: $isAdmin',
            );

            // Navigate based on admin status
            return isAdmin ? const AdminScreen() : const HomeScreen();
          },
        );
      },
    );
  }
}
