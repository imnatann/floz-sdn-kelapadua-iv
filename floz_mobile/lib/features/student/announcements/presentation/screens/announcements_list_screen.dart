import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          onRefresh: () =>
              ref.read(announcementListNotifierProvider.notifier).refresh(),
          child: state.when(
            data: (list) => _AnnouncementsList(announcements: list),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary600),
            ),
            error: (err, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                ErrorState(
                  message:
                      err is Failure ? err.message : 'Gagal memuat pengumuman',
                  onRetry: () => ref
                      .read(announcementListNotifierProvider.notifier)
                      .refresh(),
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
                child: const Icon(Icons.campaign_outlined,
                    size: 36, color: AppColors.primary600),
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
                style: TextStyle(
                    fontSize: 13, color: AppColors.slate500, height: 1.5),
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
      separatorBuilder: (_, i) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final a = announcements[i];
        return StaggeredEntry(
          index: i,
          child: _AnnouncementTile(announcement: a),
        );
      },
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.announcement});
  final AnnouncementSummary announcement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = announcement;

    return FlozCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AnnouncementDetailScreen(id: a.id, title: a.title),
          ),
        );
      },
      borderColor: a.isPinned ? AppColors.primary200 : null,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon chip
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _iconBg(a.type),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
            ),
            child: Icon(
              a.isPinned ? Icons.push_pin_rounded : Icons.campaign_rounded,
              color: _iconColor(a.type),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        a.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.slate900,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TypeBadge(type: a.type),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  a.excerpt,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.slate500,
                    height: 1.45,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (a.isPinned) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Disematkan',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(Icons.access_time_rounded,
                        size: 12, color: AppColors.slate400),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(a.createdAt),
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.slate400,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Icon(Icons.chevron_right_rounded,
                color: AppColors.slate300, size: 20),
          ),
        ],
      ),
    );
  }

  Color _iconBg(String type) {
    switch (type.toLowerCase()) {
      case 'warning':
        return AppColors.warning50;
      case 'info':
        return AppColors.info50;
      default:
        return AppColors.primary50;
    }
  }

  Color _iconColor(String type) {
    switch (type.toLowerCase()) {
      case 'warning':
        return AppColors.warning500;
      case 'info':
        return AppColors.info500;
      default:
        return AppColors.primary600;
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (type.toLowerCase()) {
      'warning' => (AppColors.warning50, AppColors.warning700),
      'info' => (AppColors.info50, AppColors.info700),
      _ => (AppColors.primary50, AppColors.primary700),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
