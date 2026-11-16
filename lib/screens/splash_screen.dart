import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'owner_home_screen.dart';
import 'profile_picker_screen.dart';
import '../database/database_helper.dart';
import '../models/app_user.dart';
import '../state/user_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/route_animations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    _initialize();
  }

  /// Prépare les données de démonstration, restaure le dernier profil utilisé
  /// puis ouvre l'espace correspondant (propriétaire ou agent).
  ///
  /// L'initialisation est bornée dans le temps : le splash ne doit jamais
  /// bloquer, même si la base de données est lente ou indisponible.
  Future<void> _initialize() async {
    final bootstrap = () async {
      try {
        await DatabaseHelper().seedDemoDataIfEmpty();
      } catch (_) {
        // Base existante ou indisponible : on continue.
      }
      try {
        return await UserSession.instance.restore();
      } catch (_) {
        return null;
      }
    }();

    AppUser? user;
    try {
      user = await bootstrap.timeout(
        const Duration(milliseconds: 1500),
        onTimeout: () => null,
      );
    } catch (_) {
      user = null;
    }

    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final Widget next;
    if (user == null) {
      next = const ProfilePickerScreen();
    } else if (user.role == AppRole.owner) {
      next = const OwnerHomeScreen();
    } else {
      next = const HomeScreen();
    }

    Navigator.of(context).pushReplacement(AppRoute.fade(next));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.directions_bike, size: 50, color: Colors.black),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'AutoPark',
              style: AppTheme.lightTheme.textTheme.displayMedium?.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sécurisation des parkings motos',
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
