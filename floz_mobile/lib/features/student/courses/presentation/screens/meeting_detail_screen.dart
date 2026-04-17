import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../../../../shared/widgets/floz_card.dart';
import '../../../../../shared/widgets/staggered_entry.dart';
import '../../domain/entities/material_item.dart' as mat;
import '../../domain/entities/meeting_detail.dart';
import '../../providers/courses_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Meeting detail screen
// ─────────────────────────────────────────────────────────────────────────────

class MeetingDetailScreen extends ConsumerWidget {
  const MeetingDetailScreen({super.key, required this.meetingId});

  final int meetingId;

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(meetingDetailProvider(meetingId));
    await ref.read(meetingDetailProvider(meetingId).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(meetingDetailProvider(meetingId));

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate900,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.slate200,
        title: Text(
          async.maybeWhen(
            data: (detail) => detail.meeting.title,
            orElse: () => 'Detail Pertemuan',
          ),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.slate900,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary600,
        backgroundColor: Colors.white,
        strokeWidth: 2.5,
        onRefresh: () => _refresh(ref),
        child: async.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.4),
              const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary600,
                ),
              ),
            ],
          ),
          error: (err, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.12),
              ErrorState(
                message: err is Failure
                    ? err.message
                    : 'Gagal memuat detail pertemuan',
                onRetry: () =>
                    ref.invalidate(meetingDetailProvider(meetingId)),
              ),
            ],
          ),
          data: (detail) => _MeetingBody(detail: detail),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _MeetingBody extends StatelessWidget {
  const _MeetingBody({required this.detail});

  final MeetingDetail detail;

  String _meetingNumberLabel(int n) {
    if (n == 15) return 'UTS';
    if (n == 16) return 'UAS';
    return 'Pertemuan $n';
  }

  @override
  Widget build(BuildContext context) {
    final header = detail.meeting;
    final materials = [...detail.materials]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _Header(
          numberLabel: _meetingNumberLabel(header.meetingNumber),
          title: header.title,
          subjectName: header.subjectName,
          className: header.className,
          description: header.description,
        ),
        const SizedBox(height: 16),
        if (materials.isEmpty)
          const _EmptyMaterials()
        else
          ...List.generate(materials.length, (i) {
            return Padding(
              padding: EdgeInsets.only(bottom: i == materials.length - 1 ? 0 : 10),
              child: StaggeredEntry(
                index: i,
                child: _MaterialCard(material: materials[i]),
              ),
            );
          }),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.numberLabel,
    required this.title,
    required this.subjectName,
    required this.className,
    required this.description,
  });

  final String numberLabel;
  final String title;
  final String subjectName;
  final String className;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return FlozCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSM),
                ),
                child: Text(
                  numberLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$subjectName · $className',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
            ),
          ),
          if (description != null && description!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.slate600,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Material rendering
// ─────────────────────────────────────────────────────────────────────────────

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({required this.material});

  final mat.MaterialItem material;

  @override
  Widget build(BuildContext context) {
    switch (material.type) {
      case mat.MaterialType.text:
        return _TextMaterial(material: material);
      case mat.MaterialType.link:
        return _LinkMaterial(material: material);
      case mat.MaterialType.file:
        return _FileMaterial(material: material);
      case mat.MaterialType.unknown:
        return const _UnknownMaterial();
    }
  }
}

class _TextMaterial extends StatelessWidget {
  const _TextMaterial({required this.material});

  final mat.MaterialItem material;

  @override
  Widget build(BuildContext context) {
    return FlozCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSM),
                ),
                child: const Icon(
                  Icons.text_snippet_rounded,
                  size: 18,
                  color: AppColors.slate600,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  material.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate900,
                  ),
                ),
              ),
            ],
          ),
          if ((material.content ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              material.content!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.slate700,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LinkMaterial extends StatelessWidget {
  const _LinkMaterial({required this.material});

  final mat.MaterialItem material;

  @override
  Widget build(BuildContext context) {
    final url = material.url ?? '';
    return FlozCard(
      onTap: () => _launchExternal(context, material.url),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.info50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
            ),
            child: const Icon(
              Icons.link_rounded,
              size: 18,
              color: AppColors.info700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  url,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.slate500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.open_in_new_rounded,
            size: 16,
            color: AppColors.slate400,
          ),
        ],
      ),
    );
  }
}

class _FileMaterial extends StatelessWidget {
  const _FileMaterial({required this.material});

  final mat.MaterialItem material;

  @override
  Widget build(BuildContext context) {
    final fileName = material.fileName ?? '—';
    final size = material.fileSize == null
        ? null
        : _formatBytes(material.fileSize!);

    return FlozCard(
      onTap: () => _launchExternal(context, material.fileUrl),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
            ),
            child: const Icon(
              Icons.insert_drive_file_rounded,
              size: 18,
              color: AppColors.primary700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        fileName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.slate500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (size != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: AppColors.slate400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        size,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.download_rounded,
            size: 16,
            color: AppColors.slate400,
          ),
        ],
      ),
    );
  }
}

class _UnknownMaterial extends StatelessWidget {
  const _UnknownMaterial();

  @override
  Widget build(BuildContext context) {
    return FlozCard(
      color: AppColors.slate100,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.slate200,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              size: 18,
              color: AppColors.slate500,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Tipe materi tidak dikenali',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.slate500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMaterials extends StatelessWidget {
  const _EmptyMaterials();

  @override
  Widget build(BuildContext context) {
    return FlozCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              size: 32,
              color: AppColors.primary600,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada materi untuk pertemuan ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.slate500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _launchExternal(BuildContext context, String? raw) async {
  if (raw == null || raw.isEmpty) {
    _showError(context, 'Tidak dapat membuka tautan.');
    return;
  }
  final uri = Uri.tryParse(raw);
  if (uri == null) {
    _showError(context, 'Tidak dapat membuka tautan.');
    return;
  }
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      _showError(context, 'Tidak dapat membuka tautan.');
    }
  } catch (_) {
    if (context.mounted) {
      _showError(context, 'Tidak dapat membuka tautan.');
    }
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

// ─────────────────────────────────────────────────────────────────────────────
// File size formatter
// ─────────────────────────────────────────────────────────────────────────────

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) {
    return kb >= 100 ? '${kb.toStringAsFixed(0)} KB' : '${kb.toStringAsFixed(1)} KB';
  }
  final mb = kb / 1024;
  if (mb < 1024) {
    return mb >= 100 ? '${mb.toStringAsFixed(0)} MB' : '${mb.toStringAsFixed(1)} MB';
  }
  final gb = mb / 1024;
  return gb >= 100 ? '${gb.toStringAsFixed(0)} GB' : '${gb.toStringAsFixed(1)} GB';
}
