import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../../../../shared/widgets/floz_card.dart';
import '../../../../../shared/widgets/staggered_entry.dart';
import '../../domain/entities/announcement.dart';
import '../../providers/announcement_providers.dart';
import 'announcement_detail_screen.dart';

class AnnouncementsListScreen extends ConsumerWidget {
  const AnnouncementsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(announcementListNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary600,
          backgroundColor: Colors.white,
          strokeWidth: 2.5,
          onRefresh: () => ref.read(announcementListNotifierProvider.notifier).refresh(),
          child: state.when(
            data: (announcements) => _AnnouncementsList(announcements: announcements),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary600)),
            error: (err, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                ErrorState(
                  message: err is Failure ? err.message : 'Gagal memuat pengumuman',
                  onRetry: () => ref.read(announcementListNotifierProvider.notifier).refresh(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementsList extends StatelessWidget {
  const _AnnouncementsList({required this.announcements});
  final List<AnnouncementSummary> announcements;

  @override
  Widget build(BuildContext context) {
    if (announcements.isEmpty) {
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
                child: const Icon(Icons.campaign_outlined, size: 36, color: AppColors.primary600),
              ),
              const SizedBox(height: 20),
              const Text(
                'Belum ada pengumuman',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pengumuman dari sekolah akan\nmuncul di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.slate500, height: 1.5),
              ),
            ],
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: announcements.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final a = announcements[i];
        return StaggeredEntry(
          index: i,
          child: FlozCard(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AnnouncementDetailScreen(id: a.id, title: a.title),
                ),
              );
            },
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (a.coverImageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                    child: CachedNetworkImage(
                      imageUrl: a.coverImageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 60,
                        height: 60,
                        color: AppColors.slate100,
                        child: const Icon(Icons.image_not_supported_outlined,
                            color: AppColors.slate400, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (a.isPinned) ...[
                            const Icon(Icons.push_pin_rounded, size: 14, color: AppColors.primary500),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              a.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.slate900,
                                    fontWeight: FontWeight.w700,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        a.excerpt,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _TypeBadge(type: a.type),
                          const Spacer(),
                          if (a.createdAt != null)
                            Text(
                              DateFormat('d MMM y').format(a.createdAt!),
                              style: const TextStyle(fontSize: 11, color: AppColors.slate400),
                            ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.slate400, size: 18),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
