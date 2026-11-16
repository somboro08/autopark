import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/vehicle.dart';
import '../models/parking_session.dart';
import '../models/parking_center.dart';
import '../theme/app_colors.dart';
import '../utils/route_animations.dart';
import '../widgets/app_settings_sheet.dart';
import '../widgets/status_badge.dart';
import 'vehicle_info_screen.dart';
import 'scan_qr_screen.dart';
import 'enter_code_screen.dart';
import 'centers_list_screen.dart';

class RetrieveVehicleScreen extends StatefulWidget {
  const RetrieveVehicleScreen({super.key});

  @override
  State<RetrieveVehicleScreen> createState() => _RetrieveVehicleScreenState();
}

class _RetrieveVehicleScreenState extends State<RetrieveVehicleScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  Vehicle? _foundVehicle;
  ParkingSession? _activeSession;
  ParkingCenter? _foundCenter;
  bool _isLoading = false;
  String? _error;
  String? _successMessage;
  bool? _plateVerified; // null = not checked, true = match, false = mismatch

  /// Simulates scanning the physical plate and verifies it against the
  /// stored vehicle associated with the QR/numeric code.
  Future<void> _verifyPlate() async {
    if (_foundVehicle == null) return;
    final plate = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final controller = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.document_scanner, color: AppColors.gold),
                    const SizedBox(width: 10),
                    Text('Scanner la plaque', style: Theme.of(ctx).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Saisissez ou scannez la plaque de la moto présente.',
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Plaque',
                    hintText: 'Ex: AB-123-CD',
                    prefixIcon: Icon(Icons.confirmation_number),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Vérifier la plaque'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (plate == null || plate.isEmpty) return;
    final normalize = (String s) =>
        s.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final matches = normalize(plate) == normalize(_foundVehicle!.plate);
    setState(() {
      _plateVerified = matches;
      if (matches) {
        _successMessage = 'Plaque vérifiée — correspondance confirmée';
        _error = null;
      } else {
        _error = 'La plaque ne correspond pas au véhicule enregistré';
        _successMessage = null;
      }
    });
  }

  Future<void> _scanQR() async {
    final result = await Navigator.of(context).push(
      AppRoute.page(const ScanQRScreen()),
    );
    if (result != null && result is String) {
      _lookupByCode(result);
    }
  }

  Future<void> _enterCode() async {
    final result = await Navigator.of(context).push(
      AppRoute.page(const EnterCodeScreen()),
    );
    if (result != null && result is String) {
      _lookupByCode(result);
    }
  }

  Future<void> _lookupByCode(String code) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _successMessage = null;
      _foundVehicle = null;
      _activeSession = null;
      _foundCenter = null;
      _plateVerified = null;
    });

    try {
      Vehicle? vehicle = await _db.getVehicleByQrCode(code);
      if (vehicle == null) {
        vehicle = await _db.getVehicleByNumericCode(code);
      }

      if (vehicle == null) {
        setState(() {
          _error = 'Aucun véhicule trouvé avec ce code';
          _isLoading = false;
        });
        return;
      }

      final session = await _db.getActiveSessionForVehicle(vehicle.id!);
      final center = await _db.getCenterById(vehicle.centerId);

      setState(() {
        _foundVehicle = vehicle;
        _activeSession = session;
        _foundCenter = center;
        _isLoading = false;
        _successMessage = 'Véhicule trouvé';
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la recherche: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openVehicleInfo() async {
    if (_foundVehicle == null) return;
    await Navigator.of(context).push(
      AppRoute.page(
        VehicleInfoScreen(
          vehicle: _foundVehicle!,
          session: _activeSession,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Retrouver un auto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () => Navigator.of(context).push(
              AppRoute.page(const CentersListScreen()),
            ),
            tooltip: 'Mes centres / Liste du jour',
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanQR,
            tooltip: 'Scanner QR',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showAppSettingsSheet(context),
            tooltip: 'Paramètres',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.qr_code_scanner,
                    label: 'Scanner QR',
                    color: AppColors.gold,
                    onPressed: _scanQR,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.input,
                    label: 'Saisir code',
                    color: theme.colorScheme.primary,
                    onPressed: _enterCode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            TextField(
              decoration: InputDecoration(
                hintText: 'Plate, code QR ou code numérique',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _isLoading ? null : () {},
                      ),
              ),
              onSubmitted: (value) => _lookupByCode(value),
            ),
            const SizedBox(height: 20),

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

            if (_foundVehicle != null) ...[
              _buildVehicleInfoCard(),
              const SizedBox(height: 16),

              // Plate verification
              if (_plateVerified == null)
                OutlinedButton.icon(
                  onPressed: _verifyPlate,
                  icon: const Icon(Icons.document_scanner),
                  label: const Text('Scanner et vérifier la plaque'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    side: const BorderSide(color: AppColors.gold, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                )
              else if (_plateVerified == true)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2ECC71).withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, color: Color(0xFF2ECC71)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Plaque vérifiée — identité confirmée',
                          style: TextStyle(color: Color(0xFF2ECC71), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gpp_bad, color: Colors.red),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Plaque non conforme',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: _verifyPlate,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              if (_activeSession != null) ...[
                _buildSessionInfoCard(),
                const SizedBox(height: 16),
              ],
              ElevatedButton.icon(
                onPressed: _openVehicleInfo,
                icon: const Icon(Icons.info_outline),
                label: const Text('Voir les détails'),
              ),
            ] else if (!_isLoading && _foundVehicle == null && _error == null) ...[
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 64, color: AppColors.gold),
                    SizedBox(height: 16),
                    Text('Aucun véhicule recherché'),
                    Text('Scannez un QR ou saisissez un code pour commencer'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon, color: color),
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildVehicleInfoCard() {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Véhicule trouvé', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _infoRow('Plaque', _foundVehicle!.plate.toUpperCase()),
            _infoRow('Propriétaire', _foundVehicle!.ownerName),
            if (_foundVehicle!.ownerPhone != null)
              _infoRow('Téléphone', _foundVehicle!.ownerPhone!),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfoCard() {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Session en cours', style: theme.textTheme.titleMedium),
                StatusBadge(
                  status: _activeSession!.effectiveStatus(
                    _foundCenter?.maxHoursDelay ?? 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(
              'Déposé le',
              '${_formatDate(_activeSession!.entryTime)} à ${_formatTime(_activeSession!.entryTime)}',
            ),
            if (_activeSession!.exitTime != null)
              _infoRow(
                'Récupéré le',
                '${_formatDate(_activeSession!.exitTime!)} à ${_formatTime(_activeSession!.exitTime!)}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
