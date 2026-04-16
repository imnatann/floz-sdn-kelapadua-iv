import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../../../../shared/widgets/floz_card.dart';
import '../../../../../shared/widgets/staggered_entry.dart';
import '../../domain/entities/student_grades.dart';
import '../../providers/grade_providers.dart';
import 'grade_detail_screen.dart';

class GradesListScreen extends ConsumerWidget {
  const GradesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gradeListNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary600,
          backgroundColor: Colors.white,
          strokeWidth: 2.5,
          onRefresh: () => ref.read(gradeListNotifierProvider.notifier).refresh(),
          child: state.when(
            data: (grades) => _GradesList(grades: grades),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary600)),
            error: (err, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                ErrorState(
                  message: err is Failure ? err.message : 'Gagal memuat nilai',
                  onRetry: () => ref.read(gradeListNotifierProvider.notifier).refresh(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradesList extends StatelessWidget {
  const _GradesList({required this.grades});
  final List<SubjectGradeSummary> grades;

  @override
  Widget build(BuildContext context) {
    if (grades.isEmpty) {
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
                child: const Icon(Icons.grade_outlined, size: 36, color: AppColors.primary600),
              ),
              const SizedBox(height: 20),
              const Text(
                'Belum ada nilai',
                style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.slate900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Nilai akan muncul setelah guru\nmemasukkan penilaian.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.slate500, height: 1.5),
              ),
            ],
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: grades.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final g = grades[i];
        return StaggeredEntry(
          index: i,
          child: FlozCard(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GradeDetailScreen(
                    subjectId: g.subjectId,
                    subjectName: g.subjectName,
                  ),
                ),
              );
            },
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: g.aboveKkm ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                  ),
                  child: Center(
                    child: Text(
                      g.average.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: g.aboveKkm ? AppColors.success500 : AppColors.danger500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.subjectName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.slate900,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'KKM ${g.kkm.toStringAsFixed(0)} • ${g.gradeCount} penilaian',
                        style: const TextStyle(fontSize: 12, color: AppColors.slate500, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.slate400, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
