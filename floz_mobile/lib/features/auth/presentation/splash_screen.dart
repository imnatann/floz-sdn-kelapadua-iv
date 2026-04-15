import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Check auth status after build
    // Check auth status after brief delay for splash visibility
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ref.read(authProvider.notifier).checkAuth();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.slate900,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Simple animated logo or just text for now
            Icon(Icons.school, size: 80, color: AppColors.primary500),
            SizedBox(height: 24),
            Text(
              'FLOZ',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(color: AppColors.primary500),
          ],
        ),
      ),
    );
  }
}
