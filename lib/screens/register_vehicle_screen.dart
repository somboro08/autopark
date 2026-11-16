import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/vehicle.dart';
import '../models/parking_center.dart';
import '../models/parking_session.dart';
import '../theme/app_colors.dart';
import '../utils/route_animations.dart';
import '../widgets/app_settings_sheet.dart';
import 'scan_qr_screen.dart';
import 'enter_code_screen.dart';
import 'add_center_screen.dart';
import 'centers_list_screen.dart';

class RegisterVehicleScreen extends StatefulWidget {
  const RegisterVehicleScreen({super.key});

  @override
  State<RegisterVehicleScreen> createState() => _RegisterVehicleScreenState();
}

class _RegisterVehicleScreenState extends State<RegisterVehicleScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final _plateController = TextEditingController();
  final _ownerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _qrController = TextEditingController();
  final _numericController = TextEditingController();

  ParkingCenter? _selectedCenter;
  List<ParkingCenter> _centers = [];
  bool _isLoadingCenters = true;
  bool _isSaving = false;
  String? _error;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadCenters();
  }

  Future<void> _loadCenters() async {
    final centers = await _db.getCenters();
    setState(() {
      _centers = centers;
      _isLoadingCenters = false;
      if (centers.isNotEmpty) _selectedCenter = centers.first;
    });
  }

  Future<void> _addCenter() async {
    await Navigator.of(context).push(
      AppRoute.page(const AddCenterScreen()),
    );
    _loadCenters();
  }

  Future<void> _scanQR() async {
    final result = await Navigator.of(context).push(
      AppRoute.page(const ScanQRScreen()),
    );
    if (result != null && result is String) {
      _qrController.text = result;
    }
  }

  Future<void> _enterCode() async {
    final result = await Navigator.of(context).push(
      AppRoute.page(const EnterCodeScreen()),
    );
    if (result != null && result is String) {
      _numericController.text = result;
    }
  }

  Future<void> _saveVehicle() async {
    if (_selectedCenter == null) {
      setState(() => _error = 'Veuillez sélectionner un centre');
      return;
    }
    if (_plateController.text.isEmpty || _ownerController.text.isEmpty) {
      setState(() => _error = 'Plaque et propriétaire requis');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final vehicle = Vehicle(
        plate: _plateController.text.trim().toUpperCase(),
        ownerName: _ownerController.text.trim(),
        ownerPhone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        centerId: _selectedCenter!.id!,
        qrCode: _qrController.text.trim().isEmpty ? null : _qrController.text.trim(),
        numericCode: _numericController.text.trim().isEmpty ? null : _numericController.text.trim(),
      );

      final vehicleId = await _db.insertVehicle(vehicle);

      // Create active parking session
      final session = ParkingSession(
        vehicleId: vehicleId,
        centerId: _selectedCenter!.id!,
        entryTime: DateTime.now(),
        status: SessionStatus.active,
      );
      await _db.insertSession(session);

      setState(() {
        _isSaving = false;
        _successMessage = 'Véhicule enregistré avec succès';
      });

      // Clear form
      _plateController.clear();
      _ownerController.clear();
      _phoneController.clear();
      _qrController.clear();
      _numericController.clear();
    } catch (e) {
      setState(() {
        _isSaving = false;
        _error = 'Erreur lors de l\'enregistrement: $e';
      });
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _qrController.dispose();
    _numericController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Enregistrer un auto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () => Navigator.of(context).push(
              AppRoute.page(const CentersListScreen()),
            ),
            tooltip: 'Mes centres',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showAppSettingsSheet(context),
            tooltip: 'Paramètres',
          ),
        ],
      ),
      body: _isLoadingCenters
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Center selection
                  if (_centers.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkDivider
                              : AppColors.lightDivider,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Centre de garde',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<ParkingCenter>(
                            value: _selectedCenter,
                            decoration: const InputDecoration(
                              hintText: 'Sélectionner un centre',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            items: _centers.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text('${c.name} - ${c.address}'),
                              );
                            }).toList(),
                            onChanged: (c) => setState(() => _selectedCenter = c),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Ajouter un centre'),
                              onPressed: _addCenter,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.location_off, size: 64, color: AppColors.gold),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun centre de garde',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ajoutez un centre avant d\'enregistrer un véhicule',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _addCenter,
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter un centre'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],

                  // Form fields
                  TextFormField(
                    controller: _plateController,
                    decoration: const InputDecoration(
                      labelText: 'Plaque de la moto',
                      hintText: 'Ex: AB-123-CD',
                      prefixIcon: Icon(Icons.confirmation_number),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ownerController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du propriétaire',
                      hintText: 'Ex: Jean Dupont',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone (optionnel)',
                      hintText: 'Ex: +229 XX XX XX XX',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _qrController,
                          decoration: const InputDecoration(
                            labelText: 'Code QR',
                            hintText: 'Code QR',
                            prefixIcon: Icon(Icons.qr_code),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.qr_code_scanner, size: 20),
                          label: const SizedBox.shrink(),
                          onPressed: _scanQR,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _numericController,
                          decoration: const InputDecoration(
                            labelText: 'Code numérique',
                            hintText: 'Code',
                            prefixIcon: Icon(Icons.numbers),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.input, size: 20),
                          label: const SizedBox.shrink(),
                          onPressed: _enterCode,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                        ],
                      ),
                    ),
                  if (_successMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2ECC71).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF2ECC71)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: const TextStyle(color: Color(0xFF2ECC71)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveVehicle,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Enregistrer le véhicule',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
