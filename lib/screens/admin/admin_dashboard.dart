import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/bus_service.dart';
import '../../services/booking_service.dart';
import '../../models/bus.dart';
import '../../models/booking.dart';
import '../login_screen.dart';
import 'add_bus_screen.dart';
import 'route_list_screen.dart';
import 'manage_routes_screen.dart';
import 'manage_buses_screen.dart';
import 'view_bookings_screen.dart';
import 'reports_screen.dart';
import 'manage_users_screen.dart';
import 'manage_payments_screen.dart';
import 'package:bus_ticket_booking/widgets/dashboard/stat_card.dart';
import 'package:bus_ticket_booking/widgets/dashboard/line_chart_widget.dart';
import 'package:bus_ticket_booking/widgets/dashboard/pie_chart_widget.dart';
import 'package:bus_ticket_booking/widgets/dashboard/bar_chart_widget.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2D),
      body: Row(
        children: [
          // Left Sidebar
          Container(
            width: 250,
            color: const Color(0xFF1A1A27),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Logo
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.directions_bus,
                        color: Colors.teal[400],
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'BusGo Admin',
                        style: TextStyle(
                          color: Colors.teal[400],
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Menu Items
                _buildMenuItem(Icons.dashboard, 'Dashboard', true),
                _buildMenuItem(Icons.event, 'Events', false),
                _buildMenuItem(Icons.person, 'Customers', false),
                _buildMenuItem(Icons.confirmation_number, 'Tickets', false),
                _buildMenuItem(Icons.settings, 'Settings', false),
                const Spacer(),
                // Get Summary Button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[400],
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.summarize, color: Colors.white),
                    label: const Text(
                      'Get Summary Report',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A27),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search here...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            filled: true,
                            fillColor: const Color(0xFF1E1E2D),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        color: Colors.grey[400],
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.teal[400],
                        child: const Text('A'),
                      ),
                    ],
                  ),
                ),
                // Dashboard Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Row
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: StatCard(
                                title: 'Ticket Sold Today',
                                value: '456,502',
                                growth: 4.5,
                                chartData: [0.3, 0.5, 0.4, 0.7, 0.6, 0.8, 0.9],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Container(
                                height: 200,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A27),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const PieChartWidget(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Sales Revenue Chart
                        Container(
                          height: 300,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A27),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Sales Revenue',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  DropdownButton<String>(
                                    value: '2020',
                                    dropdownColor: const Color(0xFF1A1A27),
                                    style: const TextStyle(color: Colors.white),
                                    items: ['2020', '2021', '2022']
                                        .map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    onChanged: (_) {},
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              const Expanded(child: LineChartWidget()),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Recent Activity
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A27),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Recent Event List',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildEventListItem(
                                      'The Story of Danau Toba',
                                      'Medan, Indonesia',
                                      '24 June 2023',
                                      '\$150.95',
                                    ),
                                    _buildEventListItem(
                                      'India Band Festivals Jakarta 2020',
                                      'Jakarta, Indonesia',
                                      '24 June 2023',
                                      '\$165.95',
                                    ),
                                    _buildEventListItem(
                                      'International Jazz Festival 2020',
                                      'Sydney, Australia',
                                      '24 June 2023',
                                      '\$185.95',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A27),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const BarChartWidget(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.teal.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.teal[400] : Colors.grey[400],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.teal[400] : Colors.grey[400],
          ),
        ),
        selected: isSelected,
        onTap: () {},
      ),
    );
  }

  Widget _buildEventListItem(
    String title,
    String location,
    String date,
    String price,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.event,
              color: Colors.teal[400],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: TextStyle(
                  color: Colors.teal[400],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BusManagement extends StatefulWidget {
  const _BusManagement();

  @override
  State<_BusManagement> createState() => _BusManagementState();
}

class _BusManagementState extends State<_BusManagement> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Bus>>(
      future: context.read<BusService>().getAllBuses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final buses = snapshot.data ?? [];
        if (buses.isEmpty) {
          return const Center(child: Text('No buses found'));
        }

        return ListView.builder(
          itemCount: buses.length,
          itemBuilder: (context, index) {
            final bus = buses[index];
            return ListTile(
              title: Text(bus.busName),
              subtitle: Text(bus.departureTime),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // TODO: Implement edit functionality
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Delete Bus'),
                              content: Text(
                                'Are you sure you want to delete ${bus.busName}?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                      );
                      if (confirmed == true) {
                        await _deleteBus(bus);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteBus(Bus bus) async {
    try {
      await context.read<BusService>().deleteBus(bus.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bus deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting bus: $e')));
      }
    }
  }
}

class _BookingManagement extends StatelessWidget {
  const _BookingManagement();

  Future<void> _confirmBooking(BuildContext context, Booking booking) async {
    try {
      final bookingService = context.read<BookingService>();
      final success = await bookingService.updateBookingStatus(
        booking.id!,
        'confirmed',
      );
      if (success != null && success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking confirmed successfully')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to confirm booking')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error confirming booking: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Booking>>(
      future: context.read<BookingService>().getAllBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return const Center(child: Text('No bookings found'));
        }

        return ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text('Booking #${booking.id}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('From: ${booking.fromLocation}'),
                    Text('To: ${booking.toLocation}'),
                    Text('Seats: ${booking.numberOfSeats}'),
                    Text('Status: ${booking.status}'),
                    Text('Amount: RWF ${booking.totalAmount}'),
                  ],
                ),
                trailing:
                    booking.status == 'pending'
                        ? TextButton(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Confirm Booking'),
                                    content: const Text(
                                      'Are you sure you want to confirm this booking?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        child: const Text('Confirm'),
                                      ),
                                    ],
                                  ),
                            );
                            if (confirmed == true) {
                              await _confirmBooking(context, booking);
                            }
                          },
                          child: const Text('Confirm'),
                        )
                        : null,
              ),
            );
          },
        );
      },
    );
  }
}
