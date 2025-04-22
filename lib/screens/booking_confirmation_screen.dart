import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../models/payment.dart';
import 'home_screen.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final Booking booking;
  final Payment payment;

  const BookingConfirmationScreen({
    super.key,
    required this.booking,
    required this.payment,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              'Booking Confirmed!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transaction ID: ${payment.transactionId}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Seat Number', booking.seatNumber),
                    _buildDetailRow(
                      'Journey Date',
                      booking.journeyDate.toString().split(' ')[0],
                    ),
                    _buildDetailRow(
                      'Amount Paid',
                      'RWF ${booking.totalAmount.toStringAsFixed(2)}',
                    ),
                    _buildDetailRow('Payment Method', payment.paymentMethod),
                    _buildDetailRow('Payment Status', payment.status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Important Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '• Please arrive at least 30 minutes before departure',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      '• Keep this ticket for verification',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      '• Present a valid ID during boarding',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              },
              child: const Text('Back to Home'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // TODO: Implement download ticket
              },
              child: const Text('Download Ticket'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 