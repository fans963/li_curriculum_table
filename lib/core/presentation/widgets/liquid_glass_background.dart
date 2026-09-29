import 'package:flutter/cupertino.dart';

/// A theme-aware background for showcase pages.
class LiquidGlassBackground extends StatelessWidget {
  const LiquidGlassBackground({super.key, required this.isDark});

  final bool isDark;

  static const darkBaseColor = Color(0xFF020715);
  static const lightBaseColor = Color(0xFFF5F0FA);

  @override
  Widget build(BuildContext context) {
    return isDark
        ? const _DarkLiquidGlassBackground()
        : const _LightLiquidGlassBackground();
  }
}

class _DarkLiquidGlassBackground extends StatelessWidget {
  const _DarkLiquidGlassBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LiquidGlassBackground.darkBaseColor,
      child: Stack(
        children: [
          // Purple glow — upper right (9B59FF / A246F7)
          Positioned(
            top: -50,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFA246F7).withValues(alpha: 0.32),
                    const Color(0xFF9B59FF).withValues(alpha: 0.1),
                    const Color(0x00000000),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Hot pink glow — center left (E040FB / EB66FF)
          Positioned(
            top: 280,
            left: -100,
            child: Container(
              width: 460,
              height: 460,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFEB66FF).withValues(alpha: 0.16),
                    const Color(0xFFE040FB).withValues(alpha: 0.05),
                    const Color(0x00000000),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Blue glow — bottom right (2077FF / 4FC3F7)
          Positioned(
            bottom: -60,
            right: -40,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2077FF).withValues(alpha: 0.18),
                    const Color(0xFF4FC3F7).withValues(alpha: 0.06),
                    const Color(0x00000000),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          // Subtle purple accent — mid-left
          Positioned(
            top: 120,
            left: 30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF9B59FF).withValues(alpha: 0.10),
                    const Color(0x00000000),
                  ],
                ),
              ),
            ),
          ),
          // Purple wash — center screen (behind catalog cards)
          Positioned(
            top: 500,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF9B59FF).withValues(alpha: 0.14),
                      const Color(0xFF7B3FA8).withValues(alpha: 0.05),
                      const Color(0x00000000),
                    ],
                    stops: const [0.0, 0.5, 1.0],
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

class _LightLiquidGlassBackground extends StatelessWidget {
  const _LightLiquidGlassBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            LiquidGlassBackground.lightBaseColor,
            Color(0xFFF0F4F8), // Soft blue-grey
            Color(0xFFEEEEF2), // Light grey
          ],
        ),
      ),
      child: Stack(
        children: [
          // Muted purple glow — upper right
          Positioned(
            top: -50,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFA246F7).withValues(alpha: 0.15),
                    const Color(0xFF9B59FF).withValues(alpha: 0.06),
                    const Color(0x00000000),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Soft pink glow — center left
          Positioned(
            top: 280,
            left: -100,
            child: Container(
              width: 460,
              height: 460,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFEB66FF).withValues(alpha: 0.12),
                    const Color(0xFFE040FB).withValues(alpha: 0.05),
                    const Color(0x00000000),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Blue accent — bottom right
          Positioned(
            bottom: -60,
            right: -40,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2077FF).withValues(alpha: 0.12),
                    const Color(0xFF4FC3F7).withValues(alpha: 0.05),
                    const Color(0x00000000),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
