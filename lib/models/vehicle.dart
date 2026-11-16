/// Véhicule (moto) enregistré dans AutoPark.
///
/// Un véhicule porte deux identités distinctes :
/// - son **identité de véhicule** (`qrCode` + `numericCode`) : statique,
///   partageable, elle sert à s'enregistrer dans un nouveau centre ;
/// - son **identité de garde** (jeton dynamique) : portée par la session de
///   parking, jamais par le véhicule.
///
/// [ownerId] référence le profil propriétaire lorsqu'il possède un compte dans
/// l'application. [centerId] est nul tant que le véhicule n'a pas été rattaché
/// à un centre de garde.
class Vehicle {
  final int? id;
  final String plate;
  final String ownerName;
  final String? ownerPhone;
  final int? centerId;
  final int? ownerId;
  final String? model;
  final String? qrCode;
  final String? numericCode;
  final String? photoPath;
  final DateTime createdAt;

  Vehicle({
    this.id,
    required this.plate,
    required this.ownerName,
    this.ownerPhone,
    this.centerId,
    this.ownerId,
    this.model,
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
      'owner_id': ownerId,
      'model': model,
      'qr_code': qrCode,
      'numeric_code': numericCode,
      'photo_path': photoPath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    int? asInt(Object? value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return Vehicle(
      id: asInt(map['id']),
      plate: map['plate'] ?? '',
      ownerName: map['owner_name'] ?? '',
      ownerPhone: map['owner_phone'],
      centerId: asInt(map['center_id']),
      ownerId: asInt(map['owner_id']),
      model: map['model'],
      qrCode: map['qr_code'],
      numericCode: map['numeric_code'],
      photoPath: map['photo_path'],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Libellé court : plaque + modèle si disponible.
  String get displayLabel {
    final m = model?.trim();
    if (m == null || m.isEmpty) return plate.toUpperCase();
    return '${plate.toUpperCase()} · $m';
  }

  Vehicle copyWith({
    int? id,
    String? plate,
    String? ownerName,
    String? ownerPhone,
    int? centerId,
    int? ownerId,
    String? model,
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
      ownerId: ownerId ?? this.ownerId,
      model: model ?? this.model,
      qrCode: qrCode ?? this.qrCode,
      numericCode: numericCode ?? this.numericCode,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Vehicle(id: $id, plate: $plate, ownerId: $ownerId, centerId: $centerId)';
  }
}
