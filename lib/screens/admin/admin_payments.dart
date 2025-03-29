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

  @override
  void initState() {
    super.initState();
    _loadPayments();
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
        'Created At'
      ]);
      
      // Add payment data rows
      for (var payment in payments) {
        // If filtering by status, only include matching payments
        if (_filterStatus == 'All' || payment.paymentStatus == _filterStatus) {
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
      }
      
      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);
      
      // Get the documents directory - this doesn't require permissions on most devices
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'rwanda_bus_payments_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = '${directory.path}/$fileName';
      
      // Write the file
      final File file = File(filePath);
      await file.writeAsString(csv);
      
      // Share the file - this uses the OS-level sharing which handles permissions for us
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Rwanda Bus Payments Export ($_filterStatus)',
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
    // Filter payments based on selected status
    List<Booking> filteredPayments = _filterStatus == 'All'
        ? _payments
        : _payments.where((payment) => payment.paymentStatus == _filterStatus).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Payment Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Filter options
            Row(
              children: [
                const Text('Filter by status:'),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _filterStatus,
                  onChanged: (value) {
                    setState(() {
                      _filterStatus = value!;
                    });
                  },
                  items: ['All', 'Confirmed', 'Pending', 'Failed'].map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status),
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
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPayments.isEmpty
                    ? const Center(
                        child: Text('No payments found'),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'User ID: ${payment.userId}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Route',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${payment.fromLocation} to ${payment.toLocation}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
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
                        style: TextStyle(
                          color: Colors.grey,
                        ),
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
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        payment.paymentMethod,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        payment.createdAt ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
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
                    icon: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
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
      builder: (context) => AlertDialog(
        title: const Text('Approve Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment ID: ${payment.id}'),
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
                await DatabaseHelper().updatePaymentStatus(payment.id, 'Confirmed');
                
                // Update booking status as well
                await DatabaseHelper().updateBookingStatus(payment.id, 'Confirmed');
                
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
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetailsDialog(Booking payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment ${payment.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('User ID', '${payment.userId}'),
            _buildDetailRow('Bus ID', payment.busId),
            _buildDetailRow('From', payment.fromLocation),
            _buildDetailRow('To', payment.toLocation),
            _buildDetailRow('Travel Date', payment.travelDate),
            _buildDetailRow('Passengers', '${payment.passengers}'),
            _buildDetailRow('Amount', '${payment.totalAmount} RWF'),
            _buildDetailRow('Method', payment.paymentMethod),
            _buildDetailRow('Payment Status', payment.paymentStatus),
            _buildDetailRow('Booking Status', payment.bookingStatus),
            _buildDetailRow('Created', payment.createdAt ?? 'Unknown'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}