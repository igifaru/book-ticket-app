// lib/models/booking.dart
import 'package:intl/intl.dart';

class Booking {
  final int? id;
  final int userId;
  final int busId;
  final String fromLocation;
  final String toLocation;
  final DateTime travelDate;
  final int numberOfSeats;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final String? seatNumber;
  final String? paymentStatus;
  final int? confirmedBy;
  final DateTime? confirmedAt;

  Booking({
    this.id,
    required this.userId,
    required this.busId,
    required this.fromLocation,
    required this.toLocation,
    required this.travelDate,
    required this.numberOfSeats,
    required this.totalAmount,
    this.status = 'pending',
    this.seatNumber,
    this.paymentStatus = 'pending',
    DateTime? createdAt,
    this.confirmedBy,
    this.confirmedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    final now = DateTime.now().toIso8601String();
    final seatNumbers = List.generate(numberOfSeats, (index) => index + 1).join(',');
    
    return {
      'id': id,
      'userId': userId,
      'busId': busId,
      'numberOfSeats': numberOfSeats,
      'totalAmount': totalAmount,
      'status': status,
      'paymentStatus': paymentStatus ?? 'pending',
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'bookingDate': now,
      'journeyDate': travelDate.toIso8601String(),
      'seatNumber': seatNumber ?? seatNumbers,
      'createdAt': now,
      'confirmedBy': confirmedBy,
      'confirmedAt': confirmedAt?.toIso8601String(),
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      busId: map['busId'] as int,
      fromLocation: map['fromLocation'] as String,
      toLocation: map['toLocation'] as String,
      travelDate: DateTime.parse(map['journeyDate'] as String),
      numberOfSeats: map['numberOfSeats'] as int,
      totalAmount: map['totalAmount'] as double,
      status: map['status'] as String? ?? 'pending',
      seatNumber: map['seatNumber'] as String?,
      paymentStatus: map['paymentStatus'] as String? ?? 'pending',
      createdAt: DateTime.parse(map['createdAt'] as String),
      confirmedBy: map['confirmedBy'] as int?,
      confirmedAt: map['confirmedAt'] != null ? DateTime.parse(map['confirmedAt'] as String) : null,
    );
  }

  Booking copyWith({
    int? id,
    int? userId,
    int? busId,
    String? fromLocation,
    String? toLocation,
    DateTime? travelDate,
    int? numberOfSeats,
    double? totalAmount,
    String? status,
    String? seatNumber,
    String? paymentStatus,
    DateTime? createdAt,
    int? confirmedBy,
    DateTime? confirmedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      busId: busId ?? this.busId,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      travelDate: travelDate ?? this.travelDate,
      numberOfSeats: numberOfSeats ?? this.numberOfSeats,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      seatNumber: seatNumber ?? this.seatNumber,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }

  DateTime get journeyDate => travelDate;
}