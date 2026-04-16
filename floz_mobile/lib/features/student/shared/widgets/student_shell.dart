import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../announcements/presentation/screens/announcements_list_screen.dart';
import '../../announcements/providers/announcement_providers.dart';
import '../../assignments/presentation/screens/assignments_list_screen.dart';
import '../../assignments/providers/assignment_providers.dart';
import '../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../grades/presentation/screens/grades_list_screen.dart';
import '../../grades/providers/grade_providers.dart';
import '../../report_cards/presentation/screens/report_cards_list_screen.dart';
import '../../report_cards/providers/report_card_providers.dart';
import '../../schedule/presentation/screens/schedule_screen.dart';
import '../../schedule/providers/schedule_providers.dart';

class StudentShell extends ConsumerStatefulWidget {
  const StudentShell({super.key});

  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Pre-warm all tab providers so data fetches start immediately,
    // not only when the user switches to that tab.
    Future.microtask(() {
      ref.read(scheduleNotifierProvider);
      ref.read(gradeListNotifierProvider);
      ref.read(reportCardListNotifierProvider);
      ref.read(announcementListNotifierProvider);
      ref.read(assignmentListNotifierProvider);
    });
  }

  static const _tabs = <_StudentTab>[
    _StudentTab(label: 'Beranda', icon: Icons.home_outlined, activeIcon: Icons.home),
    _StudentTab(label: 'Jadwal', icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today),
    _StudentTab(label: 'Nilai', icon: Icons.grade_outlined, activeIcon: Icons.grade),
    _StudentTab(label: 'Rapor', icon: Icons.description_outlined, activeIcon: Icons.description),
    _StudentTab(label: 'Info', icon: Icons.campaign_outlined, activeIcon: Icons.campaign),
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
          AssignmentsListScreen(),
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
