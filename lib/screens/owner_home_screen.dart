import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/app_user.dart';
import '../models/parking_center.dart';
import '../models/parking_session.dart';
import '../models/vehicle.dart';
import '../state/user_session.dart';
import '../theme/app_colors.dart';
import '../utils/route_animations.dart';
import '../widgets/app_settings_sheet.dart';
import '../widgets/owner_bottom_nav.dart';
import '../widgets/status_badge.dart';
import 'add_owner_vehicle_screen.dart';
import 'owner_vehicle_detail_screen.dart';
import 'profile_picker_screen.dart';

/// Espace propriétaire : ses motos, leurs codes d'identité et l'historique de
/// toutes les gardes, tous centres confondus.
class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  OwnerTab _tab = OwnerTab.vehicles;
  bool _loading = true;
  List<Vehicle> _vehicles = [];
  List<ParkingSession> _sessions = [];
  final Map<int, ParkingCenter> _centers = {};
  final Map<int, Vehicle> _vehiclesById = {};

  AppUser? get _user => UserSession.instance.current.value;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = _user;
    if (user?.id == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final vehicles = await _db.getVehiclesByOwner(user!.id!);
      final sessions = await _db.getSessionsByOwner(user.id!);
      final centers = await _db.getCenters();

      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _sessions = sessions;
        _centers
          ..clear()
          ..addEntries(centers.map((c) => MapEntry(c.id!, c)));
        _vehiclesById
          ..clear()
          ..addEntries(vehicles.map((v) => MapEntry(v.id!, v)));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _addVehicle() async {
    final created = await Navigator.of(context).push<bool>(
      AppRoute.page(const AddOwnerVehicleScreen()),
    );
    if (created == true) _load();
  }

  Future<void> _openVehicle(Vehicle vehicle) async {
    final changed = await Navigator.of(context).push<bool>(
      AppRoute.page(OwnerVehicleDetailScreen(vehicle: vehicle)),
    );
    if (changed == true) _load();
  }

  Future<void> _switchProfile() async {
    await UserSession.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      AppRoute.fade(const ProfilePickerScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _user;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: GestureDetector(
            onTap: _switchProfile,
            child: Center(
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  user?.initials ?? '?',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _tab == OwnerTab.vehicles ? 'Mes motos' : 'Mon historique',
            ),
            Text(
              user?.name ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showAppSettingsSheet(context),
            tooltip: 'Paramètres',
          ),
          IconButton(
            icon: const Icon(Icons.switch_account),
            onPressed: _switchProfile,
            tooltip: 'Changer de profil',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _tab == OwnerTab.vehicles
                  ? _buildVehiclesTab(theme)
                  : _buildHistoryTab(theme),
            ),
      floatingActionButton: _tab == OwnerTab.vehicles
          ? FloatingActionButton.extended(
              onPressed: _addVehicle,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une moto'),
            )
          : null,
      bottomNavigationBar: OwnerBottomNav(
        selectedTab: _tab,
        onTabSelected: (tab) => setState(() => _tab = tab),
      ),
    );
  }

  // ---------- Onglet « Mes motos » ----------

  Widget _buildVehiclesTab(ThemeData theme) {
    if (_vehicles.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          Icon(Icons.two_wheeler, size: 72, color: theme.disabledColor),
          const SizedBox(height: 20),
          Text(
            'Aucune moto enregistrée',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Enregistrez votre moto une seule fois. Vous obtiendrez un QR code '
            'et un code numérique à présenter à n\'importe quel centre de garde.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _addVehicle,
            icon: const Icon(Iconsax.add_circle),
            label: const Text('Ajouter ma première moto'),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _vehicles.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Partagez le QR ou le code d\'une moto avec le gardien : il '
              'l\'enregistre en une seconde.',
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
            ),
          );
        }
        final vehicle = _vehicles[index - 1];
        return _VehicleCard(
          vehicle: vehicle,
          onTap: () => _openVehicle(vehicle),
        );
      },
    );
  }

  // ---------- Onglet « Mon historique » ----------

  Widget _buildHistoryTab(ThemeData theme) {
    if (_sessions.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          Icon(Iconsax.clock, size: 72, color: theme.disabledColor),
          const SizedBox(height: 20),
          Text(
            'Aucune garde pour le moment',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Dès que votre moto est déposée dans un centre, la garde apparaît '
            'ici avec sa date, son statut et le centre concerné.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final session = _sessions[index];
        final center = _centers[session.centerId];
        final vehicle = _vehiclesById[session.vehicleId];
        final status = session.effectiveStatus(center?.maxHoursDelay ?? 24);

        return Container(
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
                      vehicle?.plate.toUpperCase() ?? 'Moto',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  StatusBadge(status: status, small: true),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Iconsax.location,
                    size: 14,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      center?.name ?? 'Centre inconnu',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Iconsax.login,
                    size: 14,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Dépôt : ${_dateFormat.format(session.entryTime)} · '
                    '${_timeFormat.format(session.entryTime)}',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ),
              if (session.exitTime != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Iconsax.logout,
                      size: 14,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Retrait : ${_dateFormat.format(session.exitTime!)} · '
                      '${_timeFormat.format(session.exitTime!)}',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;

  const _VehicleCard({required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.two_wheeler,
                  color: AppColors.gold,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.plate.toUpperCase(),
                      style: theme.textTheme.titleLarge,
                    ),
                    if (vehicle.model != null &&
                        vehicle.model!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        vehicle.model!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Iconsax.barcode,
                          size: 14,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Code ${vehicle.numericCode ?? '—'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
