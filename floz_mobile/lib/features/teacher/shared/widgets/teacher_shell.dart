import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../classes/presentation/screens/classes_list_screen.dart';
import '../../grades_input/presentation/screens/grade_input_screen.dart';
import '../../recaps/presentation/screens/recap_screen.dart';

class TeacherShell extends ConsumerStatefulWidget {
  const TeacherShell({super.key});

  @override
  ConsumerState<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends ConsumerState<TeacherShell> {
  int _index = 0;

  static const _tabs = <_TeacherTab>[
    _TeacherTab(label: 'Kelas', icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book_rounded),
    _TeacherTab(label: 'Nilai', icon: Icons.edit_note_outlined, activeIcon: Icons.edit_note),
    _TeacherTab(label: 'Rekap', icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded),
  ];

  Widget _buildTab(int index) {
    return switch (index) {
      0 => const ClassesListScreen(),
      1 => ClassesListScreen(
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

class _TeacherTab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _TeacherTab({required this.label, required this.icon, required this.activeIcon});
}
