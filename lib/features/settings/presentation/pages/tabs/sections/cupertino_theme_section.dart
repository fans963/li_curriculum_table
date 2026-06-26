part of '../settings_cupertino.dart';

class _ThemeCard extends StatelessWidget {
  final AppSettings settings;
  final SettingsController notifier;

  const _ThemeCard({required this.settings, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return _iosCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iosTile(
            context,
            icon: CupertinoIcons.paintbrush,
            title: '主题模式',
            trailing: Text(themeModeLabel(settings.themeMode), style: TextStyle(fontSize: 15, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
            onTap: () => _showThemeModePicker(context),
          ),
          _iosTile(
            context,
            icon: CupertinoIcons.color_filter,
            title: '动态取色',
            subtitle: '从壁纸或系统提取主题色',
            trailing: IgnorePointer(child: CupertinoSwitch(value: settings.useDynamicColor, onChanged: notifier.setUseDynamicColor)),
          ),
          if (!settings.useDynamicColor) ...[
            _iosTile(
              context,
              icon: CupertinoIcons.circle_fill,
              title: '主题色',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: settings.seedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: CupertinoColors.separator, width: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(CupertinoIcons.chevron_forward, size: 16, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                ],
              ),
              onTap: () => _showColorPicker(context),
            ),
            _iosTile(
              context,
              icon: CupertinoIcons.paintbrush_fill,
              title: '配色方案',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(settings.colorSchemeType.label, style: TextStyle(fontSize: 15, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                  const SizedBox(width: 8),
                  Icon(CupertinoIcons.chevron_forward, size: 16, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                ],
              ),
              onTap: () => _showSchemeTypePicker(context),
            ),
          ],
          ...DesignStyle.values.map((style) {
            final selected = settings.designStyle == style;
            return _iosTile(
              context,
              icon: style == DesignStyle.material
                  ? CupertinoIcons.app
                  : (style == DesignStyle.cupertino ? CupertinoIcons.device_phone_portrait : CupertinoIcons.gear_alt),
              title: style.label,
              subtitle: _styleDesc(style),
              trailing: selected
                  ? Icon(CupertinoIcons.check_mark, size: 20, color: CupertinoColors.systemBlue.resolveFrom(context))
                  : null,
              onTap: () => notifier.setDesignStyle(style),
            );
          }),
        ],
      ),
    );
  }

  String _styleDesc(DesignStyle s) {
    switch (s) {
      case DesignStyle.material: return 'Google Material Design 3 风格';
      case DesignStyle.cupertino: return 'Apple iOS/macOS 风格';
      case DesignStyle.system: return 'Android 用 Material，iOS 用 Cupertino';
    }
  }

  void _showThemeModePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('主题模式'),
        actions: [
          _themeAction(ctx, CupertinoIcons.gear, '跟随系统', ThemeMode.system, CupertinoColors.systemBlue),
          _themeAction(ctx, CupertinoIcons.sun_max, '浅色', ThemeMode.light, CupertinoColors.systemOrange),
          _themeAction(ctx, CupertinoIcons.moon, '深色', ThemeMode.dark, CupertinoColors.systemIndigo),
        ],
        cancelButton: CupertinoActionSheetAction(isDefaultAction: true, child: const Text('取消'), onPressed: () => Navigator.pop(ctx)),
      ),
    );
  }

  CupertinoActionSheetAction _themeAction(BuildContext ctx, IconData icon, String label, ThemeMode mode, Color color) {
    return CupertinoActionSheetAction(
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 18, color: CupertinoDynamicColor.resolve(color, ctx)),
        const SizedBox(width: 8),
        Text(label),
        if (settings.themeMode == mode) ...[const SizedBox(width: 8), const Icon(CupertinoIcons.check_mark, size: 18)],
      ]),
      onPressed: () { notifier.setThemeMode(mode); Navigator.pop(ctx); },
    );
  }

  void _showColorPicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择主题色'),
        actions: [
          ...ThemeSettingsSection.seedColors.map((color) {
            final sel = settings.seedColor.toARGB32() == color.toARGB32();
            return CupertinoActionSheetAction(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 24, height: 24, decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle,
                  border: Border.all(color: sel ? CupertinoColors.systemBlue : CupertinoColors.separator, width: sel ? 3 : 0.5),
                )),
                if (sel) ...[const SizedBox(width: 12), const Icon(CupertinoIcons.check_mark, size: 18)],
              ]),
              onPressed: () { notifier.setSeedColor(color); Navigator.pop(ctx); },
            );
          }),
          CupertinoActionSheetAction(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(CupertinoIcons.color_filter, color: CupertinoColors.systemPurple.resolveFrom(ctx)),
              const SizedBox(width: 8),
              const Text('自定义颜色...'),
            ]),
            onPressed: () { Navigator.pop(ctx); _showCustomPicker(context); },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(isDefaultAction: true, child: const Text('取消'), onPressed: () => Navigator.pop(ctx)),
      ),
    );
  }

  void _showCustomPicker(BuildContext context) {
    final hsv = HSVColor.fromColor(settings.seedColor);
    double h = hsv.hue, s = hsv.saturation, v = hsv.value;
    showCupertinoDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final picked = HSVColor.fromAHSV(1, h, s, v).toColor();
          return CupertinoAlertDialog(
            title: const Text('自定义颜色'),
            content: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 64, height: 64, decoration: BoxDecoration(color: picked, shape: BoxShape.circle, border: Border.all(color: CupertinoColors.separator.resolveFrom(ctx), width: 0.5))),
                const SizedBox(height: 16),
                _hsvRow('H', h, 0, 360, (v) => setState(() => h = v)),
                _hsvRow('S', s, 0, 1, (v) => setState(() => s = v)),
                _hsvRow('V', v, 0.2, 1, (val) => setState(() => v = val)),
              ]),
            ),
            actions: [
              CupertinoDialogAction(child: const Text('取消'), onPressed: () => Navigator.pop(ctx)),
              CupertinoDialogAction(isDefaultAction: true, child: const Text('确定'), onPressed: () { notifier.setSeedColor(picked); Navigator.pop(ctx); }),
            ],
          );
        },
      ),
    );
  }

  Widget _hsvRow(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Row(children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      Expanded(child: CupertinoSlider(value: value, min: min, max: max, onChanged: onChanged)),
    ]);
  }

  void _showSchemeTypePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('配色方案'),
        actions: ColorSchemeType.values.map((type) {
          final sel = settings.colorSchemeType == type;
          return CupertinoActionSheetAction(
            child: Row(children: [
              Icon(type.icon, size: 20, color: CupertinoColors.systemBlue.resolveFrom(ctx)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(type.label, style: const TextStyle(fontSize: 17)),
                Text(type.description, style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel.resolveFrom(ctx))),
              ])),
              if (sel) const Icon(CupertinoIcons.check_mark, size: 18, color: CupertinoColors.systemBlue),
            ]),
            onPressed: () { notifier.setColorSchemeType(type); Navigator.pop(ctx); },
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(isDefaultAction: true, child: const Text('取消'), onPressed: () => Navigator.pop(ctx)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Interaction Card
// ═══════════════════════════════════════════════════════════════════════════

