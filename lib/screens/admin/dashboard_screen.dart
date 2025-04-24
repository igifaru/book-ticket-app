import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/booking_service.dart';
import '../../services/bus_service.dart';
import '../../services/route_service.dart';
import '../../widgets/dashboard/line_chart_widget.dart';
import '../../widgets/dashboard/pie_chart_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          
          // Statistics Cards
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                context,
                title: 'Total Bookings',
                value: '1,234',
                icon: Icons.book_online,
                color: Colors.blue,
              ),
              _buildStatCard(
                context,
                title: 'Active Routes',
                value: '45',
                icon: Icons.route,
                color: Colors.green,
              ),
              _buildStatCard(
                context,
                title: 'Available Buses',
                value: '28',
                icon: Icons.directions_bus,
                color: Colors.orange,
              ),
              _buildStatCard(
                context,
                title: 'Total Revenue',
                value: 'RWF 2.5M',
                icon: Icons.attach_money,
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Charts Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booking Trends Chart
              Expanded(
                flex: 2,
                child: Card(
                  color: Colors.grey[850],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Booking Trends',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: LineChartWidget(
                            data: [10, 25, 15, 30, 20, 35, 25],
                            labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                            title: 'Weekly Bookings',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Popular Routes Chart
              Expanded(
                child: Card(
                  color: Colors.grey[850],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Popular Routes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: PieChartWidget(
                            data: [
                              RouteData(
                                name: 'Kigali - Butare',
                                value: 35,
                                color: Colors.blue,
                              ),
                              RouteData(
                                name: 'Kigali - Gisenyi',
                                value: 25,
                                color: Colors.green,
                              ),
                              RouteData(
                                name: 'Kigali - Rwamagana',
                                value: 20,
                                color: Colors.orange,
                              ),
                              RouteData(
                                name: 'Others',
                                value: 20,
                                color: Colors.grey,
                              ),
                            ],
                            title: 'Route Distribution',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 