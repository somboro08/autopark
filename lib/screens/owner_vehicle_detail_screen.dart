import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../database/database_helper.dart';
import '../models/parking_center.dart';
import '../models/parking_session.dart';
import '../models/vehicle.dart';
import '../theme/app_colors.dart';
import '../widgets/status_badge.dart';

/// Fiche d'une moto du propriétaire : identité (QR + code) et historique.
class OwnerVehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;

  const OwnerVehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<OwnerVehicleDetailScreen> createState() =>
      _OwnerVehicleDetailScreenState();
}

class _OwnerVehicleDetailScreenState extends State<OwnerVehicleDetailScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  late Vehicle _vehicle;
  List<ParkingSession> _sessions = [];
  final Map<int, ParkingCenter> _centers = {};
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
    _load();
  }

  Future<void> _load() async {
    final centers = await _db.getCenters();
    final sessions = await _db.getSessionsByVehicle(_vehicle.id!);
    if (!mounted) return;
    setState(() {
      _centers
        ..clear()
        ..addEntries(centers.map((c) => MapEntry(c.id!, c)));
      _sessions = sessions;
    });
  }

  void _copy(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copié : $value')),
    );
  }

  Future<void> _shareWithCenter() async {
    final centers = await _db.getCenters();
    if (centers.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun centre disponible')),
      );
      return;
    }

    final selected = await showModalBottomSheet<ParkingCenter>(
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                const SizedBox(height: 18),
                Text('Partager avec un centre', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'Le centre enregistrera votre moto et la reconnaîtra aux '
                  'prochaines visites.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: centers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final center = centers[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: theme.dividerColor),
                        ),
                        leading: const Icon(
                          Iconsax.shop,
                          color: AppColors.gold,
                        ),
                        title: Text(center.name),
                        subtitle: Text(
                          '${center.address} · ${center.maxHoursDelay} h',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(ctx, center),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || selected.id == null) return;
    await _db.registerVehicleForCenter(selected.id!, _vehicle.id!);
    if (_vehicle.centerId == null) {
      final updated = _vehicle.copyWith(centerId: selected.id);
      await _db.updateVehicle(updated);
      if (mounted) setState(() => _vehicle = updated);
    }
    _changed = true;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Moto partagée avec ${selected.name}')),
    );
  }

  Future<void> _deleteVehicle() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette moto ?'),
        content: const Text(
          'La moto et son historique de gardes seront retirés de votre profil.',
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
    if (confirmed != true) return;
    await _db.deleteVehicle(_vehicle.id!);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_vehicle.plate.toUpperCase()),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteVehicle,
            tooltip: 'Supprimer la moto',
          ),
        ],
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) Navigator.of(context).pop(_changed);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _IdentityCard(
              vehicle: _vehicle,
              onCopyQr: () => _copy(_vehicle.qrCode ?? '', 'Code QR'),
              onCopyNumeric: () =>
                  _copy(_vehicle.numericCode ?? '', 'Code numérique'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _shareWithCenter,
              icon: const Icon(Iconsax.share),
              label: const Text('Partager avec un centre'),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Text('Historique des gardes', style: theme.textTheme.headlineMedium),
                const Spacer(),
                Text(
                  '${_sessions.length}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_sessions.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  children: [
                    Icon(Iconsax.clock, size: 36, color: theme.disabledColor),
                    const SizedBox(height: 10),
                    Text(
                      'Aucune garde enregistrée pour cette moto',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
            else
              ..._sessions.map((session) {
                final center = _centers[session.centerId];
                final status =
                    session.effectiveStatus(center?.maxHoursDelay ?? 24);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                center?.name ?? 'Centre inconnu',
                                style: theme.textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            StatusBadge(status: status, small: true),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dépôt : ${_dateFormat.format(session.entryTime)} · '
                          '${_timeFormat.format(session.entryTime)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                          ),
                        ),
                        if (session.exitTime != null)
                          Text(
                            'Retrait : ${_dateFormat.format(session.exitTime!)} · '
                            '${_timeFormat.format(session.exitTime!)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),
            Text(
              'Ce QR et ce code identifient votre moto. En revanche, ils ne '
              'permettent pas de la récupérer : seule la présentation du code '
              'de garde depuis votre téléphone le permet.',
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onCopyQr;
  final VoidCallback onCopyNumeric;

  const _IdentityCard({
    required this.vehicle,
    required this.onCopyQr,
    required this.onCopyNumeric,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.plate.toUpperCase(),
                      style: theme.textTheme.headlineLarge,
                    ),
                    if (vehicle.model != null &&
                        vehicle.model!.trim().isNotEmpty)
                      Text(
                        vehicle.model!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Code d\'identité du véhicule',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Iconsax.shield_tick, color: AppColors.gold, size: 28),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: vehicle.qrCode ?? vehicle.plate,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.barcode, color: AppColors.gold, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    vehicle.numericCode ?? '—',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Iconsax.copy, size: 20),
                  onPressed: onCopyNumeric,
                  tooltip: 'Copier le code numérique',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onCopyQr,
            icon: const Icon(Iconsax.copy, size: 16),
            label: const Text('Copier le contenu du QR'),
          ),
        ],
      ),
    );
  }
}
