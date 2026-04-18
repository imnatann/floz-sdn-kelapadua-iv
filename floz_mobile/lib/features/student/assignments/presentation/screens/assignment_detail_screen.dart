import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../../../../shared/widgets/floz_card.dart';
import '../../domain/entities/assignment.dart';
import '../../providers/assignment_providers.dart';

class AssignmentDetailScreen extends ConsumerWidget {
  const AssignmentDetailScreen({
    super.key,
    required this.assignmentId,
    required this.subject,
  });

  final int assignmentId;
  final String subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assignmentDetailProvider(assignmentId));

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: Text(
          subject,
          style: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: state.when(
        data: (detail) => _DetailContent(detail: detail),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary600),
        ),
        error: (err, _) => ErrorState(
          message:
              err is Failure ? err.message : 'Gagal memuat detail tugas',
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.detail});
  final AssignmentDetail detail;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMMM yyyy, HH:mm');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Header card: title + type badge + due date
        FlozCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSM),
                ),
                child: Text(
                  detail.type.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                detail.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontFamily: 'SpaceGrotesk',
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate900,
                    ),
              ),
              if (detail.dueDate != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: AppColors.slate400,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Tenggat: ${df.format(detail.dueDate!)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 14, color: AppColors.slate400),
                  const SizedBox(width: 5),
                  Text(
                    detail.teacher,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.slate500),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Overdue banner
        if (detail.isOverdue) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.danger50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
              border: Border.all(color: AppColors.danger500),
            ),
            child: Row(
              children: const [
                Icon(Icons.warning_amber_rounded,
                    size: 18, color: AppColors.danger600),
                SizedBox(width: 8),
                Text(
                  'Terlambat — tenggat telah lewat',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger700,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Description section
        const SizedBox(height: 14),
        const _SectionLabel('Deskripsi'),
        const SizedBox(height: 6),
        FlozCard(
          padding: const EdgeInsets.all(16),
          child: Text(
            _stripHtml(detail.description),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.slate700,
              height: 1.6,
            ),
          ),
        ),

        // Files section
        if (detail.files.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _SectionLabel('Lampiran'),
          const SizedBox(height: 6),
          ...detail.files.map((f) => _FileCard(file: f)),
        ],

        // Submission section
        const SizedBox(height: 16),
        const _SectionLabel('Status Pengumpulan'),
        const SizedBox(height: 6),
        if (detail.submission != null)
          _SubmissionCard(submission: detail.submission!)
        else
          _NoSubmissionBanner(),
      ],
    );
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.slate500,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({required this.file});
  final AssignmentFile file;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FlozCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () async {
          final uri = Uri.parse(file.fileUrl);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.info50,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
              ),
              child: const Icon(
                Icons.insert_drive_file_outlined,
                size: 18,
                color: AppColors.info600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                file.fileName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.download_outlined,
              size: 18,
              color: AppColors.slate400,
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({required this.submission});
  final SubmissionInfo submission;

  @override
  Widget build(BuildContext context) {
    final isGraded = submission.status == 'graded';
    final df = DateFormat('d MMM yyyy, HH:mm');

    return FlozCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
        child: IntrinsicHeight(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              color: isGraded ? AppColors.success500 : AppColors.warning500,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isGraded
                            ? AppColors.success50
                            : AppColors.warning50,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSM),
                      ),
                      child: Text(
                        isGraded ? 'Sudah Dinilai' : 'Sudah Dikumpulkan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isGraded
                              ? AppColors.success700
                              : AppColors.warning700,
                        ),
                      ),
                    ),

                    // Score (if graded)
                    if (isGraded && submission.score != null) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            '${submission.score}',
                            style: const TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _scorePredicate(submission.score!),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate700,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Teacher notes
                    if (submission.teacherNotes != null &&
                        submission.teacherNotes!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Catatan guru:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        submission.teacherNotes!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.slate700,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],

                    // Submitted date
                    if (submission.submittedAt != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 13, color: AppColors.slate400),
                          const SizedBox(width: 4),
                          Text(
                            'Dikumpulkan ${df.format(submission.submittedAt!)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  String _scorePredicate(int score) {
    if (score >= 90) return 'Sangat Baik';
    if (score >= 80) return 'Baik';
    if (score >= 70) return 'Cukup';
    if (score >= 60) return 'Perlu Perbaikan';
    return 'Kurang';
  }
}

class _NoSubmissionBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.slate500),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Kumpulkan tugas secara langsung kepada guru di kelas.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.slate600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
