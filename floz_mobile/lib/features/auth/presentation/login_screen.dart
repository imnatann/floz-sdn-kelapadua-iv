import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/floz_button.dart';
import '../../../shared/widgets/floz_input.dart';
import '../../../shared/widgets/hero_logos_background.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref
          .read(authProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);
      // Router will handle redirect to dashboard
    } catch (e) {
      // Error is handled in provider state, but we can show a snackbar too if needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.danger600,
          ),
        );
      }
    }
  }

  void _changeSchool() {
    ref.read(authProvider.notifier).clearTenant();
    context.go('/tenant-search');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final tenant = state.tenant;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const Positioned.fill(child: HeroLogosBackground()),
          // Slight white overlay to ensure the form remains readable over moving logos
          Positioned.fill(
            child: Container(color: Colors.white.withValues(alpha: 0.85)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo / School Info
                      Center(
                        child: Column(
                          children: [
                            Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                color: AppColors.slate100,
                                shape: BoxShape.circle,
                              ),
                              child: tenant?['logo_url'] != null
                                  ? ClipOval(
                                      child: Image.network(tenant!['logo_url']),
                                    )
                                  : const Icon(
                                      Icons.school,
                                      size: 40,
                                      color: AppColors.slate500,
                                    ),
                            ),
                            const SizedBox(height: AppSpacing.space16),
                            Text(
                              tenant?['name'] ?? 'School Login',
                              style: AppTypography.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.space4),
                            Text(
                              'Sign in to your account',
                              style: AppTypography.bodyMedium,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.space32),

                      // Error Alert
                      if (state.error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(
                            bottom: AppSpacing.space16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger50,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMD,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.danger600,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  state.error!.replaceAll('Exception: ', ''),
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.danger700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Inputs
                      FlozInput(
                        label: 'Email Address',
                        hint: 'Enter your email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.space16),
                      FlozInput(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: _passwordController,
                        obscureText: true,
                        prefixIcon: Icons.lock_outline,
                        validator: (v) =>
                            v!.isEmpty ? 'Please enter your password' : null,
                      ),

                      const SizedBox(height: AppSpacing.space8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {}, // TODO: Forgot Password
                          child: Text(
                            'Forgot Password?',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.primary600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.space24),

                      FlozButton(
                        text: 'Sign In',
                        onPressed: _login,
                        isLoading: state.isLoading,
                        icon: Icons.login,
                      ),

                      const SizedBox(height: AppSpacing.space24),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Not ${tenant?['name'] ?? 'this school'}?',
                              style: AppTypography.labelSmall,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space16),

                      FlozButton(
                        text: 'Find Another School',
                        type: FlozButtonType.secondary,
                        onPressed: _changeSchool,
                      ),
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
