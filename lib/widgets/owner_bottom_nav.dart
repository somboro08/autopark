import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../theme/app_colors.dart';

enum OwnerTab { vehicles, history }

/// Barre de navigation du propriétaire (2 onglets, style WhatsApp).
class OwnerBottomNav extends StatelessWidget {
  final OwnerTab selectedTab;
  final ValueChanged<OwnerTab> onTabSelected;

  const OwnerBottomNav({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: theme.bottomNavigationBarTheme.backgroundColor,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _tab(
            context,
            icon: Icons.two_wheeler,
            label: 'Mes motos',
            isSelected: selectedTab == OwnerTab.vehicles,
            onTap: () => onTabSelected(OwnerTab.vehicles),
          ),
          _tab(
            context,
            icon: Iconsax.clock,
            label: 'Mon historique',
            isSelected: selectedTab == OwnerTab.history,
            onTap: () => onTabSelected(OwnerTab.history),
          ),
        ],
      ),
    );
  }

  Widget _tab(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 80,
          color: isSelected
              ? AppColors.gold.withValues(alpha: 0.10)
              : Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.gold : null,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? AppColors.gold : null,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
