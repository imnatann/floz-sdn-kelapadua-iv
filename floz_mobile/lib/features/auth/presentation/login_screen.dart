import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/error/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/floz_card.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await ref.read(loginControllerProvider.notifier).submit(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
    if (!mounted) return;
    if (ok) {
      final session = ref.read(authSessionProvider);
      if (session.role == 'teacher') {
        context.go('/teacher');
      } else {
        context.go('/student');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final theme = Theme.of(context);

    ref.listen(loginControllerProvider, (prev, next) {
      if (next is AsyncError) {
        final failure = next.error;
        final message = failure is Failure ? failure.message : 'Login gagal';
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.slate900,
            ),
          );
      }
    });

    final isLoading = state is AsyncLoading;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: Stack(
        children: [
          // Decorative gradient hero at the top
          const _HeroBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.vertical,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _BrandHeader(),
                      const SizedBox(height: 32),
                      _TweenFadeIn(
                        child: FlozCard(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Masuk ke akun Anda',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: AppColors.slate900,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Gunakan email sekolah untuk melanjutkan.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.slate500,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _FieldLabel('Email'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  key: const Key('login.email'),
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  decoration: const InputDecoration(
                                    hintText: 'nama@sekolah.id',
                                    prefixIcon: Icon(
                                      Icons.alternate_email_rounded,
                                      size: 20,
                                      color: AppColors.slate400,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Email wajib diisi';
                                    if (!v.contains('@')) return 'Format email tidak valid';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                _FieldLabel('Password'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  key: const Key('login.password'),
                                  controller: _passwordCtrl,
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    hintText: 'Minimal 6 karakter',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 20,
                                      color: AppColors.slate400,
                                    ),
                                    suffixIcon: IconButton(
                                      splashRadius: 20,
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        size: 20,
                                        color: AppColors.slate500,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Password wajib diisi';
                                    if (v.length < 6) return 'Password minimal 6 karakter';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    key: const Key('login.submit'),
                                    onPressed: isLoading ? null : _submit,
                                    child: AnimatedSwitcher(
                                      duration: AppMotion.fast,
                                      child: isLoading
                                          ? const SizedBox(
                                              key: ValueKey('loading'),
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Masuk',
                                              key: ValueKey('label'),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _FooterNote(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Private sub-widgets ────────────────────────────────────────────────

class _HeroBackground extends StatelessWidget {
  const _HeroBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 260,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary600,
              AppColors.primary500,
              AppColors.warning500,
            ],
            stops: [0.0, 0.55, 1.0],
          ),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(32),
          ),
        ),
        child: Stack(
          children: [
            // Soft top-right bloom
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                offset: Offset(0, 8),
                blurRadius: 24,
                spreadRadius: -6,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'F',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: AppColors.primary600,
                height: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'FLOZ',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 2,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'SDN Kelapa Dua IV',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.85),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.slate700,
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Hubungi wali kelas jika lupa kata sandi',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.slate500,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Small entry animation for the login card — fade + slide from 8px below.
class _TweenFadeIn extends StatefulWidget {
  const _TweenFadeIn({required this.child});
  final Widget child;

  @override
  State<_TweenFadeIn> createState() => _TweenFadeInState();
}

class _TweenFadeInState extends State<_TweenFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = CurvedAnimation(parent: _controller, curve: AppMotion.easeOut);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.easeOut));

    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(position: slide, child: widget.child),
    );
  }
}
