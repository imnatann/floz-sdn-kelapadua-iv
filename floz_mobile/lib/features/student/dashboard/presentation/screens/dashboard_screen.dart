import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../domain/entities/dashboard.dart';
import '../../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Beranda')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardNotifierProvider.notifier).refresh(),
        child: state.when(
          data: (dashboard) => _DashboardContent(dashboard: dashboard),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ErrorState(
            message: err is Failure ? err.message : 'Gagal memuat dashboard',
            onRetry: () => ref.read(dashboardNotifierProvider.notifier).refresh(),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final StudentDashboard dashboard;
  const _DashboardContent({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ProfileCard(profile: dashboard.student),
        const SizedBox(height: 16),
        _AttendanceCard(percentage: dashboard.stats.attendancePercentage),
        const SizedBox(height: 16),
        const _SectionHeader(title: 'Jadwal Hari Ini'),
        const SizedBox(height: 8),
        if (dashboard.todaysSchedules.isEmpty)
          const _EmptyTile(message: 'Tidak ada jadwal hari ini.')
        else
          ...dashboard.todaysSchedules.map((s) => _ScheduleTile(item: s)),
        const SizedBox(height: 24),
        const _SectionHeader(title: 'Pengumuman Terbaru'),
        const SizedBox(height: 8),
        if (dashboard.recentAnnouncements.isEmpty)
          const _EmptyTile(message: 'Belum ada pengumuman.')
        else
          ...dashboard.recentAnnouncements.map((a) => _AnnouncementTile(item: a)),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final StudentDashboardProfile? profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Profil siswa belum tersedia.'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, ${profile!.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text('Kelas: ${profile!.className ?? '-'}'),
            if (profile!.homeroomTeacher != null)
              Text('Wali Kelas: ${profile!.homeroomTeacher}'),
          ],
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final int percentage;
  const _AttendanceCard({required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kehadiran'),
                  Text(
                    '$percentage%',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _EmptyTile extends StatelessWidget {
  final String message;
  const _EmptyTile({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message, style: const TextStyle(color: Colors.grey)),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final ScheduleItem item;
  const _ScheduleTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.schedule),
      title: Text(item.subject),
      subtitle: Text('${item.startTime} – ${item.endTime} • ${item.teacher}'),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final AnnouncementSummary item;
  const _AnnouncementTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.campaign_outlined),
      title: Text(item.title),
      subtitle: Text(
        '${dateFmt.format(item.createdAt.toLocal())}\n${item.content}',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
    );
  }
}
