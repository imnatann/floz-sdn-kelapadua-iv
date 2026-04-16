import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../grades/presentation/screens/grades_list_screen.dart';
import '../../report_cards/presentation/screens/report_cards_list_screen.dart';
import '../../announcements/presentation/screens/announcements_list_screen.dart';
import '../../schedule/presentation/screens/schedule_screen.dart';
import 'tab_placeholder.dart';

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
    _StudentTab(label: 'Pengumuman', icon: Icons.campaign_outlined, activeIcon: Icons.campaign),
    _StudentTab(label: 'Tugas', icon: Icons.assignment_outlined, activeIcon: Icons.assignment),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardScreen(),
          ScheduleScreen(),
          GradesListScreen(),
          ReportCardsListScreen(),
          AnnouncementsListScreen(),
          TabPlaceholder(title: 'Tugas'),
        ],
      ),
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
