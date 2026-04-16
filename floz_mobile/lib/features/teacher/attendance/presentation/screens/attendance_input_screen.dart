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

class AttendanceInputScreen extends ConsumerStatefulWidget {
  const AttendanceInputScreen({super.key, required this.meetingId});

  final int meetingId;

  @override
  ConsumerState<AttendanceInputScreen> createState() =>
      _AttendanceInputScreenState();
}

class _AttendanceInputScreenState
    extends ConsumerState<AttendanceInputScreen> {
  final Map<int, String> _statusMap = {};
  final Map<int, String?> _noteMap = {};

  void _initFromRoster(AttendanceRoster roster) {
    for (final s in roster.students) {
      if (!_statusMap.containsKey(s.id)) {
        if (s.status != null) {
          _statusMap[s.id] = s.status!;
        }
        if (s.note != null) {
          _noteMap[s.id] = s.note;
        }
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

  Future<void> _submit(AttendanceRoster roster) async {
    final success = await ref
        .read(attendanceSubmitControllerProvider.notifier)
        .submit(meetingId: widget.meetingId, entries: _buildEntries());

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
      final submitState = ref.read(attendanceSubmitControllerProvider);
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
    final rosterAsync = ref.watch(attendanceRosterProvider(widget.meetingId));
    final submitState = ref.watch(attendanceSubmitControllerProvider);
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
              Text(
                'Absensi Pertemuan ${roster.meeting.meetingNumber}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate900,
                ),
              ),
              Text(
                '${roster.subject.name} - ${roster.classInfo.name}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
          loading: () => const Text(
            'Absensi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
            ),
          ),
          error: (err2, st2) => const Text(
            'Absensi',
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
                    // Header card
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
                                      roster.meeting.title,
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
                                      '${roster.students.length} siswa',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.slate500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Student list
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      sliver: SliverList.separated(
                        separatorBuilder: (ctx, idx) =>
                            const SizedBox(height: 10),
                        itemCount: roster.students.length,
                        itemBuilder: (context, i) {
                          final student = roster.students[i];
                          return StaggeredEntry(
                            index: i,
                            child: _StudentRow(
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

              // Sticky bottom bar
              _BottomBar(
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
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary600),
        ),
        error: (err, _) => ErrorState(
          message:
              err is Failure ? err.message : 'Gagal memuat data absensi',
          onRetry: () =>
              ref.refresh(attendanceRosterProvider(widget.meetingId)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Student row widget
// ─────────────────────────────────────────────────────────────────────────────

class _StudentRow extends StatelessWidget {
  const _StudentRow({
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

  bool get _showNoteField =>
      selectedStatus != null && selectedStatus != 'hadir';

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
              // Number circle
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
              // Name + NIS
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
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status chips
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatusChip(
                    label: 'H',
                    value: 'hadir',
                    selected: selectedStatus == 'hadir',
                    activeColor: AppColors.success500,
                    onTap: () => onStatusChanged('hadir'),
                  ),
                  const SizedBox(width: 4),
                  _StatusChip(
                    label: 'S',
                    value: 'sakit',
                    selected: selectedStatus == 'sakit',
                    activeColor: AppColors.warning500,
                    onTap: () => onStatusChanged('sakit'),
                  ),
                  const SizedBox(width: 4),
                  _StatusChip(
                    label: 'I',
                    value: 'izin',
                    selected: selectedStatus == 'izin',
                    activeColor: AppColors.info500,
                    onTap: () => onStatusChanged('izin'),
                  ),
                  const SizedBox(width: 4),
                  _StatusChip(
                    label: 'A',
                    value: 'alpha',
                    selected: selectedStatus == 'alpha',
                    activeColor: AppColors.danger500,
                    onTap: () => onStatusChanged('alpha'),
                  ),
                ],
              ),
            ],
          ),

          // Note field (shown only when status requires it)
          if (_showNoteField) ...[
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: note ?? ''),
              onChanged: onNoteChanged,
              decoration: InputDecoration(
                hintText: 'Keterangan (opsional)',
                hintStyle: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.slate400),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSM),
                  borderSide:
                      const BorderSide(color: AppColors.slate200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSM),
                  borderSide:
                      const BorderSide(color: AppColors.slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSM),
                  borderSide:
                      const BorderSide(color: AppColors.primary400),
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

// ─────────────────────────────────────────────────────────────────────────────
// Status chip
// ─────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final String value;
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

// ─────────────────────────────────────────────────────────────────────────────
// Bottom bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
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
          // Summary row
          Text(
            '$hadir Hadir · $sakit Sakit · $izin Izin · $alpha Alpha',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.slate600,
            ),
          ),
          const SizedBox(height: 10),
          // Submit button
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
