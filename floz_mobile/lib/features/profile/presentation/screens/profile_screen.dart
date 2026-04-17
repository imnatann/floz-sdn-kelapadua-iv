import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/floz_card.dart';
import '../../../auth/domain/entities/user.dart';
import '../../providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final user = session.user;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.slate900,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.slate900),
      ),
      body: user == null
          ? const Center(child: Text('Sesi tidak ditemukan.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _ProfileHeader(user: user),
                const SizedBox(height: 20),
                _SectionLabel('Informasi'),
                const SizedBox(height: 8),
                _InfoCard(user: user),
                const SizedBox(height: 20),
                _SectionLabel('Akun'),
                const SizedBox(height: 8),
                const _LogoutButton(),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'FLOZ • SDN Kelapa Dua IV',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.slate400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    return FlozCard(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Avatar(name: user.name, avatarUrl: user.avatarUrl),
          const SizedBox(height: 14),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.slate500,
            ),
          ),
          const SizedBox(height: 12),
          _RoleBadge(role: user.role),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.avatarUrl});
  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary50,
        border: Border.all(color: AppColors.primary100, width: 2),
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _InitialsAvatar(initials: initials),
              )
            : _InitialsAvatar(initials: initials),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: AppColors.primary600,
          height: 1,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (role) {
      'student' => ('Siswa', AppColors.primary600, AppColors.primary50),
      'teacher' => ('Guru', AppColors.success600, AppColors.success50),
      'school_admin' => ('Admin Sekolah', AppColors.warning600, AppColors.warning50),
      _ => (role.toUpperCase(), AppColors.slate600, AppColors.slate100),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Info card ───────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _InfoRow(
        icon: Icons.alternate_email_rounded,
        label: 'Email',
        value: user.email,
      ),
    ];

    if (user.isStudent && user.student != null) {
      final s = user.student!;
      rows.addAll([
        const _Divider(),
        _InfoRow(icon: Icons.badge_outlined, label: 'NIS', value: s.nis),
        const _Divider(),
        _InfoRow(icon: Icons.fingerprint_rounded, label: 'NISN', value: s.nisn),
        if (s.schoolClass != null) ...[
          const _Divider(),
          _InfoRow(
            icon: Icons.school_outlined,
            label: 'Kelas',
            value: s.schoolClass!.name,
          ),
          if (s.schoolClass!.homeroomTeacher != null) ...[
            const _Divider(),
            _InfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Wali Kelas',
              value: s.schoolClass!.homeroomTeacher!,
            ),
          ],
        ],
      ]);
    }

    if (user.isTeacher && user.teacher != null) {
      final t = user.teacher!;
      if (t.nip != null && t.nip!.isNotEmpty) {
        rows.addAll([
          const _Divider(),
          _InfoRow(icon: Icons.badge_outlined, label: 'NIP', value: t.nip!),
        ]);
      }
    }

    return FlozCard(
      padding: EdgeInsets.zero,
      child: Column(children: rows),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
            ),
            child: Icon(icon, size: 18, color: AppColors.slate600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(height: 1, color: AppColors.slate100),
    );
  }
}

// ── Section label ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.slate900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── Logout button ───────────────────────────────────────────────────────

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(logoutControllerProvider);
    final isLoading = state.isLoading;

    return FlozCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
        onTap: isLoading
            ? null
            : () => _confirmAndLogout(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.danger50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 18,
                  color: AppColors.danger600,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Keluar dari Akun',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger600,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.danger600,
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.slate300,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
        ),
        title: const Text(
          'Keluar dari akun?',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.slate900,
          ),
        ),
        content: const Text(
          'Anda akan dikembalikan ke halaman login.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.slate600,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: AppColors.slate600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Keluar',
              style: TextStyle(
                color: AppColors.danger600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(logoutControllerProvider.notifier).submit();
    // Router reacts to authSession change → redirects to /login automatically.
  }
}
