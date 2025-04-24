import 'package:flutter/material.dart';
import '../../widgets/dashboard/stat_card.dart';
import '../../widgets/dashboard/line_chart_widget.dart';
import '../../widgets/dashboard/pie_chart_widget.dart';
import '../../widgets/dashboard/bar_chart_widget.dart';

class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, Admin',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Bookings',
                  value: '1,234',
                  growth: 12.5,
                  icon: Icons.confirmation_number,
                  chartData: [4.0, 3.5, 4.5, 5.0, 3.8, 4.2, 5.5],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Revenue',
                  value: '\$12,345',
                  growth: 8.2,
                  icon: Icons.attach_money,
                  chartData: [2.4, 2.8, 3.2, 3.8, 3.5, 4.0, 4.5],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Active Routes',
                  value: '45',
                  growth: -2.3,
                  icon: Icons.route,
                  chartData: [5.0, 4.8, 4.5, 4.2, 4.0, 3.8, 3.5],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Charts Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  height: 400,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A27),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Revenue Overview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: LineChartWidget(
                          title: 'Monthly Revenue',
                          data: [45000, 42000, 50000, 48000, 55000, 60000, 58000],
                          labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Container(
                  height: 400,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A27),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Popular Routes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: PieChartWidget(
                          title: 'Route Distribution',
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
                              name: 'Kigali - Musanze',
                              value: 20,
                              color: Colors.orange,
                            ),
                            RouteData(
                              name: 'Others',
                              value: 20,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ],
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