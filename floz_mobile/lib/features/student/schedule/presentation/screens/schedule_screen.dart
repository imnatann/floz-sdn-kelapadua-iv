import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../../../../shared/widgets/floz_card.dart';
import '../../../../../shared/widgets/staggered_entry.dart';
import '../../domain/entities/weekly_schedule.dart';
import '../../providers/schedule_providers.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scheduleNotifierProvider);
    final todayIso = DateTime.now().weekday;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary600,
          backgroundColor: Colors.white,
          strokeWidth: 2.5,
          onRefresh: () =>
              ref.read(scheduleNotifierProvider.notifier).refresh(),
          child: state.when(
            data: (schedule) => _ScheduleContent(
              schedule: schedule,
              todayDayOfWeek: todayIso,
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary600),
            ),
            error: (err, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                ErrorState(
                  message: err is Failure ? err.message : 'Gagal memuat jadwal',
                  onRetry: () =>
                      ref.read(scheduleNotifierProvider.notifier).refresh(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleContent extends StatelessWidget {
  const _ScheduleContent({
    required this.schedule,
    required this.todayDayOfWeek,
  });

  final WeeklySchedule schedule;
  final int todayDayOfWeek;

  @override
  Widget build(BuildContext context) {
    if (schedule.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 80),
          _EmptyBanner(),
        ],
      );
    }

    final items = <Widget>[];
    for (var i = 0; i < schedule.days.length; i++) {
      final day = schedule.days[i];
      final isToday = day.day == todayDayOfWeek;
      items.add(
        StaggeredEntry(
          index: items.length,
          child: Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 18, bottom: 8),
            child: _DaySectionHeader(day: day, isToday: isToday),
          ),
        ),
      );
      for (final entry in day.items) {
        items.add(
          StaggeredEntry(
            index: items.length,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ScheduleTile(entry: entry, isToday: isToday),
            ),
          ),
        );
      }
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: items,
    );
  }
}

class _DaySectionHeader extends StatelessWidget {
  const _DaySectionHeader({required this.day, required this.isToday});
  final ScheduleDay day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          day.dayName,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isToday ? AppColors.primary700 : AppColors.slate900,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(width: 8),
        if (isToday)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.primary200),
            ),
            child: const Text(
              'Hari ini',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        const Spacer(),
        Text(
          '${day.items.length} pelajaran',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.slate400,
          ),
        ),
      ],
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.entry, required this.isToday});
  final ScheduleEntry entry;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FlozCard(
      padding: const EdgeInsets.all(14),
      borderColor: isToday ? AppColors.primary200 : null,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: isToday ? AppColors.primary600 : AppColors.slate300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.startTime,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.slate900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  entry.endTime,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.slate400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.subject,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.slate900,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  entry.teacher,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.slate500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBanner extends StatelessWidget {
  const _EmptyBanner();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: AppColors.primary50,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
          ),
          child: const Icon(
            Icons.calendar_today_outlined,
            size: 36,
            color: AppColors.primary600,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Belum ada jadwal',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.slate900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Jadwal pelajaran akan muncul di sini\nsetelah guru mengatur jadwal kelas.',
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
