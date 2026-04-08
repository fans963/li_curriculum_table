import 'package:curriculum_table/util/util.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class TitleBar extends StatelessWidget {
  const TitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) async {
        if (!isDesktop) return;
        await windowManager.startDragging();
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: colorScheme.surface,
        child: Row(
          children: [
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: '🍐',
                    style: TextStyle(
                      fontSize: 25,
                      color: Colors.lightGreenAccent,
                      fontFamily: 'NotoColorEmoji', 
                    ),
                  ),
                  TextSpan(
                    text: '课表',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.black87, 
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () async {
                if (!isDesktop) return;
                await windowManager.minimize();
              },
              icon: const Icon(Icons.minimize),
              tooltip: '最小化',
            ),
            IconButton(
              onPressed: () async {
                if (!isDesktop) return;
                if (await windowManager.isMaximized()) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
              icon: Icon(Icons.fullscreen),
              tooltip: '最大化',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async {
                if (!isDesktop) return;
                await windowManager.close();
              },
              tooltip: '关闭',
            ),
          ],
        ),
      ),
    );
  }
}
