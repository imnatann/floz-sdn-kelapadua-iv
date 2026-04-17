import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../../../../shared/widgets/floz_card.dart';
import '../../../../../shared/widgets/staggered_entry.dart';
import '../../domain/entities/meeting_summary.dart';
import '../../providers/courses_providers.dart';
import 'meeting_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Course detail (meetings list) screen
// ─────────────────────────────────────────────────────────────────────────────

class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({
    super.key,
    required this.taId,
    required this.subjectName,
    required this.className,
  });

  final int taId;
  final String subjectName;
  final String className;

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(courseMeetingsProvider(taId));
    await ref.read(courseMeetingsProvider(taId).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(courseMeetingsProvider(taId));

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate900,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.slate200,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subjectName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.slate900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              className,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.slate500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
                    : 'Gagal memuat daftar pertemuan',
                onRetry: () =>
                    ref.invalidate(courseMeetingsProvider(taId)),
              ),
            ],
          ),
          data: (data) {
            final meetings = [...data.meetings]
              ..sort((a, b) => a.meetingNumber.compareTo(b.meetingNumber));

            if (meetings.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 60),
                  _EmptyState(),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: meetings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => StaggeredEntry(
                index: i,
                child: _MeetingCard(meeting: meetings[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meeting card
// ─────────────────────────────────────────────────────────────────────────────

class _MeetingCard extends StatelessWidget {
  const _MeetingCard({required this.meeting});

  final MeetingSummary meeting;

  String _badgeText(int n) {
    if (n == 15) return 'UTS';
    if (n == 16) return 'UAS';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final locked = meeting.isLocked;
    final badge = _badgeText(meeting.meetingNumber);
    final isExam = meeting.meetingNumber == 15 || meeting.meetingNumber == 16;

    final card = FlozCard(
      color: locked ? AppColors.slate100 : null,
      onTap: locked
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      MeetingDetailScreen(meetingId: meeting.id),
                ),
              ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _NumberBadge(text: badge, emphasized: isExam),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meeting.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _MaterialChip(count: meeting.materialCount),
                    if (locked) const _LockedIndicator(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            locked
                ? Icons.lock_rounded
                : Icons.arrow_forward_ios_rounded,
            size: locked ? 16 : 14,
            color: locked ? AppColors.slate400 : AppColors.slate500,
          ),
        ],
      ),
    );

    if (locked) {
      return Opacity(opacity: 0.7, child: card);
    }
    return card;
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.text, required this.emphasized});

  final String text;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: emphasized ? AppColors.warning50 : AppColors.primary50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: emphasized ? 12 : 14,
          fontWeight: FontWeight.w800,
          color: emphasized ? AppColors.warning700 : AppColors.slate900,
        ),
      ),
    );
  }
}

class _MaterialChip extends StatelessWidget {
  const _MaterialChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.menu_book_rounded,
            size: 12,
            color: AppColors.slate600,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.slate700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedIndicator extends StatelessWidget {
  const _LockedIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(
          Icons.lock_outline_rounded,
          size: 12,
          color: AppColors.slate500,
        ),
        SizedBox(width: 4),
        Text(
          'Belum dibuka',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.slate500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: AppColors.primary50,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
          ),
          child: const Icon(
            Icons.event_note_rounded,
            size: 36,
            color: AppColors.primary600,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Belum ada pertemuan',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.slate900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Daftar pertemuan akan muncul setelah guru menambahkannya.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.slate500,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
