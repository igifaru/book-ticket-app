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