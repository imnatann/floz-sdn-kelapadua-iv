import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/floz_card.dart';
import '../providers/assignment_providers.dart';

class AssignmentDetailScreen extends ConsumerWidget {
  final int id;

  const AssignmentDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(assignmentDetailProvider(id));

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: Text(
          'Detail Tugas',
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
      body: detailAsync.when(
        data: (detail) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject and Type badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        detail.subject,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary600,
                        ),
                      ),
                    ),
                    if (detail.type == 'quiz')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.purple500.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Kuis',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.purple500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  detail.title,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral800,
                  ),
                ),
                const SizedBox(height: 8),

                // Teacher
                Row(
                  children: [
                    const HeroIcon(
                      HeroIcons.userCircle,
                      size: 18,
                      color: AppColors.neutral400,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      detail.teacher,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Due Date Card
                FlozCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.neutral100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const HeroIcon(
                          HeroIcons.clock,
                          color: AppColors.neutral600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Batas Waktu',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.neutral500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            detail.dueDate != null
                                ? DateFormat(
                                    'EEEE, dd MMMM yyyy, HH:mm',
                                  ).format(detail.dueDate!)
                                : 'Tidak ada batas waktu',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.neutral800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Description
                Text(
                  'Deskripsi',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  detail.description,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.neutral600,
                  ),
                ),
                const SizedBox(height: 24),

                // Attachments
                if (detail.files.isNotEmpty) ...[
                  Text(
                    'Lampiran',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...detail.files.map(
                    (file) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: FlozCard(
                        onTap: () async {
                          final url = Uri.parse(file.fileUrl);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const HeroIcon(
                              HeroIcons.document,
                              color: AppColors.primary600,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                file.fileName,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.neutral800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Submission Status
                if (detail.submission != null) ...[
                  Text(
                    'Status Pengerjaan',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FlozCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Status',
                              style: GoogleFonts.inter(
                                color: AppColors.neutral600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: detail.submission!.status == 'graded'
                                    ? AppColors.success50
                                    : AppColors.warning50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                detail.submission!.status.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: detail.submission!.status == 'graded'
                                      ? AppColors.success600
                                      : AppColors.warning600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (detail.submission!.submittedAt != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Dikirim pada',
                                style: GoogleFonts.inter(
                                  color: AppColors.neutral600,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'dd MMM yy, HH:mm',
                                ).format(detail.submission!.submittedAt!),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.neutral800,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (detail.submission!.score != null) ...[
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Nilai',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.neutral800,
                                ),
                              ),
                              Text(
                                '${detail.submission!.score}',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary600,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (detail.submission!.teacherNotes != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.neutral50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Catatan Guru:',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.neutral600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  detail.submission!.teacherNotes!,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.neutral800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Gagal memuat: $err')),
      ),
      bottomNavigationBar: detailAsync.whenData((detail) {
        if (detail.submission == null) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur pengumpulan tugas akan datang'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Kerjakan Tugas',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      }).valueOrNull,
    );
  }
}
