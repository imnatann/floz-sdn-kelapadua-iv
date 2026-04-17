import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../../../../shared/widgets/floz_card.dart';
import '../../../../../shared/widgets/staggered_entry.dart';
import '../../domain/entities/attendance_recap.dart';
import '../../domain/entities/grade_recap.dart';
import '../../providers/recap_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Recap screen
// ─────────────────────────────────────────────────────────────────────────────

enum _RecapTab { attendance, grade }

class RecapScreen extends ConsumerStatefulWidget {
  const RecapScreen({
    super.key,
    required this.taId,
    required this.subjectName,
    required this.className,
  });

  final int taId;
  final String subjectName;
  final String className;

  @override
  ConsumerState<RecapScreen> createState() => _RecapScreenState();
}

class _RecapScreenState extends ConsumerState<RecapScreen> {
  _RecapTab _activeTab = _RecapTab.attendance;

  Future<void> _refresh() async {
    if (_activeTab == _RecapTab.attendance) {
      ref.invalidate(attendanceRecapProvider(widget.taId));
      await ref.read(attendanceRecapProvider(widget.taId).future);
    } else {
      ref.invalidate(gradeRecapProvider(widget.taId));
      await ref.read(gradeRecapProvider(widget.taId).future);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate900,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.slate200,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subjectName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.slate900,
              ),
            ),
            Text(
              widget.className,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.slate500,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _TabChips(
            active: _activeTab,
            onChanged: (tab) => setState(() => _activeTab = tab),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary600,
              backgroundColor: Colors.white,
              strokeWidth: 2.5,
              onRefresh: _refresh,
              child: _activeTab == _RecapTab.attendance
                  ? _AttendanceTab(taId: widget.taId)
                  : _GradeTab(taId: widget.taId),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab chips row
// ─────────────────────────────────────────────────────────────────────────────

class _TabChips extends StatelessWidget {
  const _TabChips({required this.active, required this.onChanged});

  final _RecapTab active;
  final ValueChanged<_RecapTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _Chip(
            label: 'Absensi',
            selected: active == _RecapTab.attendance,
            onTap: () => onChanged(_RecapTab.attendance),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Nilai',
            selected: active == _RecapTab.grade,
            onTap: () => onChanged(_RecapTab.grade),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary600 : AppColors.slate100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.slate600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Attendance tab
// ─────────────────────────────────────────────────────────────────────────────

class _AttendanceTab extends ConsumerWidget {
  const _AttendanceTab({required this.taId});

  final int taId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(attendanceRecapProvider(taId));

    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary600),
      ),
      error: (err, _) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.12),
          ErrorState(
            message: err is Failure ? err.message : 'Gagal memuat rekap absensi',
            onRetry: () => ref.invalidate(attendanceRecapProvider(taId)),
          ),
        ],
      ),
      data: (recap) {
        if (recap.students.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: const [
              SizedBox(height: 60),
              _EmptyState(
                icon: Icons.event_available_rounded,
                title: 'Belum ada data absensi',
                subtitle:
                    'Rekap kehadiran siswa akan muncul setelah absensi tercatat.',
              ),
            ],
          );
        }

        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: recap.students.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) => StaggeredEntry(
            index: i,
            child: _AttendanceRow(index: i, student: recap.students[i]),
          ),
        );
      },
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({required this.index, required this.student});

  final int index;
  final StudentAttendanceRecap student;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = student.percentage.clamp(0, 100).toDouble();

    return FlozCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _StatusBadge(
                label: 'H',
                count: student.hadir,
                bg: AppColors.success50,
                fg: AppColors.success700,
              ),
              _StatusBadge(
                label: 'S',
                count: student.sakit,
                bg: AppColors.warning50,
                fg: AppColors.warning700,
              ),
              _StatusBadge(
                label: 'I',
                count: student.izin,
                bg: AppColors.info50,
                fg: AppColors.info700,
              ),
              _StatusBadge(
                label: 'A',
                count: student.alpha,
                bg: AppColors.danger50,
                fg: AppColors.danger700,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXS),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 6,
                    backgroundColor: AppColors.slate100,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Kehadiran ${_formatPct(pct)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPct(double v) {
    return v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.count,
    required this.bg,
    required this.fg,
  });

  final String label;
  final int count;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grade tab
// ─────────────────────────────────────────────────────────────────────────────

class _GradeTab extends ConsumerWidget {
  const _GradeTab({required this.taId});

  final int taId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(gradeRecapProvider(taId));

    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary600),
      ),
      error: (err, _) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.12),
          ErrorState(
            message: err is Failure ? err.message : 'Gagal memuat rekap nilai',
            onRetry: () => ref.invalidate(gradeRecapProvider(taId)),
          ),
        ],
      ),
      data: (recap) {
        if (recap.students.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: const [
              SizedBox(height: 60),
              _EmptyState(
                icon: Icons.assessment_outlined,
                title: 'Belum ada data nilai',
                subtitle:
                    'Rekap nilai siswa akan muncul setelah nilai diinput.',
              ),
            ],
          );
        }

        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: recap.students.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) => StaggeredEntry(
            index: i,
            child: _GradeRow(index: i, student: recap.students[i]),
          ),
        );
      },
    );
  }
}

class _GradeRow extends StatelessWidget {
  const _GradeRow({required this.index, required this.student});

  final int index;
  final StudentGradeRecap student;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FlozCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              if (student.predicate != null && student.predicate!.isNotEmpty)
                _PredicateBadge(value: student.predicate!),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _ScoreChip(label: 'Harian', value: student.dailyTestAvg),
              _ScoreChip(label: 'UTS', value: student.midTest),
              _ScoreChip(label: 'UAS', value: student.finalTest),
              _ScoreChip(
                label: 'Final',
                value: student.finalScore,
                emphasized: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final double? value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final txt = value == null ? '—' : _fmt(value!);
    final bg = emphasized ? AppColors.primary50 : AppColors.slate100;
    final labelColor = emphasized ? AppColors.primary700 : AppColors.slate500;
    final valueColor = emphasized ? AppColors.primary700 : AppColors.slate800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
          Text(
            txt,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

class _PredicateBadge extends StatelessWidget {
  const _PredicateBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(value);
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: colors.fg,
        ),
      ),
    );
  }

  ({Color bg, Color fg}) _colorsFor(String predicate) {
    switch (predicate.toUpperCase()) {
      case 'A':
        return (bg: AppColors.success50, fg: AppColors.success700);
      case 'B':
        return (bg: AppColors.info50, fg: AppColors.info700);
      case 'C':
        return (bg: AppColors.warning50, fg: AppColors.warning700);
      case 'D':
      default:
        return (bg: AppColors.danger50, fg: AppColors.danger700);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: AppColors.primary50,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
          ),
          child: Icon(icon, size: 36, color: AppColors.primary600),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.slate900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.slate500,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
