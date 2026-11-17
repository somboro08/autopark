import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../database/database_helper.dart';
import '../models/parking_center.dart';
import '../theme/app_colors.dart';
import '../utils/route_animations.dart';
import 'daily_list_screen.dart';
import 'centers_list_screen.dart';

/// Carte des centres de garde avec marqueurs cliquables.
///
/// À chaque clic sur un marqueur, une fiche détaille le centre et permet
/// d'accéder à son journal quotidien (dépôts / récupérations).
class CentersMapScreen extends StatefulWidget {
  const CentersMapScreen({super.key});

  @override
  State<CentersMapScreen> createState() => _CentersMapScreenState();
}

class _CentersMapScreenState extends State<CentersMapScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final MapController _mapController = MapController();

  List<ParkingCenter> _centers = [];
  bool _isLoading = true;
  ParkingCenter? _selectedCenter;

  @override
  void initState() {
    super.initState();
    _loadCenters();
  }

  Future<void> _loadCenters() async {
    final centers = await _db.getLocatedCenters();
    if (!mounted) return;
    setState(() {
      _centers = centers;
      _isLoading = false;
    });
  }

  void _selectCenter(ParkingCenter center) {
    setState(() => _selectedCenter = center);
    _mapController.move(
      LatLng(center.latitude!, center.longitude!),
      15,
    );
  }

  List<Marker> _buildMarkers() {
    return _centers.map((center) {
      final isSelected = _selectedCenter?.id == center.id;
      return Marker(
        point: LatLng(center.latitude!, center.longitude!),
        width: 40,
        height: 40,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () => _selectCenter(center),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : AppColors.gold,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.location_city,
              color: Colors.black,
              size: 20,
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte des centres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_outlined),
            onPressed: () => Navigator.of(context).push(
              AppRoute.page(const CentersListScreen()),
            ),
            tooltip: 'Liste des centres',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _centers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.map, size: 64, color: AppColors.gold),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun centre sur la carte',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajoutez des centres avec une position pour les voir ici.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(
                          _centers.first.latitude!,
                          _centers.first.longitude!,
                        ),
                        initialZoom: 13,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.parkingmotos.autopark_mvp',
                        ),
                        MarkerLayer(markers: _buildMarkers()),
                      ],
                    ),
                    if (_selectedCenter != null)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: _CenterCard(
                          center: _selectedCenter!,
                          onViewJournal: () {
                            Navigator.of(context).push(
                              AppRoute.page(
                                DailyListScreen(center: _selectedCenter!),
                              ),
                            );
                          },
                          onClose: () => setState(() => _selectedCenter = null),
                        ),
                      ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_centers.isNotEmpty) {
            _mapController.move(
              LatLng(
                _centers.first.latitude!,
                _centers.first.longitude!,
              ),
              13,
            );
          }
        },
        child: const Icon(Icons.my_location),
        tooltip: 'Recentrer',
      ),
    );
  }
}

/// Fiche d'un centre affichée en bas de la carte quand un marqueur est tapé.
class _CenterCard extends StatelessWidget {
  final ParkingCenter center;
  final VoidCallback onViewJournal;
  final VoidCallback onClose;

  const _CenterCard({
    required this.center,
    required this.onViewJournal,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.location_city,
                  color: AppColors.gold,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      center.name,
                      style: theme.textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      center.coordinatesLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onClose,
                child: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            center.address,
            style: theme.textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewJournal,
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('Voir le journal'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
