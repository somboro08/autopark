class ParkingCenter {
  final int? id;
  final String name;
  final String address;
  final int maxHoursDelay; // delay in hours before "non récupéré" status
  final DateTime createdAt;

  ParkingCenter({
    this.id,
    required this.name,
    required this.address,
    this.maxHoursDelay = 24,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'max_hours_delay': maxHoursDelay,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ParkingCenter.fromMap(Map<String, dynamic> map) {
    return ParkingCenter(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? '0'),
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      maxHoursDelay: map['max_hours_delay'] is int
          ? map['max_hours_delay']
          : int.tryParse(map['max_hours_delay']?.toString() ?? '24') ?? 24,
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
    DateTime? createdAt,
  }) {
    return ParkingCenter(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      maxHoursDelay: maxHoursDelay ?? this.maxHoursDelay,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ParkingCenter(id: $id, name: $name, address: $address, maxHoursDelay: $maxHoursDelay)';
  }
}
