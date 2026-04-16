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

class GradeDetailScreen extends ConsumerWidget {
  const GradeDetailScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  final int subjectId;
  final String subjectName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gradeDetailProvider(subjectId));

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(title: Text(subjectName)),
      body: state.when(
        data: (info) => _DetailContent(info: info),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary600)),
        error: (err, _) => ErrorState(
          message: err is Failure ? err.message : 'Gagal memuat detail nilai',
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.info});
  final SubjectGradeInfo info;

  @override
  Widget build(BuildContext context) {
    if (info.grades.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada nilai untuk mata pelajaran ini.',
          style: TextStyle(color: AppColors.slate500),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: info.grades.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final g = info.grades[i];
        return StaggeredEntry(
          index: i,
          child: FlozCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                      ),
                      child: Text(
                        g.semester,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary700),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: g.finalScore >= info.kkm
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                      ),
                      child: Text(
                        g.predicate,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: g.finalScore >= info.kkm ? AppColors.success500 : AppColors.danger500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _ScoreRow('Rata-rata Harian', g.dailyTestAvg),
                _ScoreRow('UTS', g.midTest),
                _ScoreRow('UAS', g.finalTest),
                if (g.knowledgeScore != null) _ScoreRow('Pengetahuan', g.knowledgeScore!),
                if (g.skillScore != null) _ScoreRow('Keterampilan', g.skillScore!),
                const Divider(height: 20, color: AppColors.slate100),
                _ScoreRow('Nilai Akhir', g.finalScore, isBold: true),
                if (g.notes != null && g.notes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Catatan: ${g.notes}',
                    style: const TextStyle(fontSize: 12, color: AppColors.slate600, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow(this.label, this.value, {this.isBold = false});
  final String label;
  final double value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.slate600,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
        ],
      ),
    );
  }
}
