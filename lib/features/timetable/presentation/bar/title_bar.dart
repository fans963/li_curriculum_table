import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/timetable/presentation/bar/liquid_glass_title_bar.dart';
import 'package:li_curriculum_table/features/timetable/presentation/bar/m3e_title_bar.dart';
import 'package:li_curriculum_table/util/util.dart';
import 'package:signals/signals_flutter.dart';
import 'package:window_manager/window_manager.dart';

export 'liquid_glass_title_bar.dart';
export 'm3e_title_bar.dart';

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
    final ds = sl<SettingsController>().designStyle.value;
    final concrete = UiStyleRegistry.resolveConcreteStyle(ds);

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) async {
          if (!isDesktop) return;
          await windowManager.startDragging();
        },
        child: concrete == DesignStyle.cupertino
            ? LiquidGlassTitleBar(isMaximized: _isMaximized.value)
            : M3eTitleBar(isMaximized: _isMaximized.value),
      ),
    );
  }
}
