import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/booking.dart';
import '../models/payment.dart';
import '../utils/date_formatter.dart';
import '../screens/user/user_dashboard.dart';

class TicketScreen extends StatelessWidget {
  final Booking booking;
  final Payment payment;

  const TicketScreen({
    super.key,
    required this.booking,
    required this.payment,
  });

  Future<void> _shareTicket(BuildContext context) async {
    try {
      debugPrint('TicketScreen: Sharing ticket details...');
      final text = '''
🎫 Bus Ticket Details
------------------
Booking ID: ${booking.id}
From: ${booking.fromLocation}
To: ${booking.toLocation}
Journey Date: ${DateFormatter.format(booking.journeyDate)}
Seats: ${booking.numberOfSeats}
Amount Paid: ₹${booking.totalAmount}
Status: Confirmed

Please show this ticket at the counter for verification.
''';

      await Share.share(text, subject: 'Bus Ticket Details');
      debugPrint('TicketScreen: Ticket details shared successfully');
    } catch (e) {
      debugPrint('TicketScreen: Error sharing ticket: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing ticket: $e')),
      );
    }
  }

  Future<File> _generatePdf() async {
    debugPrint('TicketScreen: Generating PDF ticket...');
    final pdf = pw.Document();

    try {
      // Create QR code data
      debugPrint('TicketScreen: Generating QR code...');
      final qrCode = await _generateQrCode('TICKET:${booking.id}');
      debugPrint('TicketScreen: QR code generated successfully');

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header with QR Code
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'BUS TICKET',
                              style: pw.TextStyle(
                                fontSize: 24,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Booking ID: ${booking.id}',
                              style: const pw.TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      qrCode != null
                          ? pw.Image(qrCode, width: 80, height: 80)
                          : pw.Container(),
                    ],
                  ),
                  pw.SizedBox(height: 20),

                  // Ticket Details Box
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    padding: const pw.EdgeInsets.all(16),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildPdfRow('From', booking.fromLocation),
                        _buildPdfDivider(),
                        _buildPdfRow('To', booking.toLocation),
                        _buildPdfDivider(),
                        _buildPdfRow('Journey Date', DateFormatter.format(booking.journeyDate)),
                        _buildPdfDivider(),
                        _buildPdfRow('Departure Time', booking.travelDate.toString().split(' ')[1].substring(0, 5)),
                        _buildPdfDivider(),
                        _buildPdfRow('Number of Seats', booking.numberOfSeats.toString()),
                        _buildPdfDivider(),
                        _buildPdfRow('Seat Number', booking.seatNumber ?? 'Not Assigned'),
                        _buildPdfDivider(),
                        _buildPdfRow('Amount Paid', '₹${booking.totalAmount}'),
                        _buildPdfDivider(),
                        _buildPdfRow('Payment Status', 'Confirmed'),
                        _buildPdfDivider(),
                        _buildPdfRow('Transaction ID', payment.transactionId),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Important Information
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Important Information:',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          '• Please arrive at least 15 minutes before departure\n'
                          '• Show this ticket at the counter for verification\n'
                          '• Carry a valid ID proof while traveling\n'
                          '• No refund on cancellation',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            lineSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      debugPrint('TicketScreen: Getting application directory...');
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/ticket_${booking.id}.pdf');
      
      debugPrint('TicketScreen: Saving PDF file...');
      await file.writeAsBytes(await pdf.save());
      debugPrint('TicketScreen: PDF saved successfully at ${file.path}');
      
      return file;
    } catch (e) {
      debugPrint('TicketScreen: Error generating PDF: $e');
      throw Exception('Failed to generate PDF ticket: $e');
    }
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(': '),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  pw.Widget _buildPdfDivider() {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 8),
      height: 1,
      color: PdfColors.grey300,
    );
  }

  Future<pw.ImageProvider?> _generateQrCode(String data) async {
    try {
      final qrPainter = QrPainter(
        data: data,
        version: QrVersions.auto,
        color: Colors.black,
        emptyColor: Colors.white,
      );
      
      final qrImage = await qrPainter.toImageData(200);
      if (qrImage != null) {
        return pw.MemoryImage(qrImage.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint('Error generating QR code: $e');
    }
    return null;
  }

  Future<void> _downloadTicket(BuildContext context) async {
    try {
      debugPrint('TicketScreen: Starting ticket download...');
      final File pdfFile = await _generatePdf();
      
      debugPrint('TicketScreen: Showing success message...');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Ticket saved as PDF: ${pdfFile.path}'),
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () async {
              debugPrint('TicketScreen: Sharing PDF file...');
              await Share.shareXFiles(
                [XFile(pdfFile.path)],
                subject: 'Bus Ticket Details',
              );
            },
          ),
        ),
      );

      debugPrint('TicketScreen: Opening print dialog...');
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          return await pdfFile.readAsBytes();
        },
        name: 'Bus Ticket - ${booking.id}',
      );
      debugPrint('TicketScreen: Print dialog closed');
    } catch (e) {
      debugPrint('TicketScreen: Error in download process: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading ticket: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('TicketScreen: Building ticket screen...');
    return WillPopScope(
      onWillPop: () async {
        debugPrint('TicketScreen: Back button pressed, navigating to home...');
        _navigateToHome(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ticket Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _navigateToHome(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareTicket(context),
              tooltip: 'Share Ticket',
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadTicket(context),
              tooltip: 'Download Ticket',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success Message
              Card(
                color: Colors.green,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: const [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 48,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Payment Successful!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your ticket has been booked',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Ticket Card
              Card(
                child: Column(
                  children: [
                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        children: [
                          QrImageView(
                            data: 'TICKET:${booking.id}',
                            version: QrVersions.auto,
                            size: 150.0,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Booking ID: ${booking.id}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Ticket Details
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'From',
                            booking.fromLocation,
                            Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'To',
                            booking.toLocation,
                            Icons.location_on,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Journey Date',
                            DateFormatter.format(booking.journeyDate),
                            Icons.calendar_today,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Seat Number',
                            booking.seatNumber ?? 'Not Assigned',
                            Icons.event_seat,
                          ),
                          const Divider(height: 32),
                          _buildDetailRow(
                            'Amount Paid',
                            '₹${booking.totalAmount}',
                            Icons.payment,
                            valueStyle: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Important Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Important Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Please arrive at least 15 minutes before departure\n'
                        '• Show this ticket at the counter for verification\n'
                        '• Carry a valid ID proof while traveling\n'
                        '• No refund on cancellation',
                        style: TextStyle(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton(
              onPressed: () => _navigateToHome(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Back to Home',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    debugPrint('TicketScreen: Navigating to home screen...');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const UserDashboard()),
      (route) => false,
    );
    debugPrint('TicketScreen: Navigation complete');
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    TextStyle? valueStyle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
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
                style: valueStyle ??
                    const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 