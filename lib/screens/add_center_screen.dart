import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/parking_center.dart';
import '../theme/app_colors.dart';

class AddCenterScreen extends StatefulWidget {
  const AddCenterScreen({super.key});

  @override
  State<AddCenterScreen> createState() => _AddCenterScreenState();
}

class _AddCenterScreenState extends State<AddCenterScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _delayController = TextEditingController(text: '24');
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _delayController.dispose();
    super.dispose();
  }

  Future<void> _saveCenter() async {
    if (_nameController.text.isEmpty || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom et adresse requis')),
      );
      return;
    }
    final delay = int.tryParse(_delayController.text) ?? 24;

    setState(() => _isSaving = true);
    try {
      final center = ParkingCenter(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        maxHoursDelay: delay,
      );
      await _db.insertCenter(center);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ajouter un centre'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(Icons.location_city, color: AppColors.gold, size: 32),
            ),
            const SizedBox(height: 24),
            Text('Nouveau centre de garde', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Définissez les informations de votre centre',
                style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du centre',
                hintText: 'Ex: Gardien Sécurité Cotonou',
                prefixIcon: Icon(Icons.location_city),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adresse',
                hintText: 'Ex: Quartier X, Rue Y',
                prefixIcon: Icon(Icons.map),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _delayController,
              decoration: const InputDecoration(
                labelText: 'Délai de garde (heures)',
                hintText: '24',
                prefixIcon: Icon(Icons.access_time),
                suffixText: 'heures',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            Text(
              'Délai après lequel un véhicule non récupéré passe en statut "Non récupéré".',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveCenter,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Créer le centre',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
