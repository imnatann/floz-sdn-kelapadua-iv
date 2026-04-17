import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected tab index in TeacherShell. Notification deep-link writes to this.
/// 0 Kelas, 1 Nilai, 2 Rekap
final teacherSelectedTabProvider = StateProvider<int>((ref) => 0);
