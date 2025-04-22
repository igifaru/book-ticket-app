import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../utils/date_formatter.dart';
import '../../utils/string_extensions.dart';

class ViewBookingsScreen extends StatefulWidget {
  const ViewBookingsScreen({super.key});

  @override
  State<ViewBookingsScreen> createState() => _ViewBookingsScreenState();
}

class _ViewBookingsScreenState extends State<ViewBookingsScreen> {
  String _searchQuery = '';
  String _filterStatus = 'all';
  String _sortBy = 'date';
  bool _sortAscending = false;
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  List<Booking> _cachedBookings = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bookingService = context.read<BookingService>();
      
      // Initialize the booking service if not already initialized
      if (!bookingService.isInitialized) {
        await bookingService.initialize();
      }
      
      _cachedBookings = await bookingService.getAllBookings();
      
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('ViewBookingsScreen: Error initializing view bookings screen: $e');
      debugPrint('ViewBookingsScreen: Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not load bookings. Please try again.';
      });
    }
  }

  Future<void> _loadBookings() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bookingService = context.read<BookingService>();
      _cachedBookings = await bookingService.getAllBookings();
      
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('ViewBookingsScreen: Error loading bookings: $e');
      debugPrint('ViewBookingsScreen: Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load bookings. Please try again.';
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  List<Booking> _filterAndSortBookings(List<Booking> bookings) {
    if (bookings.isEmpty) return [];

    // Apply search
    var filteredBookings = _searchQuery.isEmpty
        ? bookings
        : bookings.where((booking) {
            final searchLower = _searchQuery.toLowerCase();
            return booking.id.toString().contains(searchLower) ||
                booking.fromLocation.toLowerCase().contains(searchLower) ||
                booking.toLocation.toLowerCase().contains(searchLower) ||
                booking.status.toLowerCase().contains(searchLower);
          }).toList();

    // Apply status filter
    if (_filterStatus != 'all') {
      filteredBookings = filteredBookings
          .where((booking) => booking.status.toLowerCase() == _filterStatus.toLowerCase())
          .toList();
    }

    // Apply sorting
    filteredBookings.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'date':
          comparison = a.travelDate.compareTo(b.travelDate);
          break;
        case 'amount':
          comparison = a.totalAmount.compareTo(b.totalAmount);
          break;
        case 'status':
          comparison = a.status.compareTo(b.status);
          break;
        default:
          comparison = a.id!.compareTo(b.id!);
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filteredBookings;
  }

  void _showBookingDetails(BuildContext context, Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Booking Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              _buildDetailRow('Booking ID', '#${booking.id}'),
              _buildDetailRow('From', booking.fromLocation),
              _buildDetailRow('To', booking.toLocation),
              _buildDetailRow('Travel Date', _formatDate(booking.travelDate)),
              _buildDetailRow('Departure Time', _formatTime(booking.travelDate)),
              _buildDetailRow('Number of Seats', booking.numberOfSeats.toString()),
              _buildDetailRow('Seat Numbers', booking.seatNumber ?? 'Not Assigned'),
              _buildDetailRow('Total Amount', 'RWF ${booking.totalAmount}'),
              _buildDetailRow('Status', booking.status.toUpperCase(),
                  color: _getStatusColor(booking.status)),
              if (booking.status == 'confirmed' && booking.confirmedBy != null) ...[
                _buildDetailRow(
                  'Confirmed By',
                  'Admin #${booking.confirmedBy}',
                ),
                if (booking.confirmedAt != null)
                  _buildDetailRow(
                    'Confirmed At',
                    DateFormat('MMM dd, yyyy HH:mm').format(booking.confirmedAt!),
                  ),
              ],
              const SizedBox(height: 20),
              if (booking.status == 'pending')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _confirmBooking(context, booking),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Confirm Booking'),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showCancelDialog(context, booking),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancel Booking'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _confirmBooking(BuildContext context, Booking booking) async {
    try {
      final bookingService = context.read<BookingService>();
      final success = await bookingService.updateBookingStatus(
        booking.id!,
        'confirmed',
        adminId: 1, // TODO: Get actual admin ID
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking confirmed successfully')),
        );
        _cachedBookings = await bookingService.getAllBookings();
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to confirm booking'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showCancelDialog(BuildContext context, Booking booking) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final bookingService = context.read<BookingService>();
              try {
                await bookingService.updateBookingStatus(
                  booking.id!,
                  'cancelled',
                );
                if (mounted) {
                  Navigator.pop(context); // Close details sheet
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Booking cancelled successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: (value) {
              setState(() {
                if (_sortBy == value) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortBy = value;
                  _sortAscending = true;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date',
                child: Text('Sort by Date'),
              ),
              const PopupMenuItem(
                value: 'amount',
                child: Text('Sort by Amount'),
              ),
              const PopupMenuItem(
                value: 'status',
                child: Text('Sort by Status'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search bookings...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _filterStatus == 'all',
                        onSelected: (selected) {
                          setState(() {
                            _filterStatus = 'all';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Pending'),
                        selected: _filterStatus == 'pending',
                        onSelected: (selected) {
                          setState(() {
                            _filterStatus = 'pending';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Confirmed'),
                        selected: _filterStatus == 'confirmed',
                        onSelected: (selected) {
                          setState(() {
                            _filterStatus = 'confirmed';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Cancelled'),
                        selected: _filterStatus == 'cancelled',
                        onSelected: (selected) {
                          setState(() {
                            _filterStatus = 'cancelled';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadBookings,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadBookings,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : Consumer<BookingService>(
                          builder: (context, bookingService, child) {
                            final filteredBookings = _filterAndSortBookings(_cachedBookings);
                            
                            if (filteredBookings.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.event_busy,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No bookings found',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (_searchQuery.isNotEmpty || _filterStatus != 'all')
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _searchQuery = '';
                                              _searchController.clear();
                                              _filterStatus = 'all';
                                            });
                                          },
                                          child: const Text('Clear filters'),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: filteredBookings.length,
                              itemBuilder: (context, index) {
                                final booking = filteredBookings[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Row(
                                      children: [
                                        Text('Booking #${booking.id}'),
                                        const Spacer(),
                                        _buildStatusChip(booking.status),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.event, size: 16),
                                            const SizedBox(width: 4),
                                            Text(_formatDate(booking.travelDate)),
                                            const SizedBox(width: 16),
                                            const Icon(Icons.airline_seat_recline_normal, size: 16),
                                            const SizedBox(width: 4),
                                            Text('${booking.numberOfSeats} seats'),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, size: 16),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                '${booking.fromLocation} → ${booking.toLocation}',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    onTap: () => _showBookingDetails(context, booking),
                                    isThreeLine: true,
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.capitalize(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
} 