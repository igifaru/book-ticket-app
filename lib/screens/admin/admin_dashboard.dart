import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/bus_service.dart';
import '../../services/booking_service.dart';
import '../../services/route_service.dart';
import '../../services/settings_service.dart';
import '../../models/bus.dart';
import '../../models/booking.dart';
import 'settings_screen.dart';
import 'dashboard_screen.dart';
import 'users_screen.dart';
import 'buses_screen.dart';
import 'routes_screen.dart';
import 'bookings_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Get services
    final authService = context.watch<AuthService>();
    final routeService = context.watch<RouteService>();
    final busService = context.watch<BusService>();
    final bookingService = context.watch<BookingService>();
    final settingsService = context.watch<SettingsService>();

    // Check if any service is not initialized
    final bool allServicesInitialized = authService.isInitialized &&
        routeService.isInitialized &&
        busService.isInitialized &&
        bookingService.isInitialized &&
        settingsService.isInitialized;

    if (!allServicesInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final List<Widget> screens = [
      const DashboardScreen(),
      const UsersScreen(),
      const BusesScreen(),
      const RoutesScreen(),
      const BookingsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && mounted) {
                await context.read<AuthService>().logout();
              }
            },
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_bus),
            label: 'Buses',
          ),
          NavigationDestination(
            icon: Icon(Icons.route),
            label: 'Routes',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_online),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
