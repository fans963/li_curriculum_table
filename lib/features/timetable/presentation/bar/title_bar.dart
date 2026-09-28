import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:li_curriculum_table/util/util.dart';
import 'package:material_ui/material_ui.dart';
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
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) async {
          if (!isDesktop) return;
          await windowManager.startDragging();
        },
        child: _buildMaterial(context),
      ),
    );
  }

  Widget _buildMaterial(BuildContext context) {
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
                _isMaximized.value
                    ? await windowManager.unmaximize()
                    : await windowManager.maximize();
              },
              icon: Icon(
                _isMaximized.value ? Icons.fullscreen_exit : Icons.fullscreen,
              ),
              tooltip: _isMaximized.value ? '还原' : '最大化',
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
