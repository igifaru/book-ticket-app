// lib/models/bus.dart (updated)
class Bus {
  final String id;
  final String name;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final double price;
  final int availableSeats;
  final String busType;
  final List<String> features;

  Bus({
    required this.id,
    required this.name,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.price,
    required this.availableSeats,
    required this.busType,
    required this.features,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'departure_time': departureTime,
      'arrival_time': arrivalTime,
      'duration': duration,
      'price': price,
      'available_seats': availableSeats,
      'bus_type': busType,
      'features': features.join(','),
    };
  }

  factory Bus.fromMap(Map<String, dynamic> map) {
    return Bus(
      id: map['id'],
      name: map['name'],
      departureTime: map['departure_time'],
      arrivalTime: map['arrival_time'],
      duration: map['duration'],
      price: map['price'],
      availableSeats: map['available_seats'],
      busType: map['bus_type'],
      features: map['features'].split(','),
    );
  }
}