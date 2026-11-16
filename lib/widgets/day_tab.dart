import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

class DayTab extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const DayTab({
    super.key,
    required this.date,
    required this.isSelected,
    this.isToday = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dayName = DateFormat.E('fr').format(date)[0]; // First letter: L, M, M, J, V, S, D
    final dayNumber = date.day.toString();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold
              : (isToday ? (isDark ? AppColors.darkCard : AppColors.lightCard) : Colors.transparent),
          borderRadius: BorderRadius.circular(14),
          border: isToday && !isSelected
              ? Border.all(
                  color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dayName,
              style: TextStyle(
                color: isSelected ? Colors.black : theme.textTheme.bodyMedium?.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayNumber,
              style: TextStyle(
                color: isSelected ? Colors.black : theme.textTheme.titleLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
