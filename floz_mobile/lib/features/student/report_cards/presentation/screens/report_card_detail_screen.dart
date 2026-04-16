import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../../../../shared/widgets/floz_card.dart';
import '../../domain/entities/report_card.dart';
import '../../providers/report_card_providers.dart';

class ReportCardDetailScreen extends ConsumerWidget {
  const ReportCardDetailScreen({
    super.key,
    required this.reportCardId,
    required this.semesterName,
  });

  final int reportCardId;
  final String semesterName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportCardDetailProvider(reportCardId));

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(title: Text(semesterName)),
      body: state.when(
        data: (detail) => _DetailContent(detail: detail),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary600),
        ),
        error: (err, _) => ErrorState(
          message: err is Failure ? err.message : 'Gagal memuat detail rapor',
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.detail});
  final ReportCardDetail detail;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Summary card
        _SummaryCard(detail: detail),
        const SizedBox(height: 12),
        // Kehadiran card
        _AttendanceCard(detail: detail),
        const SizedBox(height: 12),
        // Catatan section
        if (detail.achievements != null ||
            detail.behaviorNotes != null ||
            detail.notes != null)
          _NotesSection(detail: detail),
        // Komentar section
        if (detail.homeroomComment != null || detail.principalComment != null) ...[
          const SizedBox(height: 12),
          _CommentsSection(detail: detail),
        ],
        const SizedBox(height: 24),
        // PDF button
        _PdfButton(pdfUrl: detail.pdfUrl),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.detail});
  final ReportCardDetail detail;

  @override
  Widget build(BuildContext context) {
    return FlozCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.className,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.slate500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                detail.averageScore.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'rata-rata',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.slate400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.slate100),
          const SizedBox(height: 12),
          Row(
            children: [
              _SummaryChip(
                label: 'Total Nilai',
                value: detail.totalScore.toStringAsFixed(1),
              ),
              if (detail.rank != null) ...[
                const SizedBox(width: 12),
                _SummaryChip(
                  label: 'Peringkat',
                  value: '${detail.rank}',
                  bgColor: AppColors.warning50,
                  textColor: AppColors.warning700,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    this.bgColor = AppColors.primary50,
    this.textColor = AppColors.primary700,
  });

  final String label;
  final String value;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.detail});
  final ReportCardDetail detail;

  @override
  Widget build(BuildContext context) {
    final total = detail.totalAttendance;

    return FlozCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kehadiran',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.slate800,
            ),
          ),
          const SizedBox(height: 14),
          _AttendanceRow(
            label: 'Hadir',
            count: detail.attendancePresent,
            total: total,
            color: AppColors.success500,
          ),
          const SizedBox(height: 10),
          _AttendanceRow(
            label: 'Sakit',
            count: detail.attendanceSick,
            total: total,
            color: AppColors.warning500,
          ),
          const SizedBox(height: 10),
          _AttendanceRow(
            label: 'Izin',
            count: detail.attendancePermit,
            total: total,
            color: AppColors.info500,
          ),
          const SizedBox(height: 10),
          _AttendanceRow(
            label: 'Alpha',
            count: detail.attendanceAbsent,
            total: total,
            color: AppColors.danger500,
          ),
        ],
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? count / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 48,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 6,
                  backgroundColor: AppColors.slate100,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count hari',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.slate600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({required this.detail});
  final ReportCardDetail detail;

  @override
  Widget build(BuildContext context) {
    return FlozCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catatan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.slate800,
            ),
          ),
          const SizedBox(height: 12),
          if (detail.achievements != null) ...[
            _NoteItem(title: 'Prestasi', content: detail.achievements!),
            const SizedBox(height: 10),
          ],
          if (detail.behaviorNotes != null) ...[
            _NoteItem(title: 'Catatan Perilaku', content: detail.behaviorNotes!),
            const SizedBox(height: 10),
          ],
          if (detail.notes != null)
            _NoteItem(title: 'Catatan Lain', content: detail.notes!),
        ],
      ),
    );
  }
}

class _NoteItem extends StatelessWidget {
  const _NoteItem({required this.title, required this.content});
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.slate500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.slate700,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({required this.detail});
  final ReportCardDetail detail;

  @override
  Widget build(BuildContext context) {
    return FlozCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Komentar',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.slate800,
            ),
          ),
          const SizedBox(height: 12),
          if (detail.homeroomComment != null) ...[
            _NoteItem(title: 'Wali Kelas', content: detail.homeroomComment!),
            const SizedBox(height: 10),
          ],
          if (detail.principalComment != null)
            _NoteItem(title: 'Kepala Sekolah', content: detail.principalComment!),
        ],
      ),
    );
  }
}

class _PdfButton extends StatelessWidget {
  const _PdfButton({required this.pdfUrl});
  final String? pdfUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: pdfUrl != null
            ? () {
                launchUrl(
                  Uri.parse(pdfUrl!),
                  mode: LaunchMode.externalApplication,
                );
              }
            : null,
        icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
        label: const Text('Unduh Rapor PDF'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary700,
          side: const BorderSide(color: AppColors.primary200),
          backgroundColor: AppColors.primary50,
          disabledForegroundColor: AppColors.slate400,
          disabledBackgroundColor: AppColors.slate100,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
