class Route {
  final int? id;
  final String startLocation;
  final String endLocation;
  final String viaLocations;
  final double distance;
  final int estimatedDuration;
  final String description;
  final bool isActive;

  Route({
    this.id,
    required this.startLocation,
    required this.endLocation,
    this.viaLocations = '',
    required this.distance,
    required this.estimatedDuration,
    required this.description,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'viaLocations': viaLocations,
      'distance': distance,
      'estimatedDuration': estimatedDuration,
      'description': description,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Route.fromMap(Map<String, dynamic> map) {
    return Route(
      id: map['id'] as int?,
      startLocation: map['startLocation'] as String,
      endLocation: map['endLocation'] as String,
      viaLocations: map['viaLocations'] as String? ?? '',
      distance: map['distance'] as double,
      estimatedDuration: map['estimatedDuration'] as int,
      description: map['description'] as String? ?? '',
      isActive: map['isActive'] == 1,
    );
  }

  Route copyWith({
    int? id,
    String? startLocation,
    String? endLocation,
    String? viaLocations,
    double? distance,
    int? estimatedDuration,
    String? description,
    bool? isActive,
  }) {
    return Route(
      id: id ?? this.id,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      viaLocations: viaLocations ?? this.viaLocations,
      distance: distance ?? this.distance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return '$startLocation to $endLocation via $viaLocations';
  }
}

class BusRoute {
  final int? id;
  final String fromLocation;
  final String toLocation;
  final double distance;
  final double duration;
  final double price;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get startLocation => fromLocation;
  String get endLocation => toLocation;

  BusRoute({
    this.id,
    required this.fromLocation,
    required this.toLocation,
    required this.distance,
    required this.duration,
    required this.price,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory BusRoute.fromMap(Map<String, dynamic> map) {
    return BusRoute(
      id: map['id'] as int?,
      fromLocation: map['fromLocation'] as String,
      toLocation: map['toLocation'] as String,
      distance: (map['distance'] as num).toDouble(),
      duration: (map['duration'] as num).toDouble(),
      price: (map['price'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'distance': distance,
      'duration': duration,
      'price': price,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BusRoute copyWith({
    int? id,
    String? fromLocation,
    String? toLocation,
    double? distance,
    double? duration,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusRoute(
      id: id ?? this.id,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'BusRoute(id: $id, fromLocation: $fromLocation, toLocation: $toLocation, distance: $distance, duration: $duration, price: $price)';
  }
} 