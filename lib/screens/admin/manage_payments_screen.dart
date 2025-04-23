import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/payment_service.dart';
import '../../services/booking_service.dart';
import '../../models/payment.dart';
import '../../models/booking.dart';
import 'package:intl/intl.dart';

class ManagePaymentsScreen extends StatefulWidget {
  const ManagePaymentsScreen({super.key});

  @override
  State<ManagePaymentsScreen> createState() => _ManagePaymentsScreenState();
}

class _ManagePaymentsScreenState extends State<ManagePaymentsScreen> {
  List<Payment> _payments = [];
  bool _isLoading = true;
  String? _error;
  String _filterStatus = 'all';
  final _currencyFormat = NumberFormat.currency(symbol: 'RWF ');

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final paymentService = context.read<PaymentService>();
      List<Payment> payments;
      
      if (_filterStatus == 'all') {
        payments = await paymentService.getAllPayments();
      } else {
        payments = await paymentService.getPaymentsByStatus(_filterStatus);
      }

      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load payments: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _approvePayment(Payment payment) async {
    try {
      await context.read<PaymentService>().updatePaymentStatus(payment.id!, 'completed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment approved successfully')),
      );
      _loadPayments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve payment: $e')),
      );
    }
  }

  Future<void> _rejectPayment(Payment payment) async {
    try {
      await context.read<PaymentService>().updatePaymentStatus(payment.id!, 'rejected');
      // Also update the booking status
      await context.read<BookingService>().updateBookingStatus(payment.bookingId, 'cancelled');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment rejected successfully')),
      );
      _loadPayments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject payment: $e')),
      );
    }
  }

  Future<void> _processRefund(Payment payment) async {
    try {
      // First update payment status to refunded
      await context.read<PaymentService>().updatePaymentStatus(payment.id!, 'refunded');
      // Then update booking status to cancelled
      await context.read<BookingService>().updateBookingStatus(payment.bookingId, 'cancelled');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refund processed successfully')),
      );
      _loadPayments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process refund: $e')),
      );
    }
  }

  void _showPaymentDetails(Payment payment) async {
    final booking = await context.read<BookingService>().getBookingById(payment.bookingId);
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.payment,
                    size: 50,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (booking != null) ...[
                _buildDetailRow('Booking ID', '#${booking.id}', Icons.confirmation_number),
                const Divider(),
                _buildDetailRow('From', booking.fromLocation, Icons.location_on),
                const Divider(),
                _buildDetailRow('To', booking.toLocation, Icons.location_on),
                const Divider(),
                _buildDetailRow('Travel Date', 
                  DateFormat('MMM dd, yyyy').format(booking.travelDate), 
                  Icons.calendar_today
                ),
                const Divider(),
              ],
              _buildDetailRow(
                'Amount',
                _currencyFormat.format(payment.amount),
                Icons.money,
              ),
              const Divider(),
              _buildDetailRow(
                'Payment Method',
                payment.paymentMethod,
                Icons.credit_card,
              ),
              const Divider(),
              _buildDetailRow(
                'Transaction ID',
                payment.transactionId,
                Icons.receipt_long,
              ),
              const Divider(),
              _buildDetailRow(
                'Status',
                payment.status,
                Icons.info_outline,
                valueColor: _getStatusColor(payment.status),
              ),
              const Divider(),
              _buildDetailRow(
                'Payment Date',
                DateFormat('MMM dd, yyyy HH:mm').format(payment.paymentDate),
                Icons.access_time,
              ),
              const SizedBox(height: 24),
              if (payment.status == 'pending')
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _approvePayment(payment);
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _rejectPayment(payment);
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ],
                )
              else if (payment.status == 'completed')
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showRefundConfirmation(payment);
                    },
                    icon: const Icon(Icons.money),
                    label: const Text('Process Refund'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRefundConfirmation(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Refund'),
        content: Text(
          'Are you sure you want to process a refund of ${_currencyFormat.format(payment.amount)}?'
          '\n\nThis will also cancel the associated booking.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _processRefund(payment);
            },
            child: const Text(
              'Process Refund',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Payments'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
                _loadPayments();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Payments'),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Text('Pending'),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Text('Completed'),
              ),
              const PopupMenuItem(
                value: 'rejected',
                child: Text('Rejected'),
              ),
              const PopupMenuItem(
                value: 'refunded',
                child: Text('Refunded'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPayments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _payments.isEmpty
                  ? Center(
                      child: Text(
                        _filterStatus == 'all'
                            ? 'No payments found'
                            : 'No ${_filterStatus.toLowerCase()} payments found',
                      ),
                    )
                  : ListView.builder(
                      itemCount: _payments.length,
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (context, index) {
                        final payment = _payments[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(payment.status).withOpacity(0.1),
                              child: Icon(
                                Icons.payment,
                                color: _getStatusColor(payment.status),
                              ),
                            ),
                            title: Text('Payment #${payment.id}'),
                            subtitle: Text(
                              '${_currencyFormat.format(payment.amount)} • ${payment.paymentMethod}',
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(payment.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                payment.status,
                                style: TextStyle(
                                  color: _getStatusColor(payment.status),
                                ),
                              ),
                            ),
                            onTap: () => _showPaymentDetails(payment),
                          ),
                        );
                      },
                    ),
    );
  }
} 