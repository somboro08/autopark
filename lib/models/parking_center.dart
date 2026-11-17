/// Centre de garde de motos.
///
/// La position géographique ([latitude] / [longitude]) est optionnelle : un
/// centre sans position reste visible dans l'annuaire mais n'apparaît pas sur
/// la carte.
class ParkingCenter {
  final int? id;
  final String name;
  final String address;
  final int maxHoursDelay; // delay in hours before "non récupéré" status
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  ParkingCenter({
    this.id,
    required this.name,
    required this.address,
    this.maxHoursDelay = 24,
    this.latitude,
    this.longitude,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get hasLocation => latitude != null && longitude != null;

  String get coordinatesLabel {
    if (!hasLocation) return 'Position non renseignée';
    return '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'max_hours_delay': maxHoursDelay,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ParkingCenter.fromMap(Map<String, dynamic> map) {
    double? asDouble(Object? value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return ParkingCenter(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? '0'),
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      maxHoursDelay: map['max_hours_delay'] is int
          ? map['max_hours_delay']
          : int.tryParse(map['max_hours_delay']?.toString() ?? '24') ?? 24,
      latitude: asDouble(map['latitude']),
      longitude: asDouble(map['longitude']),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  ParkingCenter copyWith({
    int? id,
    String? name,
    String? address,
    int? maxHoursDelay,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    return ParkingCenter(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      maxHoursDelay: maxHoursDelay ?? this.maxHoursDelay,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ParkingCenter(id: $id, name: $name, address: $address, '
        'maxHoursDelay: $maxHoursDelay, lat: $latitude, lng: $longitude)';
  }
}
