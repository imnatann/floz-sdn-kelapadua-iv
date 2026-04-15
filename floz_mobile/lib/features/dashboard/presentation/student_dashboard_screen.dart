import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_providers.dart';
import '../domain/dashboard_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/floz_card.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final tenant = ref.watch(authProvider).tenant;
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardProvider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App Bar with Tenant Logo and Profile
            SliverAppBar(
              backgroundColor: Colors.white,
              floating: true,
              pinned: true,
              elevation: 0,
              title: Row(
                children: [
                  if (tenant?['logo_url'] != null)
                    CircleAvatar(
                      backgroundImage: NetworkImage(tenant!['logo_url']),
                      radius: 16,
                    )
                  else
                    const CircleAvatar(
                      backgroundColor: AppColors.primary100,
                      radius: 16,
                      child: HeroIcon(
                        HeroIcons.academicCap,
                        style: HeroIconStyle.solid,
                        color: AppColors.primary600,
                        size: 20,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tenant?['name'] ?? 'Sekolah',
                      style: GoogleFonts.inter(
                        textStyle: const TextStyle(
                          color: AppColors.neutral900,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () {}, // TODO: Notifications
                  icon: const HeroIcon(
                    HeroIcons.bell,
                    style: HeroIconStyle.outline,
                    color: AppColors.neutral600,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Welcome Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${user?.name ?? "Siswa"}!',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Selamat datang kembali.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            dashboardAsync.when(
              data: (data) => _buildDashboardContent(context, data),
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const HeroIcon(
                        HeroIcons.exclamationCircle,
                        size: 48,
                        color: AppColors.danger500,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Gagal memuat data',
                        style: AppTypography.titleLarge,
                      ),
                      TextButton(
                        onPressed: () => ref.refresh(dashboardProvider),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    StudentDashboardData data,
  ) {
    return SliverMainAxisGroup(
      slivers: [
        // Stats / Quick Actions Grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.15,
            children: [
              _buildStatCard(
                title: 'Jadwal',
                value: data.todaysSchedules.length.toString(),
                subtitle: 'Hari Ini',
                icon: HeroIcons.calendar,
                color: Colors.orange,
                backgroundColor: Colors.orange.shade50,
              ),
              _buildStatCard(
                title: 'Kehadiran',
                value: '${data.stats.attendancePercentage}%',
                subtitle: 'Smt Ini',
                icon: HeroIcons.checkCircle,
                color: Colors.green,
                backgroundColor: Colors.green.shade50,
              ),
              _buildStatCard(
                title: 'Tugas',
                value: '-', // TODO: Add tugas count to API
                subtitle: 'Mendatang',
                icon: HeroIcons.documentText,
                color: AppColors.primary600,
                backgroundColor: AppColors.primary50,
              ),
              _buildStatCard(
                title: 'Nilai',
                value: '-', // TODO: Add GPA to API
                subtitle: 'Rata-rata',
                icon: HeroIcons.chartBar,
                color: Colors.purple,
                backgroundColor: Colors.purple.shade50,
              ),
            ],
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Announcements Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pengumuman Terbaru',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral800,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/dashboard/announcements'),
                  child: Text(
                    'Lihat Semua',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Announcements List
        if (data.recentAnnouncements.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'Belum ada pengumuman',
                  style: TextStyle(color: AppColors.neutral400),
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final announcement = data.recentAnnouncements[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: FlozCard(
                  onTap: () => context.push(
                    '/dashboard/announcements/${announcement.id}',
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const HeroIcon(
                        HeroIcons.megaphone,
                        color: AppColors.primary600,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      announcement.title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          announcement.content,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.neutral500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(announcement.createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.neutral400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }, childCount: data.recentAnnouncements.length),
          ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required HeroIcons icon,
    required Color color,
    required Color backgroundColor,
  }) {
    return FlozCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: HeroIcon(icon, color: color, size: 20),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                  child: Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutral900,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.neutral500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Simple format for now
    return '${date.day}/${date.month}/${date.year}';
  }
}
