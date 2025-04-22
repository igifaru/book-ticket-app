import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bus.dart';
import '../services/booking_service.dart';
import 'payment_screen.dart';

class BusDetailsScreen extends StatefulWidget {
  final Bus bus;
  final DateTime selectedDate;

  const BusDetailsScreen({
    super.key,
    required this.bus,
    required this.selectedDate,
  });

  @override
  State<BusDetailsScreen> createState() => _BusDetailsScreenState();
}

class _BusDetailsScreenState extends State<BusDetailsScreen> {
  final Set<int> selectedSeats = {};
  bool isLoading = false;

  void _toggleSeat(int seatNumber) {
    setState(() {
      if (selectedSeats.contains(seatNumber)) {
        selectedSeats.remove(seatNumber);
      } else {
        if (selectedSeats.length < 6) { // Maximum 6 seats per booking
          selectedSeats.add(seatNumber);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 6 seats allowed per booking'),
            ),
          );
        }
      }
    });
  }

  Widget _buildSeat(int seatNumber, bool isBooked) {
    final isSelected = selectedSeats.contains(seatNumber);
    return GestureDetector(
      onTap: isBooked ? null : () => _toggleSeat(seatNumber),
      child: Container(
        margin: const EdgeInsets.all(4),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isBooked
              ? Colors.grey
              : isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.white,
          border: Border.all(
            color: isBooked
                ? Colors.grey
                : isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            seatNumber.toString(),
            style: TextStyle(
              color: isSelected || isBooked ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _proceedToPayment() async {
    if (selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one seat'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final totalAmount = selectedSeats.length * widget.bus.price;
      final booking = await context.read<BookingService>().createBooking(
            busId: widget.bus.id!,
            selectedSeats: selectedSeats.toList(),
            journeyDate: widget.selectedDate,
            totalAmount: totalAmount,
          );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              booking: booking,
              amount: totalAmount,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create booking: $e'),
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bus.busName),
      ),
      body: Column(
        children: [
          // Bus Details Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bus Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Bus Number: ${widget.bus.busNumber}'),
                  Text(
                    'Departure: ${widget.bus.departureTime}',
                  ),
                  Text('Arrival: ${widget.bus.arrivalTime}'),
                  Text(
                    'Available Seats: ${widget.bus.availableSeats}',
                  ),
                  Text(
                    'Price per seat: ₹${widget.bus.price}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Seat Selection
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Seats',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    // Seat Layout
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 1,
                        ),
                        itemCount: widget.bus.totalSeats,
                        itemBuilder: (context, index) {
                          final seatNumber = index + 1;
                          final isBooked = false; // TODO: Implement booked seats check
                          return _buildSeat(seatNumber, isBooked);
                        },
                      ),
                    ),
                    // Legend
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildLegendItem('Available', Colors.white),
                          _buildLegendItem(
                            'Selected',
                            Theme.of(context).primaryColor,
                          ),
                          _buildLegendItem('Booked', Colors.grey),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom Bar with Total and Book Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '₹${selectedSeats.length * widget.bus.price}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : _proceedToPayment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Proceed to Payment',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
} 