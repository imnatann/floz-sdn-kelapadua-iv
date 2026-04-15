import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/floz_card.dart';
import '../providers/grades_providers.dart';

class GradesListScreen extends ConsumerWidget {
  const GradesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesAsync = ref.watch(gradesSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: Text(
          'Nilai',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral800,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(gradesSummaryProvider.future),
        child: gradesAsync.when(
          data: (grades) {
            if (grades.isEmpty) {
              return ListView(
                // ListView makes RefreshIndicator work
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🏖️', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada data nilai',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutral900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kamu belum memiliki nilai semester ini.',
                          style: GoogleFonts.inter(color: AppColors.neutral500),
                        ),
                      ],
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
                return FlozCard(
                  onTap: () => context.push('/grades/${grade.subjectId}'),
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const HeroIcon(
                        HeroIcons.bookOpen,
                        color: AppColors.primary600,
                      ),
                    ),
                    title: Text(
                      grade.subjectName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral800,
                      ),
                    ),
                    subtitle: Text(
                      '${grade.gradeCount} Komponen Nilai',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.neutral500,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: grade.average >= 75
                            ? AppColors.success50
                            : AppColors.danger50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        grade.average.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: grade.average >= 75
                              ? AppColors.success700
                              : AppColors.danger700,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const HeroIcon(
                  HeroIcons.exclamationCircle,
                  size: 48,
                  color: AppColors.danger500,
                ),
                const SizedBox(height: 16),
                Text(
                  'Gagal memuat nilai',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => ref.refresh(gradesSummaryProvider),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
