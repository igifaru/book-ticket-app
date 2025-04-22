import 'package:intl/intl.dart';

class Payment {
  final int? id;
  final int bookingId;
  final double amount;
  final String status;
  final String paymentMethod;
  final String transactionId;
  final DateTime paymentDate;

  Payment({
    this.id,
    required this.bookingId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.transactionId,
    required this.paymentDate,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      bookingId: map['bookingId'] as int,
      amount: map['amount'] as double,
      status: map['status'] as String,
      paymentMethod: map['paymentMethod'] as String,
      transactionId: map['transactionId'] as String,
      paymentDate: DateTime.parse(map['paymentDate'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'amount': amount,
      'status': status,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'paymentDate': paymentDate.toIso8601String(),
    };
  }

  Payment copyWith({
    int? id,
    int? bookingId,
    double? amount,
    String? status,
    String? paymentMethod,
    String? transactionId,
    DateTime? paymentDate,
  }) {
    return Payment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      paymentDate: paymentDate ?? this.paymentDate,
    );
  }
}