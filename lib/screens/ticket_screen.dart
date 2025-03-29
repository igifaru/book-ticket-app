// lib/screens/ticket_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for clipboard
import 'package:tickiting/models/bus.dart';
import 'package:tickiting/models/booking.dart';
import 'package:tickiting/utils/theme.dart';
import 'package:tickiting/utils/database_helper.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tickiting/screens/home_screen.dart';
// Remove or comment this line: import 'package:share_plus/share_plus.dart';

class TicketScreen extends StatefulWidget {
  final bool isNewTicket;
  final Bus? bus;
  final String? from;
  final String? to;
  final DateTime? date;
  final int? passengers;
  final List<String>? seatNumbers;
  final String? bookingId;

  const TicketScreen({
    super.key,
    this.isNewTicket = false,
    this.bus,
    this.from,
    this.to,
    this.date,
    this.passengers,
    this.seatNumbers,
    this.bookingId,
  });

  @override
  _TicketScreenState createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all bookings for the current user
      // In a real app, you'd pass the current user's ID
      final bookings = await DatabaseHelper().getUserBookings(1);

      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading bookings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _shareTicket(Ticket ticket) {
    try {
      // Create ticket text
      String ticketDetails =
          "Rwanda Bus Ticket\n\n"
          "Ticket ID: ${ticket.id}\n"
          "Bus: ${ticket.busName}\n"
          "Route: ${ticket.from} to ${ticket.to}\n"
          "Date: ${ticket.date.day}/${ticket.date.month}/${ticket.date.year}\n"
          "Time: ${ticket.departureTime}\n"
          "Seats: ${ticket.seatNumbers.join(', ')}\n"
          "Passengers: ${ticket.passengers}\n\n"
          "Please present this ticket at the bus station.";

      // Show a dialog with copy option
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing by tapping outside
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('Share Ticket'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your ticket details:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(ticketDetails),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Close the dialog
                    Navigator.pop(dialogContext);

                    // Copy to clipboard
                    await Clipboard.setData(ClipboardData(text: ticketDetails));

                    // Show confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ticket copied to clipboard'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 1),
                      ),
                    );

                    // Force navigation directly to HomeScreen
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                      (route) => false, // This removes all previous routes
                    );
                  },
                  child: const Text('Copy & Return Home'),
                ),
              ],
            ),
      );
    } catch (e) {
      print("Error in share dialog: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // If this is a new ticket, use the passed data
    if (widget.isNewTicket &&
        widget.bus != null &&
        widget.from != null &&
        widget.to != null &&
        widget.date != null &&
        widget.passengers != null &&
        widget.seatNumbers != null &&
        widget.bookingId != null) {
      final ticket = Ticket(
        id: widget.bookingId!,
        busName: widget.bus!.name,
        from: widget.from!,
        to: widget.to!,
        date: widget.date!,
        departureTime: widget.bus!.departureTime,
        passengers: widget.passengers!,
        seatNumbers: widget.seatNumbers!,
        status: 'Confirmed',
        qrCode: widget.bookingId!, // Just use the booking ID for QR data
      );

      return _buildTicketDetailsScreen(context, ticket);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tickets'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _bookings.isEmpty
              ? const Center(
                child: Text(
                  'No tickets found. Book a trip to get started!',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadBookings,
                child: ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final booking = _bookings[index];
                    return _buildTicketCard(
                      context,
                      _convertBookingToTicket(booking),
                    );
                  },
                ),
              ),
    );
  }

  // Helper to convert Booking to Ticket (UI model)
  Ticket _convertBookingToTicket(Booking booking) {
    // Parse date from string format "dd/mm/yyyy"
    final dateParts = booking.travelDate.split('/');
    final date = DateTime(
      int.parse(dateParts[2]),
      int.parse(dateParts[1]),
      int.parse(dateParts[0]),
    );

    return Ticket(
      id: booking.id,
      busName: booking.busId, // Ideally we'd get the bus name from the DB
      from: booking.fromLocation,
      to: booking.toLocation,
      date: date,
      departureTime: "Check schedule", // Ideally we'd get this from the bus
      passengers: booking.passengers,
      seatNumbers: booking.seatNumbers.split(','),
      status: booking.bookingStatus,
      qrCode: booking.id, // Use booking ID for QR data
    );
  }

  Widget _buildTicketCard(BuildContext context, Ticket ticket) {
    final bool isUpcoming =
        ticket.date.isAfter(DateTime.now()) ||
        (ticket.date.day == DateTime.now().day &&
            ticket.date.month == DateTime.now().month &&
            ticket.date.year == DateTime.now().year);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _buildTicketDetailsScreen(context, ticket),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
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
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: isUpcoming ? AppTheme.primaryColor : Colors.grey,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    isUpcoming ? 'Upcoming Trip' : 'Past Trip',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isUpcoming ? Colors.green : Colors.grey[600],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ticket.status,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            // Ticket content
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  // Bus info and date
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_bus,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticket.busName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${ticket.date.day}/${ticket.date.month}/${ticket.date.year} • ${ticket.departureTime}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // Route
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticket.from,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'From',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.grey),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              ticket.to,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'To',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // Passengers and seat info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${ticket.passengers} ${ticket.passengers > 1 ? 'Passengers' : 'Passenger'}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        'Seats: ${ticket.seatNumbers.join(', ')}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Footer
            // In ticket_screen.dart, update the status container in the _buildTicketCard method:
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    ticket.status == 'Confirmed'
                        ? Colors.green
                        : ticket.status == 'Pending'
                        ? Colors.orange
                        : Colors.grey[600],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                ticket.status,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketDetailsScreen(BuildContext context, Ticket ticket) {
    final bool isUpcoming =
        ticket.date.isAfter(DateTime.now()) ||
        (ticket.date.day == DateTime.now().day &&
            ticket.date.month == DateTime.now().month &&
            ticket.date.year == DateTime.now().year);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Details'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            // Ticket status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color:
                    ticket.status == 'Confirmed'
                        ? Colors.green
                        : ticket.status == 'Pending'
                        ? Colors.orange
                        : Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                ticket.status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Ticket card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Company logo and name
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(
                            Icons.directions_bus,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Rwanda Bus Services',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Ticket details
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        _buildDetailRow('Bus', ticket.busName),
                        const Divider(),
                        _buildDetailRow('From', ticket.from),
                        _buildDetailRow('To', ticket.to),
                        const Divider(),
                        _buildDetailRow(
                          'Date',
                          '${ticket.date.day}/${ticket.date.month}/${ticket.date.year}',
                        ),
                        _buildDetailRow('Departure Time', ticket.departureTime),
                        const Divider(),
                        _buildDetailRow('Passengers', '${ticket.passengers}'),
                        _buildDetailRow('Seats', ticket.seatNumbers.join(', ')),
                        const Divider(),
                        _buildDetailRow('Ticket ID', ticket.id),
                      ],
                    ),
                  ),
                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Scan this QR code at the bus station',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(10),
                          child: QrImageView(
                            data: ticket.id, // Use ticket ID as QR code data
                            version: QrVersions.auto,
                            size: 150,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Additional options
            if (isUpcoming) ...[
              // Share ticket button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _shareTicket(ticket);
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share Ticket'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Cancel ticket button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Cancel Ticket'),
                            content: const Text(
                              'Are you sure you want to cancel this ticket? Cancellation fees may apply.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('No'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Ticket cancellation request submitted',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Yes, Cancel'),
                              ),
                            ],
                          ),
                    );
                  },
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text(
                    'Cancel Ticket',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Ticket UI model (separate from Booking database model)
class Ticket {
  final String id;
  final String busName;
  final String from;
  final String to;
  final DateTime date;
  final String departureTime;
  final int passengers;
  final List<String> seatNumbers;
  final String status;
  final String qrCode;

  Ticket({
    required this.id,
    required this.busName,
    required this.from,
    required this.to,
    required this.date,
    required this.departureTime,
    required this.passengers,
    required this.seatNumbers,
    required this.status,
    required this.qrCode,
  });
}
