import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/parking_center.dart';
import '../theme/app_colors.dart';
import '../utils/route_animations.dart';
import 'add_center_screen.dart';
import 'centers_map_screen.dart';
import 'daily_list_screen.dart';

class CentersListScreen extends StatefulWidget {
  const CentersListScreen({super.key});

  @override
  State<CentersListScreen> createState() => _CentersListScreenState();
}

class _CentersListScreenState extends State<CentersListScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<ParkingCenter> _centers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCenters();
  }

  Future<void> _loadCenters() async {
    final centers = await _db.getCenters();
    setState(() {
      _centers = centers;
      _isLoading = false;
    });
  }

  Future<void> _addCenter() async {
    await Navigator.of(context).push(
      AppRoute.page(const AddCenterScreen()),
    );
    _loadCenters();
  }

  Future<void> _deleteCenter(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce centre ?'),
        content: const Text('Tous les véhicules associés seront aussi supprimés.'),
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
      await _db.deleteCenter(id);
      _loadCenters();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mes centres de garde'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Navigator.of(context).push(
              AppRoute.page(const CentersMapScreen()),
            ),
            tooltip: 'Voir sur la carte',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addCenter,
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
                      const Icon(Icons.location_off, size: 64, color: AppColors.gold),
                      const SizedBox(height: 16),
                      Text('Aucun centre', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('Ajoutez votre premier centre de garde',
                          style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _addCenter,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter un centre'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _centers.length,
                  itemBuilder: (context, index) {
                    final center = _centers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: theme.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkDivider
                              : AppColors.lightDivider,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.location_city, color: AppColors.gold),
                        ),
                        title: Text(center.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(center.address),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppColors.gold),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteCenter(center.id!),
                            ),
                          ],
                        ),
                        onTap: () => Navigator.of(context).push(
                          AppRoute.page(DailyListScreen(center: center)),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCenter,
        child: const Icon(Icons.add),
      ),
    );
  }
}
