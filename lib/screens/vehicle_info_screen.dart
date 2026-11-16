import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/vehicle.dart';
import '../models/parking_session.dart';
import '../models/parking_center.dart';
import '../theme/app_colors.dart';
import '../widgets/status_badge.dart';

class VehicleInfoScreen extends StatefulWidget {
  final Vehicle vehicle;
  final ParkingSession? session;

  const VehicleInfoScreen({super.key, required this.vehicle, this.session});

  @override
  State<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  bool _isLoading = false;
  ParkingCenter? _center;

  SessionStatus get _effectiveStatus {
    if (widget.session == null) return SessionStatus.active;
    return widget.session!.effectiveStatus(_center?.maxHoursDelay ?? 24);
  }

  @override
  void initState() {
    super.initState();
    _loadCenter();
  }

  Future<void> _loadCenter() async {
    if (widget.session == null) return;
    final center = await _db.getCenterById(widget.session!.centerId);
    if (mounted) setState(() => _center = center);
  }

  Future<void> _markRetrieved() async {
    if (widget.session == null) return;
    setState(() => _isLoading = true);
    try {
      final updated = widget.session!.copyWith(
        exitTime: DateTime.now(),
        status: SessionStatus.retrieved,
      );
      await _db.updateSession(updated);
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _deleteVehicle() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce véhicule ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _db.deleteVehicle(widget.vehicle.id!);
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.vehicle.plate.toUpperCase()),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteVehicle,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vehicle avatar
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.directions_bike, size: 50, color: AppColors.gold),
              ),
            ),
            const SizedBox(height: 24),

            // Info section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
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
                    'Informations du véhicule',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow('Plaque', widget.vehicle.plate.toUpperCase(), Icons.confirmation_number),
                  _buildInfoRow('Propriétaire', widget.vehicle.ownerName, Icons.person),
                  if (widget.vehicle.ownerPhone != null)
                    _buildInfoRow('Téléphone', widget.vehicle.ownerPhone!, Icons.phone),
                  _buildInfoRow('Code QR', widget.vehicle.qrCode ?? 'Non défini', Icons.qr_code),
                  _buildInfoRow('Code numérique', widget.vehicle.numericCode ?? 'Non défini', Icons.numbers),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Session status
            if (widget.session != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkDivider
                        : AppColors.lightDivider,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Statut de stationnement', style: theme.textTheme.titleLarge),
                        StatusBadge(status: _effectiveStatus),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Heure de dépôt',
                      '${_formatDate(widget.session!.entryTime)} à ${_formatTime(widget.session!.entryTime)}',
                      Icons.login,
                    ),
                    if (widget.session!.exitTime != null)
                      _buildInfoRow(
                        'Heure de récupération',
                        '${_formatDate(widget.session!.exitTime!)} à ${_formatTime(widget.session!.exitTime!)}',
                        Icons.logout,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              if (_effectiveStatus != SessionStatus.retrieved) ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _markRetrieved,
                    icon: const Icon(Icons.logout),
                    label: const Text('Marquer comme récupéré'),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.gold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
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
