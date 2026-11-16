import 'package:flutter/material.dart';

enum SessionStatus {
  active,       // en cours
  retrieved,    // récupéré
  notRetrieved, // non récupéré (dépassé le délai)
}

class ParkingSession {
  final int? id;
  final int vehicleId;
  final int centerId;
  final DateTime entryTime;
  final DateTime? exitTime;
  final SessionStatus status;
  final String? notes;

  /// Jeton de récupération, généré à l'entrée et stocké de façon sécurisée
  /// sur le téléphone du propriétaire. Il ne sert qu'à libérer le véhicule et
  /// n'est jamais réutilisable (phase sécurité).
  final String? retrievalToken;

  ParkingSession({
    this.id,
    required this.vehicleId,
    required this.centerId,
    required this.entryTime,
    this.exitTime,
    this.status = SessionStatus.active,
    this.notes,
    this.retrievalToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'center_id': centerId,
      'entry_time': entryTime.toIso8601String(),
      'exit_time': exitTime?.toIso8601String(),
      'status': status.index,
      'notes': notes,
      'retrieval_token': retrievalToken,
    };
  }

  factory ParkingSession.fromMap(Map<String, dynamic> map) {
    return ParkingSession(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? '0'),
      vehicleId: map['vehicle_id'] is int
          ? map['vehicle_id']
          : int.tryParse(map['vehicle_id']?.toString() ?? '0') ?? 0,
      centerId: map['center_id'] is int
          ? map['center_id']
          : int.tryParse(map['center_id']?.toString() ?? '0') ?? 0,
      entryTime: map['entry_time'] != null
          ? DateTime.tryParse(map['entry_time']) ?? DateTime.now()
          : DateTime.now(),
      exitTime: map['exit_time'] != null
          ? DateTime.tryParse(map['exit_time'])
          : null,
      status: SessionStatus.values[map['status'] ?? 0],
      notes: map['notes'],
      retrievalToken: map['retrieval_token'],
    );
  }

  /// Returns the effective status taking into account the center's max delay.
  /// An active session becomes "notRetrieved" once the delay is exceeded.
  SessionStatus effectiveStatus(int maxHoursDelay) {
    if (status == SessionStatus.retrieved) return SessionStatus.retrieved;
    if (status == SessionStatus.notRetrieved) return SessionStatus.notRetrieved;
    final deadline = entryTime.add(Duration(hours: maxHoursDelay));
    return deadline.isBefore(DateTime.now())
        ? SessionStatus.notRetrieved
        : SessionStatus.active;
  }

  String get statusLabel {
    switch (status) {
      case SessionStatus.active:
        return 'En cours';
      case SessionStatus.retrieved:
        return 'Récupéré';
      case SessionStatus.notRetrieved:
        return 'Non récupéré';
    }
  }

  Color get statusColor {
    switch (status) {
      case SessionStatus.active:
        return const Color(0xFF2ECC71);
      case SessionStatus.retrieved:
        return const Color(0xFF3498DB);
      case SessionStatus.notRetrieved:
        return const Color(0xFFE74C3C);
    }
  }

  ParkingSession copyWith({
    int? id,
    int? vehicleId,
    int? centerId,
    DateTime? entryTime,
    DateTime? exitTime,
    SessionStatus? status,
    String? notes,
    String? retrievalToken,
  }) {
    return ParkingSession(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      centerId: centerId ?? this.centerId,
      entryTime: entryTime ?? this.entryTime,
      exitTime: exitTime ?? this.exitTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      retrievalToken: retrievalToken ?? this.retrievalToken,
    );
  }

  @override
  String toString() {
    return 'ParkingSession(id: $id, vehicleId: $vehicleId, status: $status)';
  }
}
