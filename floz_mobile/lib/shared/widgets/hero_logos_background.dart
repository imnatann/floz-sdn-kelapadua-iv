import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HeroLogosBackground extends StatefulWidget {
  const HeroLogosBackground({super.key});

  @override
  State<HeroLogosBackground> createState() => _HeroLogosBackgroundState();
}

class _HeroLogosBackgroundState extends State<HeroLogosBackground>
    with TickerProviderStateMixin {
  late AnimationController _outerController;
  late AnimationController _innerController;

  // Web Logo URLs
  static const _outerLogos = [
    'https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93ed96e30b5810b3a288_justworks.svg',
    'https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93ed890ce4399c491d85_namely.svg',
    'https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93f0d7505dff5e981869_onpay.svg',
    'https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93ed2cf6e7e6e692e7de_paychex.svg',
    'https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93ee8d3dc30bbea1ce6b_paycor.svg',
    'https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93ed0f1fff92b2616dad_patriot.svg',
    'https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93eeca170614ecf86df8_personio.svg',
    'https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93eefac8a5d0d4ca67ea_prismhr.svg',
  ];

  static const _innerLogos = [
    'https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93efbd77caac7452fa04_wave.svg',
    'https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93efd76daf77e359a1f8_workday.svg',
    'https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93ed60c27b531d929adb_alphastaff.svg',
    'https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93eded9819f49766664c_oysterhr%201.svg',
    'https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93ee608a73339de88c5d_sapling.svg',
    'https://cdn.prod.website-files.com/63dd790039a2b29044f7d608/689c93eee1f5d8137f24c958_sequoia%20one.svg',
  ];

  @override
  void initState() {
    super.initState();
    // 80s per rotation (clockwise -> increasing value from 0 to 1)
    _outerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 80),
    )..repeat();

    // 60s per rotation (counter-clockwise -> we will subtract value from 1 or handle logic later)
    // To make it simpler, we just use a forward controller and do `1.0 - innerController.value` inside the builder.
    _innerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _outerController.dispose();
    _innerController.dispose();
    super.dispose();
  }

  Widget _buildLogo(String url, double size) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: SvgPicture.network(
          url,
          fit: BoxFit.contain,
          placeholderBuilder: (context) =>
              const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adjust radii and size based on screen size (like the CSS media query)
        final isMobile = constraints.maxWidth <= 768;
        final double outerRadius = isMobile
            ? 220
            : 400; // Increased to be more spectacular
        final double innerRadius = isMobile ? 130 : 250;
        final double outerLogoSize = isMobile ? 80 : 120; // Increased
        final double innerLogoSize = isMobile ? 64 : 96; // Increased

        return IgnorePointer(
          child: Stack(
            children: [
              // Outer Ring
              AnimatedBuilder(
                animation: _outerController,
                builder: (context, child) {
                  return Stack(
                    children: List.generate(_outerLogos.length, (index) {
                      // Calculate base angle for this item
                      final baseAngle =
                          (index / _outerLogos.length) * 2 * math.pi;
                      // Current rotation angle (clockwise)
                      final currentAngle =
                          baseAngle + (_outerController.value * 2 * math.pi);

                      // Calculate X and Y
                      // Center is context.size / 2
                      final cx = constraints.maxWidth / 2;
                      final cy = constraints.maxHeight / 2;

                      final x =
                          cx +
                          outerRadius * math.cos(currentAngle) -
                          (outerLogoSize / 2);
                      final y =
                          cy +
                          outerRadius * math.sin(currentAngle) -
                          (outerLogoSize / 2);

                      return Positioned(
                        left: x,
                        top: y,
                        child: _buildLogo(_outerLogos[index], outerLogoSize),
                      );
                    }),
                  );
                },
              ),

              // Inner Ring
              AnimatedBuilder(
                animation: _innerController,
                builder: (context, child) {
                  return Stack(
                    children: List.generate(_innerLogos.length, (index) {
                      final baseAngle =
                          (index / _innerLogos.length) * 2 * math.pi;
                      // Current rotation angle (counter-clockwise -> subtract)
                      final currentAngle =
                          baseAngle - (_innerController.value * 2 * math.pi);

                      final cx = constraints.maxWidth / 2;
                      final cy = constraints.maxHeight / 2;

                      final x =
                          cx +
                          innerRadius * math.cos(currentAngle) -
                          (innerLogoSize / 2);
                      final y =
                          cy +
                          innerRadius * math.sin(currentAngle) -
                          (innerLogoSize / 2);

                      return Positioned(
                        left: x,
                        top: y,
                        child: _buildLogo(_innerLogos[index], innerLogoSize),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
