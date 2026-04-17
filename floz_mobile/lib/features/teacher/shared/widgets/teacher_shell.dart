import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../classes/presentation/screens/classes_list_screen.dart';
import '../../grades_input/presentation/screens/grade_input_screen.dart';
import '../../recaps/presentation/screens/recap_screen.dart';
import '../providers/teacher_tab_providers.dart';

class TeacherShell extends ConsumerWidget {
  const TeacherShell({super.key});

  static const _tabs = <_TeacherTab>[
    _TeacherTab(label: 'Kelas', icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book_rounded),
    _TeacherTab(label: 'Nilai', icon: Icons.edit_note_outlined, activeIcon: Icons.edit_note),
    _TeacherTab(label: 'Rekap', icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded),
  ];

  Widget _buildTab(BuildContext context, int index) {
    return switch (index) {
      0 => const ClassesListScreen(purpose: ClassListPurpose.kelas),
      1 => ClassesListScreen(
          purpose: ClassListPurpose.nilai,
          onClassTap: (ta) => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GradeInputScreen(
                taId: ta.id,
                subjectName: ta.subjectName,
                className: ta.className,
              ),
            ),
          ),
        ),
      2 => ClassesListScreen(
          purpose: ClassListPurpose.rekap,
          onClassTap: (ta) => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RecapScreen(
                taId: ta.id,
                subjectName: ta.subjectName,
                className: ta.className,
              ),
            ),
          ),
        ),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(teacherSelectedTabProvider);
    return Scaffold(
      body: _buildTab(context, index),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(teacherSelectedTabProvider.notifier).state = i,
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

class _TeacherTab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _TeacherTab({required this.label, required this.icon, required this.activeIcon});
}
