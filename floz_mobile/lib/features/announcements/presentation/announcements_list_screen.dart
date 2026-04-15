import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/floz_card.dart';
import '../providers/announcement_providers.dart';

class AnnouncementsListScreen extends ConsumerWidget {
  const AnnouncementsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: Text(
          'Semua Pengumuman',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral800,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.neutral800),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(announcementsProvider.future),
        child: announcementsAsync.when(
          data: (announcements) {
            if (announcements.isEmpty) {
              return ListView(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const HeroIcon(
                          HeroIcons.megaphone,
                          size: 48,
                          color: AppColors.neutral300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada pengumuman.',
                          style: GoogleFonts.inter(color: AppColors.neutral500),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: announcements.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final announcement = announcements[index];
                return FlozCard(
                  onTap: () => context.push(
                    '/dashboard/announcements/${announcement.id}',
                  ),
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const HeroIcon(
                        HeroIcons.megaphone,
                        color: AppColors.primary600,
                      ),
                    ),
                    title: Text(
                      announcement.title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          announcement.content,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.neutral500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat(
                            'dd MMMM yyyy, HH:mm',
                          ).format(announcement.createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.neutral400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
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
                  'Gagal memuat pengumuman',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => ref.refresh(announcementsProvider),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
