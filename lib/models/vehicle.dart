class Vehicle {
  final int? id;
  final String plate;
  final String ownerName;
  final String? ownerPhone;
  final int centerId;
  final String? qrCode;
  final String? numericCode;
  final String? photoPath;
  final DateTime createdAt;

  Vehicle({
    this.id,
    required this.plate,
    required this.ownerName,
    this.ownerPhone,
    required this.centerId,
    this.qrCode,
    this.numericCode,
    this.photoPath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plate': plate,
      'owner_name': ownerName,
      'owner_phone': ownerPhone,
      'center_id': centerId,
      'qr_code': qrCode,
      'numeric_code': numericCode,
      'photo_path': photoPath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? '0'),
      plate: map['plate'] ?? '',
      ownerName: map['owner_name'] ?? '',
      ownerPhone: map['owner_phone'],
      centerId: map['center_id'] is int
          ? map['center_id']
          : int.tryParse(map['center_id']?.toString() ?? '0') ?? 0,
      qrCode: map['qr_code'],
      numericCode: map['numeric_code'],
      photoPath: map['photo_path'],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Vehicle copyWith({
    int? id,
    String? plate,
    String? ownerName,
    String? ownerPhone,
    int? centerId,
    String? qrCode,
    String? numericCode,
    String? photoPath,
    DateTime? createdAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      plate: plate ?? this.plate,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      centerId: centerId ?? this.centerId,
      qrCode: qrCode ?? this.qrCode,
      numericCode: numericCode ?? this.numericCode,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Vehicle(id: $id, plate: $plate, owner: $ownerName, centerId: $centerId)';
  }
}
