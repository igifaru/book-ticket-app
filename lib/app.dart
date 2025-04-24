import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/user/user_dashboard.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Ticket App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: Consumer<AuthService>(
        builder: (context, authService, _) {
          if (!authService.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!authService.isAuthenticated) {
            return const LoginScreen();
          }

          return FutureBuilder<bool>(
            future: authService.isAdmin(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final isAdmin = snapshot.data ?? false;
              return isAdmin ? const AdminDashboard() : const UserDashboard();
            },
          );
        },
      ),
    );
  }
} 