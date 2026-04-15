import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/floz_card.dart';
import '../providers/report_card_providers.dart';

class ReportCardsListScreen extends ConsumerWidget {
  const ReportCardsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportCardsAsync = ref.watch(reportCardsProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: Text(
          'Rapor Akademik',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral800,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.neutral800),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(reportCardsProvider.future),
        child: reportCardsAsync.when(
          data: (reportCards) {
            if (reportCards.isEmpty) {
              return ListView(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const HeroIcon(
                          HeroIcons.documentText,
                          size: 48,
                          color: AppColors.neutral300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Kamu belum memiliki rapor.',
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
              itemCount: reportCards.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final rc = reportCards[index];
                return FlozCard(
                  onTap: () => context.push('/profile/report-cards/${rc.id}'),
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const HeroIcon(
                        HeroIcons.academicCap,
                        color: AppColors.primary600,
                      ),
                    ),
                    title: Text(
                      '${rc.semesterName} (${rc.academicYear})',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral800,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Nilai Rata-rata: ${rc.averageScore.toStringAsFixed(1)}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.neutral600,
                              ),
                            ),
                          ),
                          if (rc.rank != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Rank ${rc.rank}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    trailing: const HeroIcon(
                      HeroIcons.chevronRight,
                      size: 20,
                      color: AppColors.neutral400,
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
                  'Gagal memuat rapor',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => ref.refresh(reportCardsProvider),
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
