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
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 24),
          
          // Statistics Cards
          LayoutBuilder(
            builder: (context, constraints) {
              return constraints.maxWidth < 600
                  ? Column(
                      children: _buildStatCards(context),
                    )
                  : Row(
                      children: _buildStatCards(context)
                          .map((card) => Expanded(child: card))
                          .toList(),
                    );
            },
          ),
          const SizedBox(height: 24),
          
          // Charts Section
          LayoutBuilder(
            builder: (context, constraints) {
              return constraints.maxWidth < 900
                  ? Column(
                      children: [
                        _buildBookingTrendsChart(context),
                        const SizedBox(height: 16),
                        _buildPopularRoutesChart(context),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildBookingTrendsChart(context),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildPopularRoutesChart(context),
                        ),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStatCards(BuildContext context) {
    return [
      Padding(
        padding: const EdgeInsets.all(8),
        child: _buildStatCard(
          context,
          title: 'Total Bookings',
          value: '1,234',
          icon: Icons.book_online,
          color: Colors.blue.shade400,
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8),
        child: _buildStatCard(
          context,
          title: 'Active Routes',
          value: '45',
          icon: Icons.route,
          color: Colors.green.shade400,
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8),
        child: _buildStatCard(
          context,
          title: 'Available Buses',
          value: '28',
          icon: Icons.directions_bus,
          color: Colors.orange.shade400,
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8),
        child: _buildStatCard(
          context,
          title: 'Total Revenue',
          value: 'RWF 2.5M',
          icon: Icons.attach_money,
          color: Colors.purple.shade400,
        ),
      ),
    ];
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      color: Colors.grey[900],
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
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingTrendsChart(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Trends',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: LineChartWidget(
                data: [15, 25, 18, 35, 22, 38, 25],
                labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                title: 'Weekly Bookings',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularRoutesChart(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Popular Routes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: PieChartWidget(
                data: const [35, 25, 20, 20],
                labels: const [
                  'Kigali - Butare',
                  'Kigali - Gisenyi',
                  'Kigali - Rwamagana',
                  'Others'
                ],
                title: 'Route Distribution',
              ),
            ),
          ],
        ),
      ),
    );
  }
} 