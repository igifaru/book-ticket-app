// lib/screens/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:tickiting/models/booking.dart';
import 'package:tickiting/models/bus.dart';
import 'package:tickiting/screens/ticket_screen.dart';
import 'package:tickiting/utils/theme.dart';
import 'package:tickiting/utils/database_helper.dart';
import 'dart:math';

class PaymentScreen extends StatefulWidget {
  final Bus bus;
  final String from;
  final String to;
  final DateTime date;
  final int passengers;

  const PaymentScreen({
    Key? key,
    required this.bus,
    required this.from,
    required this.to,
    required this.date,
    required this.passengers,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _paymentMethod = 'MTN Mobile Money';
  final _phoneController = TextEditingController();
  bool _isProcessing = false;

  // Generate random seat numbers
  List<String> _generateSeatNumbers(int count) {
    final seats = <String>[];
    final random = Random();
    final letters = ['A', 'B', 'C', 'D'];
    
    for (int i = 0; i < count; i++) {
      final letter = letters[random.nextInt(letters.length)];
      final number = random.nextInt(10) + 1;
      seats.add('$letter$number');
    }
    
    return seats;
  }

  // Generate booking ID
  String _generateBookingId() {
    final random = Random();
    return 'BKG${DateTime.now().millisecondsSinceEpoch}${random.nextInt(1000)}';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _processPayment() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    // Show payment confirmation dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to pay ${widget.bus.price * widget.passengers} RWF to Rwanda Bus Services using $_paymentMethod.'),
            const SizedBox(height: 10),
            const Text(
              'A prompt will be sent to your phone. Please enter your PIN to authorize payment.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isProcessing = false;
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completePayment();
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _completePayment() async {
    try {
      final bookingId = _generateBookingId();
      final seatNumbers = _generateSeatNumbers(widget.passengers);
      final totalAmount = widget.bus.price * widget.passengers;
      
      // Create booking record with "Pending" status
      final booking = Booking(
        id: bookingId,
        userId: 1, // In a real app, this would be the current user's ID
        busId: widget.bus.id,
        fromLocation: widget.from,
        toLocation: widget.to,
        travelDate: '${widget.date.day}/${widget.date.month}/${widget.date.year}',
        passengers: widget.passengers,
        seatNumbers: seatNumbers.join(','),
        totalAmount: totalAmount,
        paymentMethod: _paymentMethod,
        paymentStatus: 'Pending', // Changed from 'Confirmed' to 'Pending'
        bookingStatus: 'Pending', // Changed from 'Confirmed' to 'Pending'
      );
      
      // Save booking to database
      await DatabaseHelper().insertBooking(booking);
      
      // Update bus available seats
      final updatedBus = Bus(
        id: widget.bus.id,
        name: widget.bus.name,
        departureTime: widget.bus.departureTime,
        arrivalTime: widget.bus.arrivalTime,
        duration: widget.bus.duration,
        price: widget.bus.price,
        availableSeats: widget.bus.availableSeats - widget.passengers,
        busType: widget.bus.busType,
        features: widget.bus.features,
      );
      
      await DatabaseHelper().updateBus(updatedBus);

      setState(() {
        _isProcessing = false;
      });

      // Navigate to ticket screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => TicketScreen(
            isNewTicket: true,
            bus: updatedBus,
            from: widget.from,
            to: widget.to,
            date: widget.date,
            passengers: widget.passengers,
            seatNumbers: seatNumbers,
            bookingId: bookingId,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = widget.bus.price * widget.passengers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment info alert
            Container(
              padding: const EdgeInsets.all(15),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue[300]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: Colors.blue,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your ticket will be pending until payment is confirmed by an administrator. You will be notified once your ticket is confirmed.',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            // Trip summary
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
                children: [
                  const Text(
                    'Trip Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildSummaryRow('Bus', widget.bus.name),
                  _buildSummaryRow('Route', '${widget.from} to ${widget.to}'),
                  _buildSummaryRow('Date', '${widget.date.day}/${widget.date.month}/${widget.date.year}'),
                  _buildSummaryRow('Time', widget.bus.departureTime),
                  _buildSummaryRow('Passengers', '${widget.passengers}'),
                  _buildSummaryRow('Price per ticket', '${widget.bus.price} RWF'),
                  const Divider(),
                  _buildSummaryRow(
                    'Total Amount',
                    '$totalAmount RWF',
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Payment method
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Container(
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
                children: [
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.yellow,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Center(
                            child: Text(
                              'MTN',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text('MTN Mobile Money'),
                      ],
                    ),
                    value: 'MTN Mobile Money',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Center(
                            child: Text(
                              'AIRTEL',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text('Airtel Money'),
                      ],
                    ),
                    value: 'Airtel Money',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Phone number
            const Text(
              'Phone Number',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'Enter your phone number',
                prefixIcon: Icon(Icons.phone),
                prefixText: '+250 ',
              ),
            ),
            const SizedBox(height: 40),
            // Pay button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Pay $totalAmount RWF',
                        style: const TextStyle(fontSize: 18),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            // Security note
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.security,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Your payment information is secure. We use industry standard encryption to protect your data.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 16,
              color: isBold ? AppTheme.primaryColor : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}