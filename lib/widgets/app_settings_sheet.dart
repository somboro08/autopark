import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/app_user.dart';
import '../screens/profile_picker_screen.dart';
import '../state/user_session.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';
import '../utils/route_animations.dart';

/// Smooth WhatsApp-like bottom sheet for app settings (theme switching).
Future<void> showAppSettingsSheet(BuildContext context) {
  final navigator = Navigator.of(context);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Paramètres', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('Apparence de l\'application', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),

              // Profil actif
              ValueListenableBuilder<AppUser?>(
                valueListenable: UserSession.instance.current,
                builder: (context, user, _) {
                  if (user == null) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(21),
                          ),
                          child: Text(
                            user.initials,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: theme.textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user.role.label,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                  color: AppColors.gold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            navigator.pop();
                            await UserSession.instance.signOut();
                            navigator.pushAndRemoveUntil(
                              AppRoute.fade(const ProfilePickerScreen()),
                              (_) => false,
                            );
                          },
                          child: const Text('Changer'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              Text('Thème', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeController.themeMode,
                builder: (context, mode, _) {
                  return Column(
                    children: [
                      _themeOption(ctx, mode, ThemeMode.system, Icons.brightness_auto, 'Système'),
                      _themeOption(ctx, mode, ThemeMode.light, Icons.light_mode, 'Clair'),
                      _themeOption(ctx, mode, ThemeMode.dark, Icons.dark_mode, 'Sombre'),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Text('Données', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _dataOption(
                ctx,
                icon: Icons.restart_alt,
                label: 'Recharger les données de démo',
                color: AppColors.gold,
                onTap: () async {
                  final db = DatabaseHelper();
                  await db.clearAllData();
                  await db.seedDemoDataIfEmpty();
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Données de démo rechargées')),
                    );
                  }
                },
              ),
              _dataOption(
                ctx,
                icon: Icons.delete_forever,
                label: 'Effacer toutes les données',
                color: Colors.redAccent,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: ctx,
                    builder: (dctx) => AlertDialog(
                      title: const Text('Effacer toutes les données ?'),
                      content: const Text(
                        'Centres, véhicules et sessions seront supprimés définitivement.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dctx, false),
                          child: const Text('Annuler'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(dctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Effacer'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await DatabaseHelper().clearAllData();
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Toutes les données ont été effacées')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              Text(
                'AutoPark — MVP de sécurisation des parkings motos',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
              ),
            ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _dataOption(
  BuildContext context, {
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.chevron_right, color: Theme.of(context).dividerColor),
          ],
        ),
      ),
    ),
  );
}

Widget _themeOption(
  BuildContext context,
  ThemeMode current,
  ThemeMode value,
  IconData icon,
  String label,
) {
  final selected = current == value;
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => ThemeController.setMode(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.gold : Theme.of(context).dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.gold : null),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.gold, size: 20),
          ],
        ),
      ),
    ),
  );
}
