import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/auth/auth_session.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../../../../shared/widgets/floz_card.dart';
import '../../../../../shared/widgets/staggered_entry.dart';
import '../../domain/entities/teaching_assignment_summary.dart';
import '../../providers/teacher_class_providers.dart';
import 'class_detail_screen.dart';

class ClassListPurpose {
  final String title;
  final String subtitle;
  final IconData icon;
  const ClassListPurpose({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  static const kelas = ClassListPurpose(
    title: 'Kelas Saya',
    subtitle: 'Ketuk kelas untuk melihat materi, pertemuan, & siswa.',
    icon: Icons.menu_book_rounded,
  );

  static const nilai = ClassListPurpose(
    title: 'Input Nilai',
    subtitle: 'Pilih kelas untuk mulai mengisi nilai siswa.',
    icon: Icons.edit_note_rounded,
  );

  static const rekap = ClassListPurpose(
    title: 'Rekap Absensi & Nilai',
    subtitle: 'Pilih kelas untuk melihat ringkasan kehadiran & nilai.',
    icon: Icons.bar_chart_rounded,
  );
}

class ClassesListScreen extends ConsumerWidget {
  const ClassesListScreen({super.key, this.onClassTap, this.purpose});
  final void Function(TeachingAssignmentSummary ta)? onClassTap;
  final ClassListPurpose? purpose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teacherClassListNotifierProvider);
    final session = ref.watch(authSessionProvider);
    final teacherName = session.user?.name ?? 'Guru';

    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(name: teacherName),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary600,
                backgroundColor: Colors.white,
                strokeWidth: 2.5,
                onRefresh: () =>
                    ref.read(teacherClassListNotifierProvider.notifier).refresh(),
                child: state.when(
                  data: (list) => _TeacherHome(
                    classes: list,
                    teacherName: teacherName,
                    onClassTap: onClassTap,
                    purpose: purpose,
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary600),
                  ),
                  error: (err, _) => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                      ErrorState(
                        message: err is Failure ? err.message : 'Gagal memuat kelas',
                        onRetry: () => ref
                            .read(teacherClassListNotifierProvider.notifier)
                            .refresh(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Content ─────────────────────────────────────────────────────────────

class _TeacherHome extends StatelessWidget {
  const _TeacherHome({
    required this.classes,
    required this.teacherName,
    this.onClassTap,
    this.purpose,
  });
  final List<TeachingAssignmentSummary> classes;
  final String teacherName;
  final void Function(TeachingAssignmentSummary ta)? onClassTap;
  final ClassListPurpose? purpose;

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _GreetingHeader(teacherName: teacherName, classCount: 0, studentCount: 0),
          if (purpose != null) ...[
            const SizedBox(height: 12),
            _PurposeBanner(purpose: purpose!),
          ],
          const SizedBox(height: 60),
          Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                ),
                child: const Icon(Icons.menu_book_rounded, size: 36, color: AppColors.primary600),
              ),
              const SizedBox(height: 20),
              const Text(
                'Belum ada kelas yang diampu',
                style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.slate900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Kelas yang Anda ampu akan\nmuncul di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.slate500, height: 1.5),
              ),
            ],
          ),
        ],
      );
    }

    final totalStudents = classes.fold<int>(0, (sum, ta) => sum + ta.studentCount);
    final uniqueClasses = classes.map((ta) => ta.className).toSet().length;

    final items = <Widget>[
      StaggeredEntry(
        index: 0,
        child: _GreetingHeader(
          teacherName: teacherName,
          classCount: uniqueClasses,
          studentCount: totalStudents,
        ),
      ),
      if (purpose != null)
        StaggeredEntry(
          index: 1,
          child: _PurposeBanner(purpose: purpose!),
        ),
      StaggeredEntry(
        index: purpose != null ? 2 : 1,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4, left: 4),
          child: Text(
            'Mata Pelajaran & Kelas',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
            ),
          ),
        ),
      ),
      ...List.generate(classes.length, (i) {
        return StaggeredEntry(
          index: i + (purpose != null ? 3 : 2),
          child: _ClassTile(ta: classes[i], onTap: onClassTap),
        );
      }),
    ];

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
      separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 16 : 10),
    );
  }
}

// ── Greeting Header ─────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({
    required this.teacherName,
    required this.classCount,
    required this.studentCount,
  });

  final String teacherName;
  final int classCount;
  final int studentCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = _timeBasedGreeting();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF475569), Color(0xFF334155)], // slate-600→700
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate700.withValues(alpha: 0.25),
            offset: const Offset(0, 8),
            blurRadius: 18,
            spreadRadius: -6,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                teacherName,
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.15,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _HeaderStat(
                    icon: Icons.class_outlined,
                    value: '$classCount',
                    label: 'Kelas',
                  ),
                  const SizedBox(width: 16),
                  _HeaderStat(
                    icon: Icons.people_outline_rounded,
                    value: '$studentCount',
                    label: 'Siswa',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'SELAMAT PAGI';
    if (hour < 15) return 'SELAMAT SIANG';
    if (hour < 18) return 'SELAMAT SORE';
    return 'SELAMAT MALAM';
  }

}

// ── Top bar ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
      child: Row(
        children: [
          const Spacer(),
          _ProfileButton(initials: _initialsOf(name)),
        ],
      ),
    );
  }

  String _initialsOf(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => context.push('/profile'),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: AppColors.slate200, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.slate900.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary600,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Purpose banner ──────────────────────────────────────────────────────

class _PurposeBanner extends StatelessWidget {
  const _PurposeBanner({required this.purpose});
  final ClassListPurpose purpose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        border: Border.all(color: AppColors.primary600.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
            ),
            child: Icon(purpose.icon, color: AppColors.primary600, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purpose.title,
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  purpose.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Class tile ──────────────────────────────────────────────────────────

class _ClassTile extends StatelessWidget {
  const _ClassTile({required this.ta, this.onTap});
  final TeachingAssignmentSummary ta;
  final void Function(TeachingAssignmentSummary ta)? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FlozCard(
      onTap: () {
        if (onTap != null) {
          onTap!(ta);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ClassDetailScreen(
                taId: ta.id,
                subjectName: ta.subjectName,
                className: ta.className,
              ),
            ),
          );
        }
      },
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
            ),
            child: const Icon(Icons.menu_book_rounded, color: AppColors.primary600, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ta.subjectName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.slate900,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  ta.className,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.slate500),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _CountBadge(icon: Icons.people_outline_rounded, label: '${ta.studentCount} siswa'),
                    _CountBadge(icon: Icons.event_note_rounded, label: '${ta.meetingCount} pertemuan'),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Icon(Icons.chevron_right_rounded, color: AppColors.slate300, size: 20),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.slate600),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate600)),
        ],
      ),
    );
  }
}
