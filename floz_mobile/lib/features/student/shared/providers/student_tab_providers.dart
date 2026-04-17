import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected tab index in StudentShell. Notification deep-link writes to this.
/// 0 Beranda, 1 Jadwal, 2 Nilai, 3 Rapor, 4 Info, 5 Tugas
final studentSelectedTabProvider = StateProvider<int>((ref) => 0);
