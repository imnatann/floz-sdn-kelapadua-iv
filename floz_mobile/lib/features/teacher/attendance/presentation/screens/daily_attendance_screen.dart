import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../../../../shared/widgets/floz_button.dart';
import '../../../../../shared/widgets/floz_card.dart';
import '../../../../../shared/widgets/staggered_entry.dart';
import '../../domain/entities/attendance_roster.dart';
import '../../providers/attendance_providers.dart';

/// Daily class attendance screen for wali kelas.
///
/// Entry point: pass [classId] — the school class the homeroom teacher manages.
/// Non-homeroom teachers should NOT be routed here; the API will 403 anyway.
class DailyAttendanceScreen extends ConsumerStatefulWidget {
  const DailyAttendanceScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  final int classId;
  final String className;

  @override
  ConsumerState<DailyAttendanceScreen> createState() =>
      _DailyAttendanceScreenState();
}

class _DailyAttendanceScreenState extends ConsumerState<DailyAttendanceScreen> {
  final Map<int, String> _statusMap = {};
  final Map<int, String?> _noteMap = {};

  void _initFromRoster(DailyAttendanceRoster roster) {
    for (final s in roster.students) {
      if (!_statusMap.containsKey(s.id)) {
        if (s.status != null) _statusMap[s.id] = s.status!;
        if (s.note != null) _noteMap[s.id] = s.note;
      }
    }
  }

  int _countStatus(String status) =>
      _statusMap.values.where((s) => s == status).length;

  bool _allHaveStatus(List<StudentAttendance> students) =>
      students.every((s) => _statusMap.containsKey(s.id));

  List<Map<String, dynamic>> _buildEntries() {
    return _statusMap.entries
        .map((e) => {
              'student_id': e.key,
              'status': e.value,
              'note': _noteMap[e.key],
            })
        .toList();
  }

  Future<void> _submit(DailyAttendanceRoster roster) async {
    final success = await ref
        .read(dailyAttendanceSubmitControllerProvider.notifier)
        .submit(classId: widget.classId, entries: _buildEntries());

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Absensi berhasil disimpan'),
          backgroundColor: AppColors.success500,
        ),
      );
      Navigator.of(context).pop();
    } else {
      final submitState = ref.read(dailyAttendanceSubmitControllerProvider);
      final errorMsg = submitState.hasError
          ? (submitState.error is Failure
              ? (submitState.error as Failure).message
              : 'Gagal menyimpan absensi')
          : 'Gagal menyimpan absensi';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.danger500,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rosterAsync =
        ref.watch(dailyAttendanceRosterProvider(widget.classId));
    final submitState = ref.watch(dailyAttendanceSubmitControllerProvider);
    final isSubmitting = submitState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate900,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.slate200,
        title: rosterAsync.when(
          data: (roster) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Absensi Harian',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate900,
                ),
              ),
              Text(
                '${widget.className} · Pertemuan ${roster.meetingNumber}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
          loading: () => const Text(
            'Absensi Harian',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
            ),
          ),
          error: (err2, st2) => const Text(
            'Absensi Harian',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
            ),
          ),
        ),
      ),
      body: rosterAsync.when(
        data: (roster) {
          _initFromRoster(roster);
          final allHaveStatus = _allHaveStatus(roster.students);
          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: FlozCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary50,
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMD),
                                ),
                                child: const Icon(
                                  Icons.fact_check_rounded,
                                  color: AppColors.primary600,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      roster.classInfo.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: AppColors.slate900,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${roster.students.length} siswa · ${roster.date}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppColors.slate500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      sliver: SliverList.separated(
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemCount: roster.students.length,
                        itemBuilder: (context, i) {
                          final student = roster.students[i];
                          return StaggeredEntry(
                            index: i,
                            child: _DailyStudentRow(
                              index: i,
                              student: student,
                              selectedStatus: _statusMap[student.id],
                              note: _noteMap[student.id],
                              onStatusChanged: (status) {
                                setState(() {
                                  _statusMap[student.id] = status;
                                  if (status == 'hadir') {
                                    _noteMap.remove(student.id);
                                  }
                                });
                              },
                              onNoteChanged: (note) {
                                setState(() {
                                  _noteMap[student.id] =
                                      note.isEmpty ? null : note;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              _DailyBottomBar(
                hadir: _countStatus('hadir'),
                sakit: _countStatus('sakit'),
                izin: _countStatus('izin'),
                alpha: _countStatus('alpha'),
                isSubmitting: isSubmitting,
                canSubmit: allHaveStatus && !isSubmitting,
                onSubmit: () => _submit(roster),
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary600)),
        error: (err, _) => ErrorState(
          message: err is Failure ? err.message : 'Gagal memuat data absensi',
          onRetry: () =>
              ref.refresh(dailyAttendanceRosterProvider(widget.classId)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DailyStudentRow extends StatelessWidget {
  const _DailyStudentRow({
    required this.index,
    required this.student,
    required this.selectedStatus,
    required this.note,
    required this.onStatusChanged,
    required this.onNoteChanged,
  });

  final int index;
  final StudentAttendance student;
  final String? selectedStatus;
  final String? note;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onNoteChanged;

  bool get _showNote => selectedStatus != null && selectedStatus != 'hadir';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FlozCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.slate100,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.slate900,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      student.nis,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: AppColors.slate500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Chip(
                    label: 'H',
                    selected: selectedStatus == 'hadir',
                    activeColor: AppColors.success500,
                    onTap: () => onStatusChanged('hadir'),
                  ),
                  const SizedBox(width: 4),
                  _Chip(
                    label: 'S',
                    selected: selectedStatus == 'sakit',
                    activeColor: AppColors.warning500,
                    onTap: () => onStatusChanged('sakit'),
                  ),
                  const SizedBox(width: 4),
                  _Chip(
                    label: 'I',
                    selected: selectedStatus == 'izin',
                    activeColor: AppColors.info500,
                    onTap: () => onStatusChanged('izin'),
                  ),
                  const SizedBox(width: 4),
                  _Chip(
                    label: 'A',
                    selected: selectedStatus == 'alpha',
                    activeColor: AppColors.danger500,
                    onTap: () => onStatusChanged('alpha'),
                  ),
                ],
              ),
            ],
          ),
          if (_showNote) ...[
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: note ?? ''),
              onChanged: onNoteChanged,
              decoration: InputDecoration(
                hintText: 'Keterangan (opsional)',
                hintStyle: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.slate400),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                  borderSide: const BorderSide(color: AppColors.primary400),
                ),
              ),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.slate700),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: selected ? activeColor : AppColors.slate100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.slate500,
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyBottomBar extends StatelessWidget {
  const _DailyBottomBar({
    required this.hadir,
    required this.sakit,
    required this.izin,
    required this.alpha,
    required this.isSubmitting,
    required this.canSubmit,
    required this.onSubmit,
  });

  final int hadir;
  final int sakit;
  final int izin;
  final int alpha;
  final bool isSubmitting;
  final bool canSubmit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.slate200)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$hadir Hadir · $sakit Sakit · $izin Izin · $alpha Alpha',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.slate600,
            ),
          ),
          const SizedBox(height: 10),
          FlozButton(
            text: 'Simpan Absensi',
            onPressed: canSubmit ? onSubmit : null,
            isLoading: isSubmitting,
          ),
        ],
      ),
    );
  }
}
