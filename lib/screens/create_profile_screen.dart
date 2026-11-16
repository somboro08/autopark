import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../database/database_helper.dart';
import '../models/app_user.dart';
import '../state/user_session.dart';
import '../theme/app_colors.dart';
import '../utils/route_animations.dart';
import 'home_screen.dart';
import 'owner_home_screen.dart';

/// Création d'un profil local (propriétaire ou agent de centre).
class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  AppRole _role = AppRole.owner;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final user = AppUser(
        role: _role,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );
      final id = await DatabaseHelper().insertUser(user);
      final created = user.copyWith(id: id);
      await UserSession.instance.signIn(created);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        AppRoute.fade(
          _role == AppRole.owner ? const OwnerHomeScreen() : const HomeScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de créer le profil : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau profil')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Type de profil', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _RoleCard(
              icon: Icons.two_wheeler,
              title: AppRole.owner.label,
              description: AppRole.owner.description,
              selected: _role == AppRole.owner,
              onTap: () => setState(() => _role = AppRole.owner),
            ),
            const SizedBox(height: 10),
            _RoleCard(
              icon: Iconsax.shop,
              title: AppRole.agent.label,
              description: AppRole.agent.description,
              selected: _role == AppRole.agent,
              onTap: () => setState(() => _role = AppRole.agent),
            ),
            const SizedBox(height: 28),
            Text('Informations', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                hintText: 'Ex: Jean Houngbo',
                prefixIcon: Icon(Iconsax.user),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 3) {
                  return 'Entrez un nom d\'au moins 3 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Téléphone (optionnel)',
                hintText: '+229 97 00 00 00',
                prefixIcon: Icon(Iconsax.call),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text('Créer le profil'),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ce profil reste sur cet appareil. Le partage entre appareils '
              'arrivera avec la synchronisation serveur.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold.withValues(alpha: 0.10)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.gold : theme.dividerColor,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 26,
              color: selected ? AppColors.gold : theme.iconTheme.color,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: selected ? AppColors.gold : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.gold, size: 22),
          ],
        ),
      ),
    );
  }
}
