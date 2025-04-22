import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'admin/admin_dashboard.dart';
import 'user/user_dashboard.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _logoTapCount = 0;

  void _handleLogoTap() {
    setState(() {
      _logoTapCount++;
      if (_logoTapCount >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debug mode activated')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (!authService.isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authService.currentUser == null) {
          return const LoginScreen();
        }

        if (authService.currentUser!.role == 'admin') {
          return const AdminDashboard();
        }

        return const UserDashboard();
      },
    );
  }
} 