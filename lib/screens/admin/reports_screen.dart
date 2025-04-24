import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../../services/booking_service.dart';
import '../../services/payment_service.dart';
import '../../models/booking.dart';
import '../../models/payment.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/dashboard/bar_chart_widget.dart';
import '../../widgets/dashboard/line_chart_widget.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  String? _error;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  String _selectedReport = 'bookings';
  List<Booking> _bookings = [];
  List<Payment> _payments = [];
  bool _isInitialized = false;
  late BookingService _bookingService;
  late PaymentService _paymentService;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _bookingService = Provider.of<BookingService>(context, listen: false);
      _paymentService = Provider.of<PaymentService>(context, listen: false);
      _initializeData();
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _bookingService.removeListener(_onBookingServiceChanged);
      _paymentService.removeListener(_onPaymentServiceChanged);
    }
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('ReportsScreen: Starting initialization...');

      // Initialize services in correct order
      debugPrint('ReportsScreen: Initializing BookingService...');
      if (!_bookingService.isInitialized) {
        await _bookingService.initialize();
      }

      debugPrint('ReportsScreen: Initializing PaymentService...');
      if (!_paymentService.isInitialized) {
        await _paymentService.initialize();
      }

      // Add listeners after initialization
      _bookingService.addListener(_onBookingServiceChanged);
      _paymentService.addListener(_onPaymentServiceChanged);

      debugPrint('ReportsScreen: Loading initial data...');
      await _loadData();
      
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
      debugPrint('ReportsScreen: Initialization complete');
    } catch (e, stackTrace) {
      debugPrint('ReportsScreen: Error during initialization: $e');
      debugPrint('ReportsScreen: Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _error = 'Error loading data. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _onBookingServiceChanged() {
    if (!mounted || !_isInitialized) return;
    _loadData();
  }

  void _onPaymentServiceChanged() {
    if (!mounted || !_isInitialized) return;
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    try {
      debugPrint('ReportsScreen: Loading data...');

      // Load data in parallel
      final results = await Future.wait([
        _bookingService.getAllBookings(),
        _paymentService.getAllPayments(),
      ]);

      if (!mounted) return;
      setState(() {
        _bookings = List<Booking>.from(results[0]);
        _payments = List<Payment>.from(results[1]);
        _error = null;
      });
      debugPrint('ReportsScreen: Data loaded successfully');
    } catch (e, stackTrace) {
      debugPrint('ReportsScreen: Error loading data: $e');
      debugPrint('ReportsScreen: Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _error = 'Error loading data. Please try again.';
      });
    }
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBarTheme: AppBarTheme(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
      helpText: 'Select Report Period',
      saveText: 'Apply',
      confirmText: 'Apply',
      cancelText: 'Cancel',
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _loadData();
      });
    }
  }

  List<Booking> get _filteredBookings {
    return _bookings.where((booking) {
      final bookingDate = booking.createdAt;
      return bookingDate.isAfter(_dateRange.start) &&
             bookingDate.isBefore(_dateRange.end.add(const Duration(days: 1)));
    }).toList();
  }

  List<Payment> get _filteredPayments {
    return _payments.where((payment) {
      return payment.paymentDate.isAfter(_dateRange.start) &&
             payment.paymentDate.isBefore(_dateRange.end.add(const Duration(days: 1)));
    }).toList();
  }

  Widget _buildBookingStats() {
    final totalBookings = _filteredBookings.length;
    final confirmedBookings = _filteredBookings.where((b) => b.status.toLowerCase() == 'confirmed').length;
    final cancelledBookings = _filteredBookings.where((b) => b.status.toLowerCase() == 'cancelled').length;
    final pendingBookings = _filteredBookings.where((b) => b.status.toLowerCase() == 'pending').length;

    return Column(
      children: [
        _buildStatCard(
          'Total Bookings',
          totalBookings.toString(),
          Icons.book,
          Colors.blue,
          onTap: () => _showBookingDetails('all'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Confirmed',
                confirmedBookings.toString(),
                Icons.check_circle,
                Colors.green,
                onTap: () => _showBookingDetails('confirmed'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Cancelled',
                cancelledBookings.toString(),
                Icons.cancel,
                Colors.red,
                onTap: () => _showBookingDetails('cancelled'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          'Pending',
          pendingBookings.toString(),
          Icons.pending,
          Colors.orange,
          onTap: () => _showBookingDetails('pending'),
        ),
        const SizedBox(height: 24),
        if (_filteredBookings.isNotEmpty) _buildBookingChart(),
      ],
    );
  }

  void _showBookingDetails(String status) {
    final bookings = status == 'all' 
        ? _filteredBookings 
        : _filteredBookings.where((b) => b.status.toLowerCase() == status.toLowerCase()).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${status.capitalize()} Bookings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              if (bookings.isEmpty)
                Expanded(
                  child: Center(
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
                          'No ${status.toLowerCase()} bookings found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'for the selected period',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
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
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(booking.createdAt),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.airline_seat_recline_normal, size: 16),
                                  const SizedBox(width: 4),
                                  Text('${booking.numberOfSeats} seats'),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = status.toLowerCase() == 'confirmed'
        ? Colors.green
        : status.toLowerCase() == 'cancelled'
            ? Colors.red
            : Colors.orange;

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

  Widget _buildStatCard(
    String title, 
    String value, 
    IconData icon, 
    Color color, 
    {VoidCallback? onTap}
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingChart() {
    final dailyBookings = <DateTime, int>{};
    for (final booking in _filteredBookings) {
      final date = DateTime(
        booking.createdAt.year,
        booking.createdAt.month,
        booking.createdAt.day,
      );
      dailyBookings[date] = (dailyBookings[date] ?? 0) + 1;
    }

    final spots = dailyBookings.entries.map((e) {
      return FlSpot(
        e.key.millisecondsSinceEpoch.toDouble(),
        e.value.toDouble(),
      );
    }).toList()..sort((a, b) => a.x.compareTo(b.x));

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Trends',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          return Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              DateFormat('MM/dd').format(date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.blue,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.blueAccent,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                            touchedSpot.x.toInt(),
                          );
                          return LineTooltipItem(
                            '${DateFormat('MMM dd').format(date)}\n',
                            const TextStyle(color: Colors.white, fontSize: 12),
                            children: [
                              TextSpan(
                                text: '${touchedSpot.y.toInt()} bookings',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                    handleBuiltInTouches: true,
                    touchCallback: (event, response) {
                      if (event is FlTapUpEvent) {
                        if (response?.lineBarSpots != null && 
                            response!.lineBarSpots!.isNotEmpty) {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                            response.lineBarSpots!.first.x.toInt(),
                          );
                          _showBookingsForDate(date);
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingsForDate(DateTime date) {
    final bookings = _filteredBookings.where((booking) {
      final bookingDate = DateTime(
        booking.createdAt.year,
        booking.createdAt.month,
        booking.createdAt.day,
      );
      return bookingDate == DateTime(date.year, date.month, date.day);
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bookings on ${DateFormat('MMM dd, yyyy').format(date)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return Card(
                      child: ListTile(
                        title: Text('Booking #${booking.id}'),
                        subtitle: Text(
                          'Status: ${booking.status}\n'
                          'Seats: ${booking.numberOfSeats}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueStats() {
    final totalRevenue = _filteredPayments
        .where((p) => p.status == 'completed')
        .fold<double>(0, (sum, payment) => sum + payment.amount);
    
    final dailyRevenue = <DateTime, double>{};
    for (final payment in _filteredPayments.where((p) => p.status == 'completed')) {
      final date = DateTime(
        payment.paymentDate.year,
        payment.paymentDate.month,
        payment.paymentDate.day,
      );
      dailyRevenue[date] = (dailyRevenue[date] ?? 0) + payment.amount;
    }

    return Column(
      children: [
        _buildStatCard(
          'Total Revenue',
          'RWF ${NumberFormat('#,###').format(totalRevenue)}',
          Icons.monetization_on,
          Colors.green,
        ),
        const SizedBox(height: 24),
        _buildRevenueChart(dailyRevenue),
      ],
    );
  }

  Widget _buildRevenueChart(Map<DateTime, double> dailyRevenue) {
    final spots = dailyRevenue.entries.map((e) {
      return FlSpot(
        e.key.millisecondsSinceEpoch.toDouble(),
        e.value,
      );
    }).toList()..sort((a, b) => a.x.compareTo(b.x));

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return Text(DateFormat('MM/dd').format(date));
                },
                reservedSize: 30,
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportReport() async {
    try {
      setState(() => _isLoading = true);

      final pdf = pw.Document();
      
      // Add title page
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Bus Booking System Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Period: ${DateFormat('MMM dd, yyyy').format(_dateRange.start)} - ${DateFormat('MMM dd, yyyy').format(_dateRange.end)}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                _selectedReport == 'bookings' ? 'Booking Report' : 'Revenue Report',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),
              if (_selectedReport == 'bookings') ...[
                _buildBookingsPdfContent(),
              ] else ...[
                _buildRevenuePdfContent(),
              ],
            ],
          ),
        ),
      );

      // Save the PDF
      final output = await getTemporaryDirectory();
      final reportType = _selectedReport == 'bookings' ? 'bookings' : 'revenue';
      final date = DateFormat('yyyyMMdd').format(DateTime.now());
      final file = File('${output.path}/report_${reportType}_$date.pdf');
      await file.writeAsBytes(await pdf.save());

      // Show success message and open file
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Report exported successfully!'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => OpenFile.open(file.path),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting report: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  pw.Widget _buildBookingsPdfContent() {
    final confirmedBookings = _filteredBookings.where((b) => b.status.toLowerCase() == 'confirmed').length;
    final cancelledBookings = _filteredBookings.where((b) => b.status.toLowerCase() == 'cancelled').length;
    final pendingBookings = _filteredBookings.where((b) => b.status.toLowerCase() == 'pending').length;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildPdfStat('Total Bookings', _filteredBookings.length.toString()),
            _buildPdfStat('Confirmed', confirmedBookings.toString()),
            _buildPdfStat('Cancelled', cancelledBookings.toString()),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Booking Details',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              children: [
                _buildPdfTableHeader('Booking ID'),
                _buildPdfTableHeader('Date'),
                _buildPdfTableHeader('Status'),
                _buildPdfTableHeader('Seats'),
                _buildPdfTableHeader('Amount'),
              ],
            ),
            ..._filteredBookings.map((booking) => pw.TableRow(
              children: [
                _buildPdfTableCell(booking.id.toString()),
                _buildPdfTableCell(DateFormat('MM/dd/yyyy').format(booking.createdAt)),
                _buildPdfTableCell(booking.status),
                _buildPdfTableCell(booking.numberOfSeats.toString()),
                _buildPdfTableCell('RWF ${NumberFormat('#,###').format(booking.totalAmount)}'),
              ],
            )).toList(),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildRevenuePdfContent() {
    final totalRevenue = _filteredPayments
        .where((p) => p.status == 'completed')
        .fold<double>(0, (sum, payment) => sum + payment.amount);

    final dailyRevenue = <DateTime, double>{};
    for (final payment in _filteredPayments.where((p) => p.status == 'completed')) {
      final date = DateTime(
        payment.paymentDate.year,
        payment.paymentDate.month,
        payment.paymentDate.day,
      );
      dailyRevenue[date] = (dailyRevenue[date] ?? 0) + payment.amount;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPdfStat('Total Revenue', 'RWF ${NumberFormat('#,###').format(totalRevenue)}'),
        pw.SizedBox(height: 20),
        pw.Text(
          'Payment Details',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              children: [
                _buildPdfTableHeader('Date'),
                _buildPdfTableHeader('Transaction ID'),
                _buildPdfTableHeader('Method'),
                _buildPdfTableHeader('Amount'),
              ],
            ),
            ..._filteredPayments.where((p) => p.status == 'completed').map((payment) => pw.TableRow(
              children: [
                _buildPdfTableCell(DateFormat('MM/dd/yyyy').format(payment.paymentDate)),
                _buildPdfTableCell(payment.transactionId),
                _buildPdfTableCell(payment.paymentMethod),
                _buildPdfTableCell('RWF ${NumberFormat('#,###').format(payment.amount)}'),
              ],
            )).toList(),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfStat(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  pw.Widget _buildPdfTableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportReport,
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
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
              onPressed: _initializeData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _selectDateRange,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Report Period',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          const Icon(Icons.calendar_today, size: 20),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${DateFormat('MMM dd, yyyy').format(_dateRange.start)} - '
                        '${DateFormat('MMM dd, yyyy').format(_dateRange.end)}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'bookings',
                  label: Text('Bookings'),
                  icon: Icon(Icons.book),
                ),
                ButtonSegment(
                  value: 'revenue',
                  label: Text('Revenue'),
                  icon: Icon(Icons.monetization_on),
                ),
              ],
              selected: {_selectedReport},
              onSelectionChanged: (Set<String> selected) {
                setState(() {
                  _selectedReport = selected.first;
                });
              },
            ),
            const SizedBox(height: 24),
            _selectedReport == 'bookings'
                ? _buildBookingStats()
                : _buildRevenueStats(),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}