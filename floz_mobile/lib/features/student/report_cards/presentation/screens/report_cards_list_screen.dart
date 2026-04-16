import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../../../../shared/widgets/floz_card.dart';
import '../../../../../shared/widgets/staggered_entry.dart';
import '../../domain/entities/report_card.dart';
import '../../providers/report_card_providers.dart';
import 'report_card_detail_screen.dart';

class ReportCardsListScreen extends ConsumerWidget {
  const ReportCardsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportCardListNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary600,
          backgroundColor: Colors.white,
          strokeWidth: 2.5,
          onRefresh: () => ref.read(reportCardListNotifierProvider.notifier).refresh(),
          child: state.when(
            data: (cards) => _ReportCardsList(cards: cards),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary600),
            ),
            error: (err, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                ErrorState(
                  message: err is Failure ? err.message : 'Gagal memuat rapor',
                  onRetry: () => ref.read(reportCardListNotifierProvider.notifier).refresh(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportCardsList extends StatelessWidget {
  const _ReportCardsList({required this.cards});
  final List<ReportCardSummary> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
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
                  Icons.description_outlined,
                  size: 36,
                  color: AppColors.primary600,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Belum ada rapor',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Rapor akan tersedia setelah wali kelas mempublikasikan.',
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: cards.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final card = cards[i];
        return StaggeredEntry(
          index: i,
          child: _ReportCardItem(summary: card),
        );
      },
    );
  }
}

class _ReportCardItem extends StatelessWidget {
  const _ReportCardItem({required this.summary});
  final ReportCardSummary summary;

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return FlozCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReportCardDetailScreen(
              reportCardId: summary.id,
              semesterName: summary.semesterName,
            ),
          ),
        );
      },
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
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
                        summary.semesterName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary700,
                        ),
                      ),
                    ),
                    if (summary.rank != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning50,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                        ),
                        child: Text(
                          'Peringkat ${summary.rank}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  summary.academicYear,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      summary.averageScore.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'rata-rata',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.slate400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (summary.publishedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Diterbitkan ${_formatDate(summary.publishedAt!)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.slate400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.slate400, size: 20),
        ],
      ),
    );
  }
}
