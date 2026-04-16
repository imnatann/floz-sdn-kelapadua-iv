import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../domain/entities/announcement.dart';
import '../../providers/announcement_providers.dart';

class AnnouncementDetailScreen extends ConsumerWidget {
  const AnnouncementDetailScreen({
    super.key,
    required this.id,
    required this.title,
  });

  final int id;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(announcementDetailProvider(id));

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text('Pengumuman'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate900,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: state.when(
        data: (detail) => _DetailContent(detail: detail),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary600)),
        error: (err, _) => ErrorState(
          message: err is Failure ? err.message : 'Gagal memuat pengumuman',
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.detail});
  final AnnouncementDetail detail;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detail.coverImageUrl != null)
            CachedNetworkImage(
              imageUrl: detail.coverImageUrl!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                width: double.infinity,
                height: 200,
                color: AppColors.slate100,
                child: const Icon(Icons.image_not_supported_outlined,
                    color: AppColors.slate400, size: 32),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  detail.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontFamily: 'SpaceGrotesk',
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                      ),
                ),
                const SizedBox(height: 10),
                // Date + type badges row
                Row(
                  children: [
                    if (detail.createdAt != null) ...[
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: AppColors.slate400),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('d MMM y').format(detail.createdAt!),
                        style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                      ),
                      const SizedBox(width: 10),
                    ],
                    _TypeBadge(type: detail.type),
                    if (detail.isPinned) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary50,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXS),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.push_pin_rounded, size: 12, color: AppColors.primary500),
                            SizedBox(width: 3),
                            Text(
                              'Disematkan',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.slate100),
                const SizedBox(height: 16),
                // Content — plain text (HTML tags stripped)
                Text(
                  _stripHtml(detail.content),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.slate700,
                        height: 1.6,
                      ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final String type;

  Color get _bgColor {
    switch (type.toLowerCase()) {
      case 'warning':
        return AppColors.warning50;
      case 'info':
        return AppColors.info50;
      default:
        return AppColors.primary50;
    }
  }

  Color get _textColor {
    switch (type.toLowerCase()) {
      case 'warning':
        return AppColors.warning700;
      case 'info':
        return AppColors.info700;
      default:
        return AppColors.primary700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXS),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _textColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
