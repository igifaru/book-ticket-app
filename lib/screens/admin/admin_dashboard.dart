import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card
            Card(
              color: Theme.of(context).primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Welcome, Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Manage your bus booking system',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Management Options
            _buildAdminOption(
              context,
              title: 'Manage Routes',
              icon: Icons.route,
              color: Colors.blue,
              description: 'Add, edit, or remove bus routes',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageRoutesScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildAdminOption(
              context,
              title: 'Manage Buses',
              icon: Icons.directions_bus,
              color: Colors.green,
              description: 'Add, edit, or remove buses',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageBusesScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildAdminOption(
              context,
              title: 'View Bookings',
              icon: Icons.book_online,
              color: Colors.orange,
              description: 'View and manage bookings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ViewBookingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bar_chart, color: Colors.purple),
              ),
              title: const Text('Reports'),
              subtitle: const Text('View booking and revenue reports'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
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
