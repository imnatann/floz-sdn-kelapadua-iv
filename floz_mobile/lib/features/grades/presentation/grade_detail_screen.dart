import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/floz_card.dart';
import '../providers/grades_providers.dart';

class GradeDetailScreen extends ConsumerWidget {
  final int subjectId;

  const GradeDetailScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(gradeDetailProvider(subjectId));

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: detailAsync.when(
          data: (data) => Text(
            data.subject['name'] ?? 'Detail Nilai',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral800,
            ),
          ),
          loading: () => const Text('Memuat...'),
          error: (_, __) => const Text('Error'),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.neutral800),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(gradeDetailProvider(subjectId).future),
        child: detailAsync.when(
          data: (data) {
            final grades = data.grades;

            if (grades.isEmpty) {
              return ListView(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    alignment: Alignment.center,
                    child: const Text(
                      'Belum ada nilai untuk mata pelajaran ini.',
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: grades.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final grade = grades[index];
                final isPass = grade.finalScore >= grade.kkm;

                return FlozCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              grade.component,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.neutral800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isPass
                                  ? AppColors.success50
                                  : AppColors.danger50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              grade.finalScore.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: isPass
                                    ? AppColors.success700
                                    : AppColors.danger700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.neutral200),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailItem('KKM', grade.kkm.toString()),
                          _buildDetailItem('Skor Asli', grade.score.toString()),
                          _buildDetailItem('Predikat', grade.predicate ?? '-'),
                          _buildDetailItem(
                            'Dibuat',
                            grade.createdAt != null
                                ? DateFormat(
                                    'dd MMM yyyy',
                                  ).format(grade.createdAt!)
                                : '-',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Gagal memuat: $error')),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral400,
            letterSpacing: 0.5,
          ).copyWith(textBaseline: TextBaseline.alphabetic),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.neutral700,
          ),
        ),
      ],
    );
  }
}
