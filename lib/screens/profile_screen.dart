import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../models/user.dart';
import '../models/booking.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  User? _user;
  List<Booking> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final bookingService = Provider.of<BookingService>(context, listen: false);

      final user = await authService.getCurrentUser();
      if (user != null) {
        final bookings = await bookingService.getUserBookings(user.id!);
        setState(() {
          _user = user;
          _bookings = bookings;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text('User not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        child: Icon(Icons.person, size: 50),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _user!.username ?? 'No username',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _user!.email,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      if (_user!.phone != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _user!.phone!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Booking History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_bookings.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No bookings found',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final booking = _bookings[index];
                    return Card(
                      child: ListTile(
                        title: Text('Booking #${booking.id}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Number of Seats: ${booking.numberOfSeats}'),
                            Text('Status: ${booking.status}'),
                            Text('Total Amount: RWF ${booking.totalAmount.toStringAsFixed(2)}'),
                          ],
                        ),
                        trailing: booking.status == 'pending'
                            ? TextButton(
                                onPressed: () {
                                  // TODO: Implement cancel booking
                                },
                                child: const Text('Cancel'),
                              )
                            : null,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
} 