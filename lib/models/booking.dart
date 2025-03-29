// lib/models/booking.dart
class Booking {
  final String id;
  final int userId;
  final String busId;
  final String fromLocation;
  final String toLocation;
  final String travelDate;
  final int passengers;
  final String seatNumbers;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String bookingStatus;
  final String? createdAt;
  bool notificationSent; // Added field to track if notifications have been sent

  Booking({
    required this.id,
    required this.userId,
    required this.busId,
    required this.fromLocation,
    required this.toLocation,
    required this.travelDate,
    required this.passengers,
    required this.seatNumbers,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.bookingStatus,
    this.createdAt,
    this.notificationSent = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'bus_id': busId,
      'from_location': fromLocation,
      'to_location': toLocation,
      'travel_date': travelDate,
      'passengers': passengers,
      'seat_numbers': seatNumbers,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'booking_status': bookingStatus,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'notification_sent': notificationSent ? 1 : 0,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'],
      userId: map['user_id'],
      busId: map['bus_id'],
      fromLocation: map['from_location'],
      toLocation: map['to_location'],
      travelDate: map['travel_date'],
      passengers: map['passengers'],
      seatNumbers: map['seat_numbers'],
      totalAmount: map['total_amount'],
      paymentMethod: map['payment_method'],
      paymentStatus: map['payment_status'],
      bookingStatus: map['booking_status'],
      createdAt: map['created_at'],
      notificationSent: map['notification_sent'] == 1,
    );
  }
}