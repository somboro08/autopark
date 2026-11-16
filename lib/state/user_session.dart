import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/app_user.dart';

/// Profil actuellement actif sur l'appareil (MVP hors-ligne).
///
/// À terme, ce sera une session authentifiée par le serveur ; l'interface ne
/// change pas, seule l'implémentation du stockage évolue.
class UserSession {
  UserSession._();

  static final UserSession instance = UserSession._();

  static const String _activeUserKey = 'active_user_id';

  final ValueNotifier<AppUser?> current = ValueNotifier<AppUser?>(null);

  bool get isSignedIn => current.value != null;

  AppRole? get role => current.value?.role;

  /// Restaure le dernier profil utilisé (au démarrage).
  Future<AppUser?> restore() async {
    final db = DatabaseHelper();
    final raw = await db.getSetting(_activeUserKey);
    final id = raw == null ? null : int.tryParse(raw);
    if (id == null) {
      current.value = null;
      return null;
    }
    final user = await db.getUserById(id);
    current.value = user;
    return user;
  }

  Future<void> signIn(AppUser user) async {
    current.value = user;
    await DatabaseHelper().setSetting(_activeUserKey, user.id?.toString());
  }

  Future<void> signOut() async {
    current.value = null;
    await DatabaseHelper().setSetting(_activeUserKey, null);
  }

  /// Rafraîchit le profil en mémoire après une modification.
  Future<void> refresh() async {
    final user = current.value;
    if (user?.id == null) return;
    final fresh = await DatabaseHelper().getUserById(user!.id!);
    current.value = fresh;
  }
}
