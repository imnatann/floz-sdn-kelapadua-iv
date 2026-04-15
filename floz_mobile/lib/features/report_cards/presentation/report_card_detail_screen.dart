import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/floz_card.dart';
import '../providers/report_card_providers.dart';

class ReportCardDetailScreen extends ConsumerWidget {
  final int id;

  const ReportCardDetailScreen({super.key, required this.id});

  Future<void> _downloadPdf(BuildContext context, WidgetRef ref) async {
    try {
      final url = await ref.read(reportCardRepositoryProvider).getPdfUrl(id);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak dapat membuka PDF')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mendapatkan PDF: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(reportCardDetailProvider(id));

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text('Detail Rapor'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.neutral800),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.neutral800,
        ),
        actions: [
          IconButton(
            onPressed: () => _downloadPdf(context, ref),
            icon: const HeroIcon(
              HeroIcons.arrowDownTray,
              color: AppColors.primary600,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(reportCardDetailProvider(id).future),
        child: detailAsync.when(
          data: (rc) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FlozCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          '${rc.semesterName} (${rc.academicYear})',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutral800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kelas ${rc.className}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBox(
                          'Total Nilai',
                          rc.totalScore.toStringAsFixed(1),
                          HeroIcons.plusCircle,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatBox(
                          'Rata-rata',
                          rc.averageScore.toStringAsFixed(1),
                          HeroIcons.calculator,
                          Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatBox(
                          'Ranking',
                          rc.rank?.toString() ?? '-',
                          HeroIcons.trophy,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Attendance
                  FlozCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kehadiran',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutral800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildAttendanceItem(
                              'Hadir',
                              rc.attendancePresent,
                              Colors.green,
                            ),
                            _buildAttendanceItem(
                              'Sakit',
                              rc.attendanceSick,
                              Colors.orange,
                            ),
                            _buildAttendanceItem(
                              'Izin',
                              rc.attendancePermit,
                              Colors.blue,
                            ),
                            _buildAttendanceItem(
                              'Alpa',
                              rc.attendanceAbsent,
                              Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Comments
                  if (rc.homeroomComment != null ||
                      rc.principalComment != null ||
                      rc.achievements != null)
                    FlozCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (rc.achievements != null) ...[
                            _buildCommentSection('Prestasi', rc.achievements!),
                            const Divider(height: 24),
                          ],
                          if (rc.homeroomComment != null) ...[
                            _buildCommentSection(
                              'Catatan Wali Kelas',
                              rc.homeroomComment!,
                            ),
                            const Divider(height: 24),
                          ],
                          if (rc.principalComment != null) ...[
                            _buildCommentSection(
                              'Catatan Kepala Sekolah',
                              rc.principalComment!,
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildStatBox(
    String label,
    String value,
    HeroIcons icon,
    MaterialColor color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade100),
      ),
      child: Column(
        children: [
          HeroIcon(icon, size: 24, color: color.shade600),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, color: color.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem(String label, int value, MaterialColor color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.neutral500),
        ),
      ],
    );
  }

  Widget _buildCommentSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.neutral600,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
