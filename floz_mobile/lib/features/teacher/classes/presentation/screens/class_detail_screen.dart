import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../../../../shared/widgets/floz_card.dart';
import '../../../../../shared/widgets/staggered_entry.dart';
import '../../domain/entities/class_meetings.dart';
import '../../providers/teacher_class_providers.dart';
import '../../../attendance/presentation/screens/attendance_input_screen.dart';

class ClassDetailScreen extends ConsumerWidget {
  const ClassDetailScreen({
    super.key,
    required this.taId,
    required this.subjectName,
    required this.className,
  });

  final int taId;
  final String subjectName;
  final String className;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teacherMeetingsProvider(taId));

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
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
            ),
            Text(
              className,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.slate500,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate900,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.slate200,
      ),
      body: state.when(
        data: (cm) => _MeetingsBody(classMeetings: cm),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary600),
        ),
        error: (err, _) => ErrorState(
          message: err is Failure ? err.message : 'Gagal memuat pertemuan',
          onRetry: () => ref.refresh(teacherMeetingsProvider(taId)),
        ),
      ),
    );
  }
}

class _MeetingsBody extends StatelessWidget {
  const _MeetingsBody({required this.classMeetings});
  final ClassMeetings classMeetings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cm = classMeetings;

    return CustomScrollView(
      slivers: [
        // Header card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: FlozCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary50,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMD),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: AppColors.primary600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cm.subjectName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppColors.slate900,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              cm.className,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _HeaderChip(
                        icon: Icons.event_note_rounded,
                        label: '${cm.meetings.length} pertemuan',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Meetings list
        if (cm.meetings.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text(
                'Belum ada pertemuan',
                style: TextStyle(color: AppColors.slate500),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList.separated(
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemCount: cm.meetings.length,
              itemBuilder: (context, i) {
                final m = cm.meetings[i];
                return StaggeredEntry(
                  index: i,
                  child: _MeetingTile(
                    meeting: m,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AttendanceInputScreen(meetingId: m.id),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _MeetingTile extends StatelessWidget {
  const _MeetingTile({required this.meeting, this.onTap});
  final MeetingSummary meeting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = meeting;
    final locked = m.isLocked;

    return FlozCard(
      padding: const EdgeInsets.all(14),
      borderColor: locked ? AppColors.slate200 : null,
      onTap: locked ? null : onTap,
      child: Opacity(
        opacity: locked ? 0.65 : 1.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Meeting number circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: locked ? AppColors.slate200 : AppColors.primary500,
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '${m.meetingNumber}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: locked ? AppColors.slate500 : Colors.white,
                    ),
                  ),
                  if (locked)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: AppColors.slate400,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          size: 9,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: locked ? AppColors.slate500 : AppColors.slate900,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (m.description != null && m.description!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      m.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.slate400,
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Counts
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _CountIcon(
                  icon: Icons.attach_file_rounded,
                  count: m.materialCount,
                  color: locked ? AppColors.slate400 : AppColors.primary500,
                ),
                const SizedBox(height: 4),
                _CountIcon(
                  icon: Icons.assignment_outlined,
                  count: m.assignmentCount,
                  color: locked ? AppColors.slate400 : AppColors.info500,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CountIcon extends StatelessWidget {
  const _CountIcon({
    required this.icon,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary600),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary700,
            ),
          ),
        ],
      ),
    );
  }
}
