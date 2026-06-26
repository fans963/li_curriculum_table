import 'package:li_curriculum_table/util/util.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:window_manager/window_manager.dart';

class TitleBar extends SignalStatefulWidget {
  const TitleBar({super.key});

  @override
  State<TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends State<TitleBar> with WindowListener {
  final _isMaximized = signal(false);

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkMaximized();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _checkMaximized() async {
    if (!isDesktop) return;
    final maximized = await windowManager.isMaximized();
    if (mounted) _isMaximized.value = maximized;
  }

  @override
  void onWindowMaximize() {
    if (mounted) _isMaximized.value = true;
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) _isMaximized.value = false;
  }

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
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            RichText(
              text: TextSpan(children: [
                TextSpan(text: '🍐', style: TextStyle(fontSize: 25, color: colorScheme.primary, fontFamily: 'NotoColorEmoji')),
                TextSpan(text: '课表', style: TextStyle(fontSize: 24, color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
              ]),
            ),
            const Spacer(),
            IconButton(
              onPressed: () async { if (!isDesktop) return; await windowManager.minimize(); },
              icon: const Icon(Icons.minimize), tooltip: '最小化', iconSize: 18,
              style: IconButton.styleFrom(minimumSize: const Size(32, 32), padding: EdgeInsets.zero),
            ),
            IconButton(
              onPressed: () async {
                if (!isDesktop) return;
                _isMaximized.value ? await windowManager.unmaximize() : await windowManager.maximize();
              },
              icon: Icon(_isMaximized.value ? Icons.fullscreen_exit : Icons.fullscreen),
              tooltip: _isMaximized.value ? '还原' : '最大化',
              iconSize: 18,
              style: IconButton.styleFrom(minimumSize: const Size(32, 32), padding: EdgeInsets.zero),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async { if (!isDesktop) return; await windowManager.close(); },
              tooltip: '关闭', iconSize: 18,
              style: IconButton.styleFrom(minimumSize: const Size(32, 32), padding: EdgeInsets.zero, foregroundColor: colorScheme.error),
            ),
          ],
        ),
      ),
    );
  }
}
