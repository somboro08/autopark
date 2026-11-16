/// Rôle d'un utilisateur de l'application.
///
/// - [owner] : propriétaire d'une ou plusieurs motos. Il enregistre ses
///   véhicules dans son profil, obtient un QR / code d'identité et suit
///   l'historique de toutes ses gardes.
/// - [agent] : gardien / gestionnaire d'un centre de garde. Il enregistre les
///   dépôts et vérifie les identités à la sortie.
enum AppRole {
  owner,
  agent;

  String get label {
    switch (this) {
      case AppRole.owner:
        return 'Propriétaire';
      case AppRole.agent:
        return 'Agent de centre';
    }
  }

  String get description {
    switch (this) {
      case AppRole.owner:
        return "J'enregistre mes motos et je les partage avec les centres";
      case AppRole.agent:
        return 'Je gère un centre de garde et les dépôts de motos';
    }
  }

  static AppRole fromStorage(String? raw) {
    return raw == 'agent' ? AppRole.agent : AppRole.owner;
  }

  String get storageKey => name;
}

/// Profil local d'un utilisateur (MVP hors-ligne).
///
/// À terme, cette entité correspondra à un compte serveur authentifié.
class AppUser {
  final int? id;
  final AppRole role;
  final String name;
  final String? phone;
  final DateTime createdAt;

  AppUser({
    this.id,
    required this.role,
    required this.name,
    this.phone,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role.storageKey,
      'name': name,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] is int
          ? map['id']
          : int.tryParse(map['id']?.toString() ?? '0'),
      role: AppRole.fromStorage(map['role'] as String?),
      name: map['name'] ?? '',
      phone: map['phone'],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  AppUser copyWith({
    int? id,
    AppRole? role,
    String? name,
    String? phone,
  }) {
    return AppUser(
      id: id ?? this.id,
      role: role ?? this.role,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt,
    );
  }

  /// Initiales utilisées dans les avatars.
  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  String toString() => 'AppUser(id: $id, role: ${role.name}, name: $name)';
}
