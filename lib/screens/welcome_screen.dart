// In lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:tickiting/screens/auth/login_screen.dart';
import 'package:tickiting/utils/theme.dart';
import 'dart:async';
import 'package:tickiting/utils/admin_login_dialog.dart'; // Import the admin login helper

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // Counter for logo taps
  int _logoTapCount = 0;

  // Timer to reset tap count if user doesn't tap quickly enough
  Timer? _tapTimer;

  void _handleLogoTap() {
    // Increment the tap counter
    setState(() {
      _logoTapCount++;
    });

    // Cancel existing timer
    _tapTimer?.cancel();

    // Set new timer to reset the counter after 2 seconds of inactivity
    _tapTimer = Timer(const Duration(seconds: 2), () {
      setState(() {
        _logoTapCount = 0;
      });
    });

    // If tapped 5 times, show admin login dialog
    if (_logoTapCount == 5) {
      setState(() {
        _logoTapCount = 0;
      });
      _tapTimer?.cancel();

      // Show admin login dialog
      handleAdminAccess(context);
    }
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo - now with tap detection
            GestureDetector(
              onTap: _handleLogoTap,
              child: Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(75),
                ),
                child: const Icon(
                  Icons.directions_bus,
                  size: 100,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // App name
            const Text(
              'Rwanda Bus Ticket',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Book your bus tickets easily and quickly',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 60),
            // Get Started button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Create account button
          ],
        ),
      ),
    );
  }
}
