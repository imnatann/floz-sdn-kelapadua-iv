import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../../../../shared/widgets/floz_card.dart';
import '../../../../../shared/widgets/floz_stat_card.dart';
import '../../../../../shared/widgets/staggered_entry.dart';
import '../../domain/entities/dashboard.dart';
import '../../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary600,
          backgroundColor: Colors.white,
          strokeWidth: 2.5,
          displacement: 32,
          onRefresh: () =>
              ref.read(dashboardNotifierProvider.notifier).refresh(),
          child: state.when(
            data: (dashboard) => _DashboardContent(dashboard: dashboard),
            loading: () => const _LoadingView(),
            error: (err, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                ErrorState(
                  message:
                      err is Failure ? err.message : 'Gagal memuat dashboard',
                  onRetry: () =>
                      ref.read(dashboardNotifierProvider.notifier).refresh(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Content ─────────────────────────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.dashboard});
  final StudentDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final items = <_DashboardItem>[
      _DashboardItem(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _HeaderGreeting(profile: dashboard.student),
        ),
      ),
      _DashboardItem(
        FlozStatCard(
          icon: Icons.check_circle_outline_rounded,
          label: 'Kehadiran semester ini',
          value: '${dashboard.stats.attendancePercentage}%',
          accent: _attendanceColor(dashboard.stats.attendancePercentage),
        ),
      ),
      _DashboardItem(
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _SectionHeader(
            title: 'Jadwal Hari Ini',
            count: dashboard.todaysSchedules.length,
          ),
        ),
        spacingBefore: true,
      ),
      if (dashboard.todaysSchedules.isEmpty)
        _DashboardItem(
          const _EmptyBanner(
            icon: Icons.event_busy_outlined,
            message: 'Tidak ada jadwal hari ini.',
          ),
        )
      else
        ...dashboard.todaysSchedules
            .map((s) => _DashboardItem(_ScheduleTile(item: s))),
      _DashboardItem(
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _SectionHeader(
            title: 'Pengumuman Terbaru',
            count: dashboard.recentAnnouncements.length,
          ),
        ),
        spacingBefore: true,
      ),
      if (dashboard.recentAnnouncements.isEmpty)
        _DashboardItem(
          const _EmptyBanner(
            icon: Icons.campaign_outlined,
            message: 'Belum ada pengumuman.',
          ),
        )
      else
        ...dashboard.recentAnnouncements
            .map((a) => _DashboardItem(_AnnouncementTile(item: a))),
    ];

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: items.length,
      itemBuilder: (_, i) =>
          StaggeredEntry(index: i, child: items[i].widget),
      separatorBuilder: (_, i) =>
          SizedBox(height: items[i + 1].spacingBefore ? 8 : 10),
    );
  }

  Color _attendanceColor(int pct) {
    if (pct >= 85) return AppColors.success500;
    if (pct >= 70) return AppColors.warning500;
    return AppColors.danger500;
  }
}

class _DashboardItem {
  final Widget widget;
  final bool spacingBefore;
  _DashboardItem(this.widget, {this.spacingBefore = false});
}

// ── Greeting header ─────────────────────────────────────────────────────

class _HeaderGreeting extends StatelessWidget {
  const _HeaderGreeting({required this.profile});
  final StudentDashboardProfile? profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = _timeBasedGreeting();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary600, AppColors.primary500],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary600.withValues(alpha: 0.22),
            offset: const Offset(0, 8),
            blurRadius: 18,
            spreadRadius: -6,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _ProfileButton(initials: _initialsOf(profile?.name ?? 'Siswa')),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                profile?.name ?? 'Siswa',
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.15,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (profile?.className != null)
                    _HeaderChip(
                      icon: Icons.school_outlined,
                      label: 'Kelas ${profile!.className}',
                    ),
                  if (profile?.homeroomTeacher != null)
                    _HeaderChip(
                      icon: Icons.person_outline_rounded,
                      label: profile!.homeroomTeacher!,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'SELAMAT PAGI';
    if (hour < 15) return 'SELAMAT SIANG';
    if (hour < 18) return 'SELAMAT SORE';
    return 'SELAMAT MALAM';
  }

  String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => context.push('/profile'),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.32), width: 1.2),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.slate900,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Schedule tile ───────────────────────────────────────────────────────

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.item});
  final ScheduleItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FlozCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary500,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatTime(item.startTime),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.slate900,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _formatTime(item.endTime),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.slate400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.subject,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.slate900,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.teacher,
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

  String _formatTime(String raw) {
    if (raw.length >= 5) return raw.substring(0, 5);
    return raw;
  }
}

// ── Announcement tile ───────────────────────────────────────────────────

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.item});
  final AnnouncementSummary item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('d MMM');
    return FlozCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: AppColors.primary600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.slate900,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateFmt.format(item.createdAt.toLocal()),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.slate400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.content,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.slate600,
                    height: 1.45,
                  ),
                  maxLines: 2,
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

// ── Empty + loading ─────────────────────────────────────────────────────

class _EmptyBanner extends StatelessWidget {
  const _EmptyBanner({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return FlozCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.slate400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.slate500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: const [
        _ShimmerBlock(height: 132, radius: AppSpacing.radiusLG),
        SizedBox(height: 12),
        _ShimmerBlock(height: 76, radius: AppSpacing.radiusLG),
        SizedBox(height: 24),
        _ShimmerBlock(height: 18, radius: 6, width: 120),
        SizedBox(height: 12),
        _ShimmerBlock(height: 70, radius: AppSpacing.radiusLG),
        SizedBox(height: 10),
        _ShimmerBlock(height: 70, radius: AppSpacing.radiusLG),
        SizedBox(height: 10),
        _ShimmerBlock(height: 70, radius: AppSpacing.radiusLG),
      ],
    );
  }
}

class _ShimmerBlock extends StatefulWidget {
  const _ShimmerBlock({
    required this.height,
    required this.radius,
    this.width,
  });
  final double height;
  final double radius;
  final double? width;

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(AppColors.slate100, AppColors.slate200, t),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}
