import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:window_manager/window_manager.dart';
import 'package:li_curriculum_table/util/util.dart';

/// Material 3 Expressive styled window title bar.
class M3eTitleBar extends StatelessWidget {
  final bool isMaximized;

  const M3eTitleBar({
    super.key,
    required this.isMaximized,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '🍐',
                  style: TextStyle(
                    fontSize: 18,
                    color: colorScheme.primary,
                    fontFamily: 'NotoColorEmoji',
                  ),
                ),
                TextSpan(
                  text: '课表',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (isDesktop) ...[
            M3EIconButton(
              onPressed: () async {
                await windowManager.minimize();
              },
              icon: const Icon(Icons.minimize),
              tooltip: '最小化',
              size: M3EIconButtonSize.xs,
              variant: M3EIconButtonVariant.standard,
            ),
            M3EIconButton(
              onPressed: () async {
                isMaximized
                    ? await windowManager.unmaximize()
                    : await windowManager.maximize();
              },
              icon: Icon(
                isMaximized ? Icons.fullscreen_exit : Icons.fullscreen,
              ),
              tooltip: isMaximized ? '还原' : '最大化',
              size: M3EIconButtonSize.xs,
              variant: M3EIconButtonVariant.standard,
            ),
            M3EIconButton(
              icon: const Icon(Icons.close),
              onPressed: () async {
                await windowManager.close();
              },
              tooltip: '关闭',
              size: M3EIconButtonSize.xs,
              variant: M3EIconButtonVariant.standard,
            ),
          ],
        ],
      ),
    );
  }
}
