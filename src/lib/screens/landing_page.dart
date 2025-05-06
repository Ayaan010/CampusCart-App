import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'login_screen.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFAB40), // Orange background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Cart illustration
            Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset(
                'assets/images/campuscart.png',
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 1),
            // App tagline
            const Column(
              children: [
                Text(
                  'No Queues, No',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF004D40),
                    height: 1.2,
                  ),
                ),
                Text(
                  'Hassle',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color.fromARGB(255, 0, 77, 64),
                    height: 1.2,
                  ),
                ),
                Text(
                  'Just Pick Up!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF004D40),
                    height: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            // Login button
            SizedBox(
              width: 160,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004D40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Sign in',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Sign up button
            SizedBox(
              width: 160,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBE9E7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Sign up',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF004D40),
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
