// lib/screens/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:tickiting/screens/admin/admin_buses.dart';
import 'package:tickiting/screens/admin/admin_payments.dart';
import 'package:tickiting/screens/admin/admin_users.dart';
import 'package:tickiting/screens/admin/admin_settings.dart';
import 'package:tickiting/utils/theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboardHome(),
    const AdminBuses(),
    const AdminPayments(),
    const AdminUsers(),
    const AdminSettings(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blueGrey[800],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blueGrey[800],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 30,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'admin@rwandabus.com',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(0, 'Dashboard', Icons.dashboard),
            _buildDrawerItem(1, 'Bus Management', Icons.directions_bus),
            _buildDrawerItem(2, 'Payment Management', Icons.payment),
            _buildDrawerItem(3, 'User Management', Icons.people),
            _buildDrawerItem(4, 'Settings', Icons.settings),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.pop(context); // Go back to main app
              },
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }

  Widget _buildDrawerItem(int index, String title, IconData icon) {
    return ListTile(
      leading: Icon(
        icon,
        color: _selectedIndex == index ? AppTheme.primaryColor : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _selectedIndex == index ? AppTheme.primaryColor : Colors.black,
          fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context); // Close drawer
      },
    );
  }
}

// Add the missing AdminDashboardHome class here
class AdminDashboardHome extends StatelessWidget {
  const AdminDashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Text(
            'Welcome, Admin',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Here\'s what\'s happening with your bus service today',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),
          // Stats cards
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                'Total Buses',
                '24',
                Icons.directions_bus,
                Colors.blue,
              ),
              _buildStatCard(
                'Active Routes',
                '16',
                Icons.map,
                Colors.green,
              ),
              _buildStatCard(
                'Users',
                '1,245',
                Icons.people,
                Colors.orange,
              ),
              _buildStatCard(
                'Bookings Today',
                '78',
                Icons.confirmation_number,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 30),
          // Revenue chart
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Revenue Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: _buildLineChart(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // Recent bookings
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Bookings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('See All'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return _buildBookingItem(index);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // Bus occupancy
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bus Occupancy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: _buildBarChart(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 40,
            color: color,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    // This is a placeholder for a chart
    // In a real app, you would use a charting library like fl_chart
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Text('Revenue Chart Placeholder'),
      ),
    );
  }

  Widget _buildBarChart() {
    // This is a placeholder for a chart
    // In a real app, you would use a charting library like fl_chart
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Text('Occupancy Chart Placeholder'),
      ),
    );
  }

  Widget _buildBookingItem(int index) {
    final List<Map<String, dynamic>> bookings = [
      {
        'name': 'John Doe',
        'route': 'Kigali to Butare',
        'time': '10:30 AM',
        'amount': '5,000 RWF',
        'status': 'Confirmed',
      },
      {
        'name': 'Jane Smith',
        'route': 'Kigali to Gisenyi',
        'time': '11:45 AM',
        'amount': '7,500 RWF',
        'status': 'Pending',
      },
      {
        'name': 'David Wilson',
        'route': 'Butare to Kigali',
        'time': '01:15 PM',
        'amount': '5,000 RWF',
        'status': 'Confirmed',
      },
      {
        'name': 'Sarah Johnson',
        'route': 'Kigali to Cyangugu',
        'time': '02:30 PM',
        'amount': '8,000 RWF',
        'status': 'Pending',
      },
      {
        'name': 'Michael Brown',
        'route': 'Gisenyi to Kigali',
        'time': '03:45 PM',
        'amount': '7,500 RWF',
        'status': 'Confirmed',
      },
    ];

    final booking = bookings[index];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blueGrey[100],
            child: Text(
              booking['name'].substring(0, 1),
              style: TextStyle(
                color: Colors.blueGrey[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${booking['route']} - ${booking['time']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                booking['amount'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: booking['status'] == 'Confirmed'
                      ? Colors.green[100]
                      : Colors.orange[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  booking['status'],
                  style: TextStyle(
                    color: booking['status'] == 'Confirmed'
                        ? Colors.green[700]
                        : Colors.orange[700],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}