import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../announcements/presentation/screens/announcements_list_screen.dart';
import '../../assignments/presentation/screens/assignments_list_screen.dart';
import '../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../grades/presentation/screens/grades_list_screen.dart';
import '../../report_cards/presentation/screens/report_cards_list_screen.dart';
import '../../schedule/presentation/screens/schedule_screen.dart';
import '../providers/student_tab_providers.dart';

class StudentShell extends ConsumerWidget {
  const StudentShell({super.key});

  static const _tabs = <_StudentTab>[
    _StudentTab(label: 'Beranda', icon: Icons.home_outlined, activeIcon: Icons.home),
    _StudentTab(label: 'Jadwal', icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today),
    _StudentTab(label: 'Nilai', icon: Icons.grade_outlined, activeIcon: Icons.grade),
    _StudentTab(label: 'Rapor', icon: Icons.description_outlined, activeIcon: Icons.description),
    _StudentTab(label: 'Info', icon: Icons.campaign_outlined, activeIcon: Icons.campaign),
    _StudentTab(label: 'Tugas', icon: Icons.assignment_outlined, activeIcon: Icons.assignment),
  ];

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
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(studentSelectedTabProvider);
    return Scaffold(
      body: _buildTab(index),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(studentSelectedTabProvider.notifier).state = i,
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
