import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/parking_center.dart';
import '../models/parking_session.dart';
import '../models/vehicle.dart';
import '../theme/app_colors.dart';
import '../utils/route_animations.dart';
import '../widgets/day_tab.dart';
import 'vehicle_info_screen.dart';

class DailyListScreen extends StatefulWidget {
  final ParkingCenter center;

  const DailyListScreen({super.key, required this.center});

  @override
  State<DailyListScreen> createState() => _DailyListScreenState();
}

class _DailyListScreenState extends State<DailyListScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  DateTime _selectedDate = DateTime.now();
  List<ParkingSession> _sessions = [];
  final Map<int, Vehicle> _vehicleCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await _db.getSessionsByCenterAndDate(widget.center.id!, _selectedDate);
    setState(() {
      _sessions = sessions;
      _isLoading = false;
    });
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    for (final session in _sessions) {
      final vehicle = await _db.getVehicleById(session.vehicleId);
      if (vehicle != null) {
        setState(() => _vehicleCache[session.vehicleId] = vehicle);
      }
    }
  }

  List<DateTime> _getWeekDays() {
    final now = DateTime.now();
    // Start of week (Monday)
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
    _loadSessions();
  }

  @override
  @override
  void dispose() {
    super.dispose();
  }

  String _getSessionStatus(SessionStatus status, ParkingSession session, ParkingCenter center) {
    final effective = session.effectiveStatus(center.maxHoursDelay);
    switch (effective) {
      case SessionStatus.active:
        return 'En cours';
      case SessionStatus.retrieved:
        return 'Récupéré';
      case SessionStatus.notRetrieved:
        return 'Non récupéré';
    }
  }

  Color _getStatusColor(String statusLabel) {
    switch (statusLabel) {
      case 'En cours':
        return const Color(0xFF2ECC71);
      case 'Récupéré':
        return const Color(0xFF3498DB);
      default:
        return const Color(0xFFE74C3C);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekDays = _getWeekDays();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.center.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Horizontal week tabs
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                final day = weekDays[index];
                final isSameDay = _selectedDate.year == day.year &&
                    _selectedDate.month == day.month &&
                    _selectedDate.day == day.day;
                final isToday = DateTime.now().year == day.year &&
                    DateTime.now().month == day.month &&
                    DateTime.now().day == day.day;
                return DayTab(
                  date: day,
                  isSelected: isSameDay,
                  isToday: isToday,
                  onTap: () => _selectDate(day),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Session list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _sessions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 64, color: AppColors.gold),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun véhicule',
                              style: theme.textTheme.titleLarge,
                            ),
                            Text(
                              'Aucun dépôt pour le ${DateFormat('dd/MM/yyyy', 'fr').format(_selectedDate)}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) {
                          final session = _sessions[index];
                          final vehicle = _vehicleCache[session.vehicleId];
                          if (vehicle == null) return const SizedBox.shrink();

                          final statusLabel = _getSessionStatus(session.status, session, widget.center);
                          final statusColor = _getStatusColor(statusLabel);

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
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.directions_bike, color: AppColors.gold, size: 24),
                              ),
                              title: Text(
                                vehicle.plate.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(vehicle.ownerName),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 14, color: AppColors.gold),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${_formatDate(session.entryTime)} ${_formatTime(session.entryTime)}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (session.exitTime != null)
                                    Text(
                                      _formatTime(session.exitTime!),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                ],
                              ),
                              onTap: () => Navigator.of(context).push(
                                AppRoute.page(
                                  VehicleInfoScreen(
                                    vehicle: vehicle,
                                    session: session,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
