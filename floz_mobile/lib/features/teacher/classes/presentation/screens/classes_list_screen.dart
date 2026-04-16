import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../../../../shared/widgets/floz_card.dart';
import '../../../../../shared/widgets/staggered_entry.dart';
import '../../domain/entities/teaching_assignment_summary.dart';
import '../../providers/teacher_class_providers.dart';
import 'class_detail_screen.dart';

class ClassesListScreen extends ConsumerWidget {
  const ClassesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teacherClassListNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text('Kelas Saya'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate900,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.slate200,
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary600,
          backgroundColor: Colors.white,
          strokeWidth: 2.5,
          onRefresh: () =>
              ref.read(teacherClassListNotifierProvider.notifier).refresh(),
          child: state.when(
            data: (list) => _ClassesList(classes: list),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary600),
            ),
            error: (err, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                    height: MediaQuery.of(context).size.height * 0.2),
                ErrorState(
                  message:
                      err is Failure ? err.message : 'Gagal memuat kelas',
                  onRetry: () => ref
                      .read(teacherClassListNotifierProvider.notifier)
                      .refresh(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassesList extends StatelessWidget {
  const _ClassesList({required this.classes});
  final List<TeachingAssignmentSummary> classes;

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 36,
                  color: AppColors.primary600,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Belum ada kelas yang diampu',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Kelas yang Anda ampu akan\nmuncul di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.slate500,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: classes.length,
      separatorBuilder: (_, i) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final ta = classes[i];
        return StaggeredEntry(
          index: i,
          child: _ClassTile(ta: ta),
        );
      },
    );
  }
}

class _ClassTile extends StatelessWidget {
  const _ClassTile({required this.ta});
  final TeachingAssignmentSummary ta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FlozCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClassDetailScreen(
              taId: ta.id,
              subjectName: ta.subjectName,
              className: ta.className,
            ),
          ),
        );
      },
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book icon chip
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.primary600,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          // Content
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.slate500,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _CountBadge(
                      icon: Icons.people_outline_rounded,
                      label: '${ta.studentCount} siswa',
                    ),
                    _CountBadge(
                      icon: Icons.event_note_rounded,
                      label: '${ta.meetingCount} pertemuan',
                    ),
                    _CountBadge(
                      icon: Icons.calendar_today_outlined,
                      label: ta.academicYear,
                      bgColor: AppColors.info50,
                      fgColor: AppColors.info700,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.slate300,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.icon,
    required this.label,
    this.bgColor = AppColors.slate100,
    this.fgColor = AppColors.slate600,
  });

  final IconData icon;
  final String label;
  final Color bgColor;
  final Color fgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fgColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
