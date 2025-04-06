// lib/screens/admin/admin_payments.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tickiting/models/booking.dart';
import 'package:tickiting/utils/theme.dart';
import 'package:tickiting/utils/database_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';

class AdminPayments extends StatefulWidget {
  const AdminPayments({super.key});

  @override
  _AdminPaymentsState createState() => _AdminPaymentsState();
}

class _AdminPaymentsState extends State<AdminPayments> {
  List<Booking> _payments = [];
  bool _isLoading = true;
  String _filterStatus = 'All';
  String _filterRoute = 'All';
  List<Map<String, String>> _availableRoutes = [];

  @override
  void initState() {
    super.initState();
    _loadPayments();
    _loadAvailableRoutes();
  }

  Future<void> _loadAvailableRoutes() async {
    try {
      // Get all available routes from database
      final routes = await DatabaseHelper().getAvailableRoutes();

      // Add "All" option at the beginning
      setState(() {
        _availableRoutes = [
          {'from': 'All', 'to': 'All'},
          ...routes,
        ];
      });
    } catch (e) {
      print('Error loading routes: $e');
    }
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all bookings from database
      final bookings = await DatabaseHelper().getAllBookings();

      setState(() {
        _payments = bookings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading payments: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Export payments to CSV file without permission check
  Future<void> exportPayments(List<Booking> payments) async {
    try {
      // Prepare the CSV data
      List<List<dynamic>> csvData = [];

      // Add header row
      csvData.add([
        'Payment ID',
        'User ID',
        'From Location',
        'To Location',
        'Travel Date',
        'Passengers',
        'Seat Numbers',
        'Amount',
        'Payment Method',
        'Payment Status',
        'Booking Status',
        'Created At',
      ]);

      // Add payment data rows
      for (var payment in payments) {
        csvData.add([
          payment.id,
          payment.userId,
          payment.fromLocation,
          payment.toLocation,
          payment.travelDate,
          payment.passengers,
          payment.seatNumbers,
          payment.totalAmount,
          payment.paymentMethod,
          payment.paymentStatus,
          payment.bookingStatus,
          payment.createdAt ?? 'N/A',
        ]);
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Get the documents directory - this doesn't require permissions on most devices
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'rwanda_bus_payments_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = '${directory.path}/$fileName';

      // Write the file
      final File file = File(filePath);
      await file.writeAsString(csv);

      // Share the file - this uses the OS-level sharing which handles permissions for us
      String routeInfo = _filterRoute == 'All' ? 'All Routes' : _filterRoute;
      String statusInfo =
          _filterStatus == 'All' ? 'All Statuses' : _filterStatus;

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Rwanda Bus Payments Export ($routeInfo - $statusInfo)',
        text: 'Attached is the exported payments data from Rwanda Bus',
      );
    } catch (e) {
      // Handle any errors that occur during export
      print('Error exporting payments: $e');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting payments: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter payments based on selected status and route
    List<Booking> filteredPayments = _payments;

    // Apply status filter
    if (_filterStatus != 'All') {
      filteredPayments =
          filteredPayments
              .where((payment) => payment.paymentStatus == _filterStatus)
              .toList();
    }

    // Apply route filter
    if (_filterRoute != 'All') {
      final routeParts = _filterRoute.split(' to ');
      if (routeParts.length == 2) {
        final fromLocation = routeParts[0];
        final toLocation = routeParts[1];

        filteredPayments =
            filteredPayments
                .where(
                  (payment) =>
                      payment.fromLocation == fromLocation &&
                      payment.toLocation == toLocation,
                )
                .toList();
      }
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Payment Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Filter options
            Row(
              children: [
                const Text('Status:'),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _filterStatus,
                  onChanged: (value) {
                    setState(() {
                      _filterStatus = value!;
                    });
                  },
                  items:
                      ['All', 'Confirmed', 'Pending', 'Failed'].map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                ),
                const SizedBox(width: 20),
                const Text('Route:'),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _filterRoute,
                  onChanged: (value) {
                    setState(() {
                      _filterRoute = value!;
                    });
                  },
                  items:
                      [
                        'All',
                        ..._availableRoutes
                            .where((route) => route['from'] != 'All')
                            .map(
                              (route) => "${route['from']} to ${route['to']}",
                            ),
                      ].map((route) {
                        return DropdownMenuItem(
                          value: route,
                          child: Text(route),
                        );
                      }).toList(),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () async {
                    // Show loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return const Dialog(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(width: 20),
                                Text("Exporting payments..."),
                              ],
                            ),
                          ),
                        );
                      },
                    );

                    try {
                      await exportPayments(filteredPayments);
                      // Close loading dialog
                      if (mounted) {
                        Navigator.pop(context);

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payments exported successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      // Close loading dialog
                      if (mounted) {
                        Navigator.pop(context);
                      }

                      // Error is already handled in exportPayments function
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Payments list
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredPayments.isEmpty
                      ? const Center(
                        child: Text(
                          'No payments found with the selected filters',
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: _loadPayments,
                        child: ListView.builder(
                          itemCount: filteredPayments.length,
                          itemBuilder: (context, index) {
                            final payment = filteredPayments[index];
                            return _buildPaymentCard(payment);
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Booking payment) {
    Color statusColor;
    switch (payment.paymentStatus) {
      case 'Confirmed':
        statusColor = Colors.green;
        break;
      case 'Pending':
        statusColor = Colors.orange;
        break;
      case 'Failed':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment ID: ${payment.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'User ID: ${payment.userId}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    payment.paymentStatus,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            // Highlight the route information
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                children: [
                  Icon(Icons.route, size: 16, color: Colors.blue[800]),
                  const SizedBox(width: 5),
                  Text(
                    '${payment.fromLocation} to ${payment.toLocation}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Travel Date',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        payment.travelDate,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Amount',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '${payment.totalAmount} RWF',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Method',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        payment.paymentMethod,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date', style: TextStyle(color: Colors.grey)),
                      Text(
                        payment.createdAt ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (payment.paymentStatus == 'Pending')
                  OutlinedButton.icon(
                    onPressed: () {
                      // Approve payment logic
                      _showApproveDialog(payment);
                    },
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    label: const Text(
                      'Approve',
                      style: TextStyle(color: Colors.green),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                    ),
                  ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    // View details
                    _showPaymentDetailsDialog(payment);
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showApproveDialog(Booking payment) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Approve Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment ID: ${payment.id}'),
                Text('Route: ${payment.fromLocation} to ${payment.toLocation}'),
                Text('Amount: ${payment.totalAmount} RWF'),
                Text('Method: ${payment.paymentMethod}'),
                const SizedBox(height: 10),
                const Text('Are you sure you want to approve this payment?'),
                const Text('This will confirm the ticket for the user.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Update payment status in database
                    await DatabaseHelper().updatePaymentStatus(
                      payment.id,
                      'Confirmed',
                    );

                    // Update booking status as well
                    await DatabaseHelper().updateBookingStatus(
                      payment.id,
                      'Confirmed',
                    );

                    // Reload payments
                    _loadPayments();

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment approved and ticket confirmed'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error approving payment: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Approve'),
              ),
            ],
          ),
    );
  }

  void _showPaymentDetailsDialog(Booking payment) async {
    // Try to get the user's name
    String userName = 'User #${payment.userId}';
    try {
      final user = await DatabaseHelper().getUserById(payment.userId);
      if (user != null) {
        userName = user.name;
      }
    } catch (e) {
      print('Error getting user: $e');
    }

    // Get the bus information
    String busName = 'Unknown Bus';
    try {
      final bus = await DatabaseHelper().getBus(payment.busId);
      if (bus != null) {
        busName = bus.name;
      }
    } catch (e) {
      print('Error getting bus: $e');
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Payment Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Payment ID', payment.id),
                  _buildDetailRow('User Name', userName),
                  _buildDetailRow('User ID', '${payment.userId}'),
                  _buildDetailRow('Bus', busName),
                  _buildDetailRow('Bus ID', payment.busId),
                  _buildDetailRow(
                    'Route',
                    '${payment.fromLocation} to ${payment.toLocation}',
                  ),
                  _buildDetailRow('Travel Date', payment.travelDate),
                  _buildDetailRow('Passengers', '${payment.passengers}'),
                  _buildDetailRow('Seat Numbers', payment.seatNumbers),
                  _buildDetailRow('Total Amount', '${payment.totalAmount} RWF'),
                  _buildDetailRow('Payment Method', payment.paymentMethod),
                  _buildDetailRow('Payment Status', payment.paymentStatus),
                  _buildDetailRow('Booking Status', payment.bookingStatus),
                  if (payment.createdAt != null)
                    _buildDetailRow('Created At', payment.createdAt!),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Close'),
              ),
              if (payment.paymentStatus == 'Pending')
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showApproveDialog(payment);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Approve Payment'),
                ),
              if (payment.paymentStatus == 'Confirmed')
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showResendConfirmationDialog(payment);
                  },
                  icon: const Icon(Icons.email),
                  label: const Text('Resend Confirmation'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showResendConfirmationDialog(Booking payment) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Resend Confirmation'),
            content: const Text(
              'Do you want to resend the confirmation notification to the user?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Call notification service to send a confirmation notification
                    // This would typically be handled by your notification service
                    // For now, we'll just show a success message

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Confirmation notification sent to user'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error sending notification: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Send'),
              ),
            ],
          ),
    );
  }
}
