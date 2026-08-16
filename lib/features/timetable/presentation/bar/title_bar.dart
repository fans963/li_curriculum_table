import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:icon_button_m3e/icon_button_m3e.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
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
    final isCupertino = AdaptiveStyle.isCupertino(
      sl<SettingsController>().designStyle.value,
    );

    return CupertinoTheme(
      data: CupertinoTheme.of(context),
      child: Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (_) async {
            if (!isDesktop) return;
            await windowManager.startDragging();
          },
          child: isCupertino
              ? _buildCupertino(context)
              : _buildMaterial(context),
        ),
      ),
    );
  }

  Widget _buildCupertino(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator
                .resolveFrom(context)
                .withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
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
                    color: const Color(0xFFFF5F56), // Red
                    onPressed: () async {
                      await windowManager.close();
                    },
                  ),
                  _buildMacButton(
                    color: const Color(0xFFFFBD2E), // Yellow
                    onPressed: () async {
                      await windowManager.minimize();
                    },
                  ),
                  _buildMacButton(
                    color: const Color(0xFF27C93F), // Green
                    onPressed: () async {
                      _isMaximized.value
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
                  TextSpan(
                    text: '🍐',
                    style: TextStyle(
                      fontSize: 20,
                      color: CupertinoColors.activeOrange.resolveFrom(context),
                      fontFamily: 'NotoColorEmoji',
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 6)),
                  TextSpan(
                    text: '课表',
                    style: TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.label.resolveFrom(context),
                      fontWeight: FontWeight.bold,
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
                    fontSize: 25,
                    color: colorScheme.primary,
                    fontFamily: 'NotoColorEmoji',
                  ),
                ),
                TextSpan(
                  text: '课表',
                  style: TextStyle(
                    fontSize: 24,
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (isDesktop) ...[
            IconButtonM3E(
              onPressed: () async {
                await windowManager.minimize();
              },
              icon: const Icon(Icons.minimize),
              tooltip: '最小化',
              size: IconButtonM3ESize.xs,
              variant: IconButtonM3EVariant.standard,
            ),
            IconButtonM3E(
              onPressed: () async {
                _isMaximized.value
                    ? await windowManager.unmaximize()
                    : await windowManager.maximize();
              },
              icon: Icon(
                _isMaximized.value ? Icons.fullscreen_exit : Icons.fullscreen,
              ),
              tooltip: _isMaximized.value ? '还原' : '最大化',
              size: IconButtonM3ESize.xs,
              variant: IconButtonM3EVariant.standard,
            ),
            IconButtonM3E(
              icon: const Icon(Icons.close),
              onPressed: () async {
                await windowManager.close();
              },
              tooltip: '关闭',
              size: IconButtonM3ESize.xs,
              variant: IconButtonM3EVariant.standard,
            ),
          ],
        ],
      ),
    );
  }
}
