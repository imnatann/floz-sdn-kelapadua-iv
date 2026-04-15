import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import '../../core/theme/app_colors.dart';

class FlozBottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const FlozBottomNav({super.key, required this.navigationShell});

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary50,
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: HeroIcon(HeroIcons.home, style: HeroIconStyle.outline),
            selectedIcon: HeroIcon(HeroIcons.home, style: HeroIconStyle.solid),
            label: 'Home',
          ),
          NavigationDestination(
            icon: HeroIcon(HeroIcons.calendar, style: HeroIconStyle.outline),
            selectedIcon: HeroIcon(
              HeroIcons.calendar,
              style: HeroIconStyle.solid,
            ),
            label: 'Jadwal',
          ),
          NavigationDestination(
            icon: HeroIcon(
              HeroIcons.documentText,
              style: HeroIconStyle.outline,
            ),
            selectedIcon: HeroIcon(
              HeroIcons.documentText,
              style: HeroIconStyle.solid,
            ),
            label: 'Tugas',
          ),
          NavigationDestination(
            icon: HeroIcon(
              HeroIcons.clipboardDocumentCheck,
              style: HeroIconStyle.outline,
            ),
            selectedIcon: HeroIcon(
              HeroIcons.clipboardDocumentCheck,
              style: HeroIconStyle.solid,
            ),
            label: 'Nilai',
          ),
          NavigationDestination(
            icon: HeroIcon(HeroIcons.user, style: HeroIconStyle.outline),
            selectedIcon: HeroIcon(HeroIcons.user, style: HeroIconStyle.solid),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
