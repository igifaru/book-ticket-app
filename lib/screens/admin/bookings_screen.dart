import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with AutomaticKeepAliveClientMixin {
  bool _isLoading = false;
  String? _error;
  bool _isActionInProgress = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeBookings();
  }

  Future<void> _initializeBookings() async {
    if (!mounted) return;

    final bookingService = Provider.of<BookingService>(context, listen: false);
    if (!bookingService.isInitialized) {
      setState(() => _isLoading = true);
      try {
        await bookingService.initialize();
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = 'Failed to initialize bookings: $e';
          });
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _refreshBookings() async {
    if (_isActionInProgress) return;

    final bookingService = Provider.of<BookingService>(context, listen: false);
    await bookingService.getAllBookings();
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '#FFA726';
      case 'confirmed':
        return '#66BB6A';
      case 'cancelled':
        return '#EF5350';
      default:
        return '#9E9E9E';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: Consumer<BookingService>(
        builder: (context, bookingService, child) {
          if (!bookingService.isInitialized) {
            return const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshBookings,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverAppBar(
                  title: Text('Bookings'),
                  floating: true,
                  snap: true,
                ),
                if (bookingService.loading && bookingService.bookings.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  )
                else if (_error != null && bookingService.bookings.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: bookingService.loading ? null : _initializeBookings,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (bookingService.bookings.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text('No bookings found'),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final booking = bookingService.bookings[index];
                          final statusColor = _getStatusColor(booking.status);
                          
                          return RepaintBoundary(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Card(
                                elevation: 2,
                                child: ExpansionTile(
                                  title: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: Color(
                                            int.parse(statusColor.substring(1), radix: 16) + 0xFF000000,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Booking #${booking.id}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    '${booking.fromLocation} → ${booking.toLocation}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildInfoRow('Status', booking.status.toUpperCase()),
                                          _buildInfoRow('From', booking.fromLocation),
                                          _buildInfoRow('To', booking.toLocation),
                                          _buildInfoRow('Seats', booking.numberOfSeats.toString()),
                                          _buildInfoRow(
                                            'Amount',
                                            'RWF ${booking.totalAmount.toStringAsFixed(2)}',
                                          ),
                                          _buildInfoRow(
                                            'Booked On',
                                            booking.createdAt.toString().split('.')[0],
                                          ),
                                          if (booking.status == 'pending' && !_isActionInProgress)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 16),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  TextButton(
                                                    onPressed: _isActionInProgress 
                                                      ? null 
                                                      : () => _handleCancelBooking(booking),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor: Colors.red,
                                                    ),
                                                    child: const Text('Cancel Booking'),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  ElevatedButton(
                                                    onPressed: _isActionInProgress 
                                                      ? null 
                                                      : () => _handleConfirmBooking(booking),
                                                    child: const Text('Confirm Booking'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: bookingService.bookings.length,
                      ),
                    ),
                  ),
                if (bookingService.loading && bookingService.bookings.isNotEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleConfirmBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: const Text(
          'Are you sure you want to confirm this booking?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Wait'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isActionInProgress = true);
      try {
        final bookingService = Provider.of<BookingService>(context, listen: false);
        await bookingService.updateBookingStatus(
          booking.id!,
          'confirmed',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking confirmed successfully'),
              backgroundColor: Colors.green,
            ),
          );
          await _refreshBookings();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error confirming booking: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isActionInProgress = false);
        }
      }
    }
  }

  Future<void> _handleCancelBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isActionInProgress = true);
      try {
        final bookingService = Provider.of<BookingService>(context, listen: false);
        await bookingService.updateBookingStatus(
          booking.id!,
          'cancelled',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking cancelled successfully'),
              backgroundColor: Colors.orange,
            ),
          );
          await _refreshBookings();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling booking: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isActionInProgress = false);
        }
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
} 