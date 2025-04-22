import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import '../services/payment_service.dart';
import 'ticket_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Booking booking;
  final double amount;

  const PaymentScreen({
    super.key,
    required this.booking,
    required this.amount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedPaymentMethod = 'card';
  bool isProcessing = false;
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final payment = await context.read<PaymentService>().processPayment(
            bookingId: widget.booking.id!,
            amount: widget.amount,
            paymentMethod: selectedPaymentMethod,
          );

      if (!mounted) return;

      if (payment == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment processing failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TicketScreen(
            booking: widget.booking,
            payment: payment,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount to Pay',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${widget.amount}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Payment Method Selection
            Text(
              'Select Payment Method',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('Credit/Debit Card'),
                    value: 'card',
                    groupValue: selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        selectedPaymentMethod = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('UPI'),
                    value: 'upi',
                    groupValue: selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        selectedPaymentMethod = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Net Banking'),
                    value: 'netbanking',
                    groupValue: selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        selectedPaymentMethod = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Payment Details Form
            if (selectedPaymentMethod == 'card')
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Card Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cardNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Card Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter card number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _expiryController,
                            decoration: const InputDecoration(
                              labelText: 'MM/YY',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _cvvController,
                            decoration: const InputDecoration(
                              labelText: 'CVV',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name on Card',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter name on card';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
            // Pay Button
            ElevatedButton(
              onPressed: isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Pay ₹${widget.amount}',
                      style: const TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }
} 