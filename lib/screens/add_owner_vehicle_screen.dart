import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../database/database_helper.dart';
import '../models/vehicle.dart';
import '../state/user_session.dart';
import '../theme/app_colors.dart';

/// Enregistrement d'une moto dans le profil du propriétaire.
///
/// Le QR code et le code numérique sont générés automatiquement : ce sont les
/// codes d'identité du véhicule, que le propriétaire partagera avec les centres.
class AddOwnerVehicleScreen extends StatefulWidget {
  const AddOwnerVehicleScreen({super.key});

  @override
  State<AddOwnerVehicleScreen> createState() => _AddOwnerVehicleScreenState();
}

class _AddOwnerVehicleScreenState extends State<AddOwnerVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _modelController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _plateController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = UserSession.instance.current.value;
    if (user?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun profil actif')),
      );
      return;
    }

    setState(() => _saving = true);
    final db = DatabaseHelper();
    final plate = _plateController.text.trim().toUpperCase();

    try {
      // Une même plaque ne doit pas être enregistrée deux fois pour le même
      // propriétaire.
      final existing = await db.getVehiclesByOwner(user!.id!);
      if (existing.any((v) => v.plate.toUpperCase() == plate)) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('La moto $plate est déjà dans votre profil'),
          ),
        );
        return;
      }

      await db.insertVehicle(Vehicle(
        plate: plate,
        ownerName: user.name,
        ownerPhone: user.phone,
        ownerId: user.id,
        model: _modelController.text.trim().isEmpty
            ? null
            : _modelController.text.trim(),
        qrCode: db.generateVehicleQrCode(),
        numericCode: db.generateNumericCode(),
      ));

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enregistrement impossible : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle moto')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Iconsax.shield_tick, color: AppColors.gold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Un QR code et un code numérique uniques seront générés. '
                      'Présentez-les au gardien pour enregistrer la moto dans '
                      'un centre, sans jamais redonner vos informations.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _plateController,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Plaque d\'immatriculation',
                hintText: 'Ex: AB-123-CD',
                prefixIcon: Icon(Iconsax.card),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 4) {
                  return 'Entrez une plaque valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _modelController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: 'Modèle (optionnel)',
                hintText: 'Ex: Yamaha Crypton',
                prefixIcon: Icon(Icons.two_wheeler),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text('Enregistrer ma moto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
