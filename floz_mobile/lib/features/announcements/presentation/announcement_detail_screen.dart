import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/floz_card.dart';
import '../providers/announcement_providers.dart';

class AnnouncementDetailScreen extends ConsumerWidget {
  final int id;

  const AnnouncementDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(announcementDetailProvider(id));

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text('Detail Pengumuman'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.neutral800),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.neutral800,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(announcementDetailProvider(id).future),
        child: detailAsync.when(
          data: (announcement) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FlozCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                announcement.type.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary700,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat(
                                'dd MMM yyyy, HH:mm',
                              ).format(announcement.createdAt),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.neutral400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          announcement.title,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutral900,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.neutral200),
                        const SizedBox(height: 16),
                        Text(
                          announcement.content,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColors.neutral700,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (announcement.attachmentUrl != null) ...[
                    const SizedBox(height: 16),
                    FlozCard(
                      padding: EdgeInsets.zero,
                      onTap: () =>
                          _openAttachment(context, announcement.attachmentUrl!),
                      child: ListTile(
                        leading: const HeroIcon(
                          HeroIcons.documentArrowDown,
                          color: AppColors.info600,
                        ),
                        title: Text(
                          'Unduh Lampiran',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: AppColors.info700,
                          ),
                        ),
                        trailing: const HeroIcon(
                          HeroIcons.arrowTopRightOnSquare,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Future<void> _openAttachment(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka lampiran')),
        );
      }
    }
  }
}
