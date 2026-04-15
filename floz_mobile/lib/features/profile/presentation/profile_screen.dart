import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/floz_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    // Helper to get role badge color
    Color getRoleColor(String? role) {
      if (role == 'student') return AppColors.primary600;
      if (role == 'teacher') return AppColors.success600;
      return AppColors.warning600;
    }

    // Helper to get role label
    String getRoleLabel(String? role) {
      if (role == 'student') return 'Siswa';
      if (role == 'teacher') return 'Guru';
      if (role == 'parent') return 'Wali Murid';
      return role?.toUpperCase() ?? '-';
    }

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: Text(
          'Profil Saya',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral900,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Spectacular Profile Header with Cover Photo
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Cover Photo Area
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.primary600,
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?q=80&w=1000&auto=format&fit=crop',
                      ), // Placeholder vibrant background
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Gradient Overlay for readability
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
                // Overlapping Avatar
                Positioned(
                  bottom: -50,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: user?.avatarUrl != null
                          ? NetworkImage(user!.avatarUrl!)
                          : null,
                      child: user?.avatarUrl == null
                          ? const HeroIcon(
                              HeroIcons.user,
                              size: 50,
                              color: AppColors.neutral400,
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),

            // Spacer to accommodate overlapping avatar
            const SizedBox(height: 60),

            // Profile Basic Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Text(
                    user?.name ?? '-',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutral900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '-',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.neutral500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: getRoleColor(user?.role).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: getRoleColor(user?.role).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      getRoleLabel(user?.role),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: getRoleColor(user?.role),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Detailed Personal Information Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'Informasi Pribadi',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral800,
                      ),
                    ),
                  ),
                  FlozCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        if (user?.isStudent == true &&
                            user?.studentData != null) ...[
                          _buildDetailRow(
                            HeroIcons.identification,
                            'NISN',
                            user!.studentData!['nisn']?.toString() ?? '-',
                          ),
                          const Divider(height: 1, color: AppColors.neutral200),
                          _buildDetailRow(
                            HeroIcons.userGroup,
                            'Kelas',
                            user.studentData!['class']?['name'] ?? '-',
                          ),
                          const Divider(height: 1, color: AppColors.neutral200),
                          _buildDetailRow(
                            HeroIcons.user,
                            'Jenis Kelamin',
                            user.studentData!['gender'] == 'L'
                                ? 'Laki-laki'
                                : (user.studentData!['gender'] == 'P'
                                      ? 'Perempuan'
                                      : '-'),
                          ),
                          const Divider(height: 1, color: AppColors.neutral200),
                          _buildDetailRow(
                            HeroIcons.phone,
                            'No. Telepon P',
                            user.studentData!['parent_phone']?.toString() ??
                                '-',
                          ),
                        ],

                        if (user?.isTeacher == true &&
                            user?.teacherData != null) ...[
                          _buildDetailRow(
                            HeroIcons.identification,
                            'NIP',
                            user!.teacherData!['nip']?.toString() ?? '-',
                          ),
                          const Divider(height: 1, color: AppColors.neutral200),
                          _buildDetailRow(
                            HeroIcons.phone,
                            'No. Telepon',
                            user.teacherData!['phone']?.toString() ?? '-',
                          ),
                          const Divider(height: 1, color: AppColors.neutral200),
                          _buildDetailRow(
                            HeroIcons.user,
                            'Jenis Kelamin',
                            user.teacherData!['gender'] == 'L'
                                ? 'Laki-laki'
                                : (user.teacherData!['gender'] == 'P'
                                      ? 'Perempuan'
                                      : '-'),
                          ),
                        ],

                        // Fallback generic info if neither is fully populated or if they are a parent
                        if ((!user!.isStudent && !user.isTeacher) ||
                            (user.isStudent && user.studentData == null) ||
                            (user.isTeacher && user.teacherData == null)) ...[
                          _buildDetailRow(
                            HeroIcons.envelope,
                            'Email',
                            user.email,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Menu Items Section
                  if (user.isStudent) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'Akademik',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.neutral800,
                        ),
                      ),
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: HeroIcons.academicCap,
                      title: 'Rapor Akademik',
                      subtitle: 'Lihat rapor semester dan evaluasi belajar',
                      onTap: () => context.push('/profile/report-cards'),
                      iconColor: AppColors.primary600,
                      iconBgColor: AppColors.primary50,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref.read(authProvider.notifier).logout();
                      },
                      icon: const HeroIcon(
                        HeroIcons.arrowRightOnRectangle,
                        size: 20,
                      ),
                      label: const Text(
                        'Keluar dari Akun',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger600,
                        backgroundColor: Colors.white,
                        side: const BorderSide(
                          color: AppColors.danger50,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(HeroIcons icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: HeroIcon(icon, size: 20, color: AppColors.neutral500),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.neutral500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.neutral900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required HeroIcons icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return FlozCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: HeroIcon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.neutral800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.neutral500),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const HeroIcon(
            HeroIcons.chevronRight,
            size: 16,
            color: AppColors.neutral400,
          ),
        ),
      ),
    );
  }
}
