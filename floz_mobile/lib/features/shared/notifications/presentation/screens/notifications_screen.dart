import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/auth/auth_session.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../../../../shared/widgets/floz_card.dart';
import '../../../../student/shared/providers/student_tab_providers.dart';
import '../../../../teacher/shared/providers/teacher_tab_providers.dart';
import '../../domain/entities/notification_item.dart';
import '../../providers/notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(notificationsPageProvider);
    try {
      await ref.read(notificationsPageProvider.future);
    } catch (_) {
      /* ignore — error UI is shown by the AsyncValue branch */
    }
  }

  Future<void> _markAllAsRead(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(notificationsRepositoryProvider);
    await repo.markAllAsRead();
    ref.invalidate(notificationsPageProvider);
  }

  void _onTapNotification(
      BuildContext context, WidgetRef ref, NotificationItem n) async {
    if (!n.isRead) {
      // fire-and-forget mark-as-read; UI will refresh on next provider read
      ref.read(notificationsRepositoryProvider).markAsRead(n.id);
      ref.invalidate(notificationsPageProvider);
    }

    final action = n.action;
    if (action == null) {
      Navigator.of(context).pop();
      return;
    }

    final role = ref.read(authSessionProvider).user?.role;
    Navigator.of(context).pop();

    switch (action.screen) {
      case 'grades':
        if (role == 'student') {
          ref.read(studentSelectedTabProvider.notifier).state = 2; // Nilai
        }
        break;
      case 'announcement_detail':
        if (role == 'student') {
          ref.read(studentSelectedTabProvider.notifier).state = 4; // Info
        }
        break;
      case 'assignments':
        if (role == 'student') {
          ref.read(studentSelectedTabProvider.notifier).state = 5; // Tugas
        } else if (role == 'teacher') {
          ref.read(teacherSelectedTabProvider.notifier).state = 1; // Nilai (input)
        }
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPage = ref.watch(notificationsPageProvider);
    final unread =
        asyncPage.maybeWhen(data: (p) => p.unreadCount, orElse: () => 0);

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.slate200,
        foregroundColor: AppColors.slate900,
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.slate900,
          ),
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () => _markAllAsRead(context, ref),
              child: const Text(
                'Tandai semua dibaca',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary600,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary600,
        onRefresh: () => _refresh(ref),
        child: asyncPage.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary600),
          ),
          error: (err, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
              ErrorState(
                message:
                    err is Failure ? err.message : 'Gagal memuat notifikasi',
                onRetry: () => ref.invalidate(notificationsPageProvider),
              ),
            ],
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                  FlozCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            size: 48, color: AppColors.slate400),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada notifikasi.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: page.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _NotificationCard(
                item: page.items[i],
                onTap: () => _onTapNotification(context, ref, page.items[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});
  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRead = item.isRead;
    return Material(
      color: isRead ? Colors.white : AppColors.primary50,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
            border: Border.all(
              color: isRead ? AppColors.slate100 : AppColors.primary100,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isRead ? AppColors.slate100 : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                ),
                child: Icon(
                  _iconFor(item.icon),
                  size: 20,
                  color: AppColors.primary600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.body,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate600,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _relativeTime(item.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate400,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4, left: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary600,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'star':
        return Icons.star_rounded;
      case 'campaign':
        return Icons.campaign_rounded;
      case 'assignment':
        return Icons.assignment_rounded;
      case 'event_busy':
        return Icons.event_busy_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
