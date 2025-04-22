import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/route.dart' as route_model;
import '../../services/route_service.dart';
import '../../services/auth_service.dart';
import '../bus_search_screen.dart';
import '../profile_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RouteService>().initialize();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BusSearchScreen(),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required IconData icon,
    required String description,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color: color ?? Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      // Home Tab
      SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to Bus Ticket Booking',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Book your journey with ease',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildDashboardCard(
              title: 'Search & Book Tickets',
              icon: Icons.search,
              description: 'Find and book bus tickets for your journey',
              onTap: _navigateToSearch,
              color: Colors.blue,
            ),
            _buildDashboardCard(
              title: 'My Bookings',
              icon: Icons.confirmation_number,
              description: 'View and manage your current bookings',
              onTap: () {
                // Navigate to bookings screen
              },
              color: Colors.green,
            ),
            _buildDashboardCard(
              title: 'Popular Routes',
              icon: Icons.route,
              description: 'Explore frequently traveled routes',
              onTap: () {
                // Navigate to routes screen
              },
              color: Colors.orange,
            ),
            _buildDashboardCard(
              title: 'Help & Support',
              icon: Icons.help_outline,
              description: 'Get assistance with your bookings',
              onTap: () {
                // Navigate to help screen
              },
              color: Colors.purple,
            ),
          ],
        ),
      ),
      // Profile Tab
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Ticket Booking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
} 