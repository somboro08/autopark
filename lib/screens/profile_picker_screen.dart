import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../database/database_helper.dart';
import '../models/app_user.dart';
import '../state/user_session.dart';
import '../theme/app_colors.dart';
import '../utils/route_animations.dart';
import 'create_profile_screen.dart';
import 'home_screen.dart';
import 'owner_home_screen.dart';

/// Écran de sélection du profil local : propriétaire ou agent de centre.
///
/// Chaque profil garde ses propres données (motos, historique). C'est aussi
/// l'occasion de montrer les deux faces du produit.
class ProfilePickerScreen extends StatefulWidget {
  const ProfilePickerScreen({super.key});

  @override
  State<ProfilePickerScreen> createState() => _ProfilePickerScreenState();
}

class _ProfilePickerScreenState extends State<ProfilePickerScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<AppUser> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<AppUser> users;
    try {
      users = await _db.getUsers();
    } catch (_) {
      // Base indisponible (tests, premier lancement) : on affiche l'état vide.
      users = [];
    }
    if (!mounted) return;
    setState(() {
      _users = users;
      _loading = false;
    });
  }

  Future<void> _enterProfile(AppUser user) async {
    await UserSession.instance.signIn(user);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      AppRoute.fade(
        user.role == AppRole.owner ? const OwnerHomeScreen() : const HomeScreen(),
      ),
    );
  }

  Future<void> _createProfile() async {
    await Navigator.of(context).push(
      AppRoute.page(const CreateProfileScreen()),
    );
    _load();
  }

  Future<void> _deleteProfile(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce profil ?'),
        content: Text(
          'Le profil « ${user.name} » sera supprimé de cet appareil. '
          'Les véhicules et l\'historique liés resteront dans la base.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || user.id == null) return;
    await _db.deleteUser(user.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
                children: [
                  // Logo
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.two_wheeler,
                        size: 44,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'AutoPark',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Qui utilise l\'application ?',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),

                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_users.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Iconsax.profile_circle,
                            size: 40,
                            color: theme.disabledColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aucun profil sur cet appareil',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Créez un profil propriétaire pour enregistrer vos '
                            'motos, ou un profil agent pour gérer un centre.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  else
                    ..._users.map((user) => _ProfileTile(
                          user: user,
                          onTap: () => _enterProfile(user),
                          onDelete: () => _deleteProfile(user),
                        )),

                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _createProfile,
                    icon: const Icon(Iconsax.add_circle),
                    label: const Text('Créer un profil'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Les données restent sur cet appareil (SQLite).',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final AppUser user;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProfileTile({
    required this.user,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: theme.textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            user.role == AppRole.owner
                                ? Icons.two_wheeler
                                : Iconsax.shop,
                            size: 14,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user.role.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (user.phone != null) ...[
                            Text(
                              '  ·  ${user.phone}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'Supprimer',
                  icon: Icon(
                    Iconsax.trash,
                    size: 20,
                    color: theme.disabledColor,
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
