import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:window_manager/window_manager.dart';
import 'package:li_curriculum_table/util/util.dart';

/// iOS 26 Liquid Glass styled window title bar with macOS traffic light controls.
class LiquidGlassTitleBar extends StatelessWidget {
  final bool isMaximized;

  const LiquidGlassTitleBar({
    super.key,
    required this.isMaximized,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GlassContainer(
      height: 40,
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: const LiquidRoundedRectangle(borderRadius: 0),
      settings: LiquidGlassSettings(
        glassColor: cs.surface.withValues(alpha: 0.35),
        blur: 10,
        thickness: 20,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isDesktop)
            Positioned(
              left: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMacButton(
                    color: const Color(0xFFFF5F56),
                    onPressed: () async {
                      await windowManager.close();
                    },
                  ),
                  _buildMacButton(
                    color: const Color(0xFFFFBD2E),
                    onPressed: () async {
                      await windowManager.minimize();
                    },
                  ),
                  _buildMacButton(
                    color: const Color(0xFF27C93F),
                    onPressed: () async {
                      isMaximized
                          ? await windowManager.unmaximize()
                          : await windowManager.maximize();
                    },
                  ),
                ],
              ),
            ),
          Center(
            child: RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: '🍐',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'NotoColorEmoji',
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 6)),
                  TextSpan(
                    text: '课表',
                    style: TextStyle(
                      fontSize: 15,
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacButton({
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
