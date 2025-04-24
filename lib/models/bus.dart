// lib/models/bus.dart
import 'package:intl/intl.dart';

class Bus {
  final int? id;
  final String busNumber;
  final int capacity;
  final String type;
  final bool isActive;
  final String busName;
  final String registrationNumber;
  final int routeId;
  final String departureTime;
  final String arrivalTime;
  final int totalSeats;
  final int availableSeats;
  final double price;
  final String fromLocation;
  final String toLocation;
  final String status;
  final DateTime? createdAt;
  final DateTime travelDate;
  final DateTime? updatedAt;

  Bus({
    this.id,
    required this.busNumber,
    required this.capacity,
    required this.type,
    this.isActive = true,
    required this.busName,
    required this.registrationNumber,
    required this.routeId,
    required this.departureTime,
    required this.arrivalTime,
    required this.totalSeats,
    required this.availableSeats,
    required this.price,
    required this.fromLocation,
    required this.toLocation,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
    required this.travelDate,
  });

  String get formattedPrice => NumberFormat.currency(
        symbol: 'RWF ',
        decimalDigits: 2,
      ).format(price);

  String get formattedDepartureTime => departureTime;
  String get formattedArrivalTime => arrivalTime;
  String get formattedTravelDate => DateFormat('yyyy-MM-dd').format(travelDate);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'busNumber': busNumber,
      'capacity': capacity,
      'type': type,
      'isActive': isActive ? 1 : 0,
      'busName': busName,
      'registrationNumber': registrationNumber,
      'routeId': routeId,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'price': price,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'travelDate': travelDate.toIso8601String(),
    };
  }

  factory Bus.fromMap(Map<String, dynamic> map) {
    return Bus(
      id: map['id'] as int?,
      busNumber: map['busNumber'] as String,
      capacity: map['capacity'] as int,
      type: map['type'] as String,
      isActive: map['isActive'] == 1,
      busName: map['busName'] as String,
      registrationNumber: map['registrationNumber'] as String,
      routeId: map['routeId'] as int,
      departureTime: map['departureTime'] as String,
      arrivalTime: map['arrivalTime'] as String,
      totalSeats: map['totalSeats'] as int,
      availableSeats: map['availableSeats'] as int,
      price: map['price'].toDouble(),
      fromLocation: map['fromLocation'] as String,
      toLocation: map['toLocation'] as String,
      status: map['status'] ?? 'active',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      travelDate: DateTime.parse(map['travelDate']),
    );
  }

  Bus copyWith({
    int? id,
    String? busNumber,
    int? capacity,
    String? type,
    bool? isActive,
    String? busName,
    String? registrationNumber,
    int? routeId,
    String? departureTime,
    String? arrivalTime,
    int? totalSeats,
    int? availableSeats,
    double? price,
    String? fromLocation,
    String? toLocation,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? travelDate,
  }) {
    return Bus(
      id: id ?? this.id,
      busNumber: busNumber ?? this.busNumber,
      capacity: capacity ?? this.capacity,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      busName: busName ?? this.busName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      routeId: routeId ?? this.routeId,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      totalSeats: totalSeats ?? this.totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      price: price ?? this.price,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      travelDate: travelDate ?? this.travelDate,
    );
  }

  DateTime getDepartureDateTime(DateTime date) {
    final timeParts = departureTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  DateTime getArrivalDateTime(DateTime date) {
    final timeParts = arrivalTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}
