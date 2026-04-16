import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../announcements/presentation/screens/announcements_list_screen.dart';
import '../../assignments/presentation/screens/assignments_list_screen.dart';
import '../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../grades/presentation/screens/grades_list_screen.dart';
import '../../report_cards/presentation/screens/report_cards_list_screen.dart';
import '../../schedule/presentation/screens/schedule_screen.dart';

class StudentShell extends ConsumerStatefulWidget {
  const StudentShell({super.key});

  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
  int _index = 0;

  static const _tabs = <_StudentTab>[
    _StudentTab(label: 'Beranda', icon: Icons.home_outlined, activeIcon: Icons.home),
    _StudentTab(label: 'Jadwal', icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today),
    _StudentTab(label: 'Nilai', icon: Icons.grade_outlined, activeIcon: Icons.grade),
    _StudentTab(label: 'Rapor', icon: Icons.description_outlined, activeIcon: Icons.description),
    _StudentTab(label: 'Info', icon: Icons.campaign_outlined, activeIcon: Icons.campaign),
    _StudentTab(label: 'Tugas', icon: Icons.assignment_outlined, activeIcon: Icons.assignment),
  ];

  /// Build only the active tab. Riverpod providers are NOT auto-dispose,
  /// so switching back to a previously-visited tab shows cached data
  /// instantly without re-fetching.
  Widget _buildTab(int index) {
    return switch (index) {
      0 => const DashboardScreen(),
      1 => const ScheduleScreen(),
      2 => const GradesListScreen(),
      3 => const ReportCardsListScreen(),
      4 => const AnnouncementsListScreen(),
      5 => const AssignmentsListScreen(),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildTab(_index),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _StudentTab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _StudentTab({required this.label, required this.icon, required this.activeIcon});
}
