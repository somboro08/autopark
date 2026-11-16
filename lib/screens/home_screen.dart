import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart';
import 'retrieve_vehicle_screen.dart';
import 'register_vehicle_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  NavTab _selectedTab = NavTab.retrieve;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedTab == NavTab.retrieve ? 0 : 1,
        children: const [
          RetrieveVehicleScreen(),
          RegisterVehicleScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedTab: _selectedTab,
        onTabSelected: (tab) => setState(() => _selectedTab = tab),
      ),
    );
  }
}
