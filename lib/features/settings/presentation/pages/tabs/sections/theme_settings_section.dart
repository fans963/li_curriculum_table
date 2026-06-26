import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:signals/signals_flutter.dart';
import 'package:slider_m3e/slider_m3e.dart';

import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';

import '../settings_sections.dart';

class ThemeSettingsSection extends StatelessWidget {
  const ThemeSettingsSection({super.key});

  static const seedColors = [
    Color(0xFF0A7C6D),
    Color(0xFF6750A4),
    Color(0xFF0061A4),
    Color(0xFF006E1C),
    Color(0xFF904D00),
    Color(0xFFBA1A1A),
    Color(0xFF5C6200),
    Color(0xFF006493),
    Color(0xFF8B5000),
    Color(0xFF5E5B8E),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = sl<SettingsController>().state.value;
    final notifier = sl<SettingsController>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ds = settings.designStyle;

    return SectionCard(
      icon: AppIcons.palette(ds),
      title: '外观',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ThemeModePicker(settings: settings, notifier: notifier, cs: cs, tt: tt),
          const SizedBox(height: 16),
          SettingsTile(
            icon: AppIcons.colorLens(ds),
            title: '动态取色',
            subtitle: '从壁纸或系统提取主题色',
            trailing: Switch(
              value: settings.useDynamicColor,
              onChanged: (v) => notifier.setUseDynamicColor(v),
            ),
          ),
          if (!settings.useDynamicColor) ...[
            const SizedBox(height: 16),
            _SeedColorPicker(settings: settings, notifier: notifier, cs: cs, tt: tt),
            const SizedBox(height: 16),
            _ColorSchemeTypePicker(settings: settings, notifier: notifier, cs: cs, tt: tt),
          ],
          const SizedBox(height: 16),
          _DesignStylePicker(settings: settings, notifier: notifier, cs: cs, tt: tt, ds: ds),
        ],
      ),
    );
  }
}

class _ThemeModePicker extends StatelessWidget {
  final AppSettings settings;
  final SettingsController notifier;
  final ColorScheme cs;
  final TextTheme tt;

  const _ThemeModePicker({required this.settings, required this.notifier, required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('主题模式', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: M3EToggleButtonGroup(
            type: M3EButtonGroupType.connected,
            style: M3EButtonStyle.tonal,
            size: M3EButtonSize.md,
            shape: M3EButtonShape.round,
            selectedIndex: ThemeMode.values.indexOf(settings.themeMode),
            onSelectedIndexChanged: (i) {
              if (i != null) notifier.setThemeMode(ThemeMode.values[i]);
            },
            actions: const [
              M3EToggleButtonGroupAction(icon: Icon(Icons.brightness_auto_rounded), label: Text('跟随系统')),
              M3EToggleButtonGroupAction(icon: Icon(Icons.light_mode_rounded), label: Text('浅色')),
              M3EToggleButtonGroupAction(icon: Icon(Icons.dark_mode_rounded), label: Text('深色')),
            ],
          ),
        ),
      ],
    );
  }
}

class _SeedColorPicker extends StatelessWidget {
  final AppSettings settings;
  final SettingsController notifier;
  final ColorScheme cs;
  final TextTheme tt;

  const _SeedColorPicker({required this.settings, required this.notifier, required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('主题色', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...ThemeSettingsSection.seedColors.map((color) {
              final selected = settings.seedColor.toARGB32() == color.toARGB32();
              return GestureDetector(
                onTap: () => notifier.setSeedColor(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: cs.onSurface, width: 2.5)
                        : Border.all(color: cs.outlineVariant.withValues(alpha: 0.3), width: 1),
                    boxShadow: selected
                        ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8, spreadRadius: 1)]
                        : null,
                  ),
                  child: selected
                      ? Icon(Icons.check_rounded, color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white, size: 20)
                      : null,
                ),
              );
            }),
            GestureDetector(
              onTap: () => _showCustomColorPicker(context, settings.seedColor, notifier),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3), width: 1),
                ),
                child: Icon(Icons.palette_outlined, size: 20, color: cs.primary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ColorSchemeTypePicker extends StatelessWidget {
  final AppSettings settings;
  final SettingsController notifier;
  final ColorScheme cs;
  final TextTheme tt;

  const _ColorSchemeTypePicker({required this.settings, required this.notifier, required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('配色方案', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 10),
        M3EToggleButtonGroup(
          type: M3EButtonGroupType.standard,
          style: M3EButtonStyle.tonal,
          size: M3EButtonSize.sm,
          shape: M3EButtonShape.round,
          overflow: M3EButtonGroupOverflow.scroll,
          selectedIndex: ColorSchemeType.values.indexOf(settings.colorSchemeType),
          onSelectedIndexChanged: (i) {
            if (i != null) notifier.setColorSchemeType(ColorSchemeType.values[i]);
          },
          actions: ColorSchemeType.values
              .map((t) => M3EToggleButtonGroupAction(icon: Icon(t.icon, size: 18), label: Text(t.label)))
              .toList(),
        ),
      ],
    );
  }
}

class _DesignStylePicker extends StatelessWidget {
  final AppSettings settings;
  final SettingsController notifier;
  final ColorScheme cs;
  final TextTheme tt;
  final DesignStyle ds;

  const _DesignStylePicker({required this.settings, required this.notifier, required this.cs, required this.tt, required this.ds});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('设计风格', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        ...DesignStyle.values.map((style) {
          final selected = settings.designStyle == style;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => notifier.setDesignStyle(style),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.4),
                      width: selected ? 2 : 1,
                    ),
                    color: selected ? cs.primaryContainer.withValues(alpha: 0.15) : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Icon(style.icon, size: 22, color: selected ? cs.primary : cs.onSurfaceVariant),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(style.label,
                                style: tt.bodyMedium?.copyWith(
                                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                                  color: selected ? cs.primary : cs.onSurface,
                                )),
                            Text(_desc(style), style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      if (selected) Icon(AppIcons.checkCircle(ds), size: 20, color: cs.primary),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  String _desc(DesignStyle s) {
    switch (s) {
      case DesignStyle.material:
        return 'Google Material Design 3 风格';
      case DesignStyle.cupertino:
        return 'Apple iOS/macOS 风格';
      case DesignStyle.system:
        return 'Android 用 Material，iOS 用 Cupertino';
    }
  }
}

void _showCustomColorPicker(BuildContext context, Color current, SettingsController notifier) {
  final hsv = HSVColor.fromColor(current);
  showDialog(
    context: context,
    builder: (ctx) => _ColorPickerDialog(
      initialHue: hsv.hue,
      initialSat: hsv.saturation,
      initialVal: hsv.value,
      notifier: notifier,
    ),
  );
}

class _ColorPickerDialog extends SignalStatefulWidget {
  final double initialHue;
  final double initialSat;
  final double initialVal;
  final SettingsController notifier;

  const _ColorPickerDialog({
    required this.initialHue,
    required this.initialSat,
    required this.initialVal,
    required this.notifier,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late final _hue = signal(widget.initialHue);
  late final _sat = signal(widget.initialSat);
  late final _val = signal(widget.initialVal);

  @override
  Widget build(BuildContext context) {
    final picked = HSVColor.fromAHSV(1, _hue.value, _sat.value, _val.value).toColor();
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('自定义颜色'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: picked, shape: BoxShape.circle, border: Border.all(color: cs.outlineVariant, width: 0.5)),
          ),
          const SizedBox(height: 16),
          _hsvRow('H', _hue.value, 0, 360, SliderM3EEmphasis.secondary, (v) => _hue.value = v),
          _hsvRow('S', _sat.value, 0, 1, SliderM3EEmphasis.surface, (v) => _sat.value = v),
          _hsvRow('V', _val.value, 0.2, 1, SliderM3EEmphasis.surface, (v) => _val.value = v),
        ],
      ),
      actions: [
        M3ETextButton(onPressed: () => Navigator.pop(context), size: M3EButtonSize.md, shape: M3EButtonShape.round, child: const Text('取消')),
        M3EFilledButton(
          onPressed: () { widget.notifier.setSeedColor(picked); Navigator.pop(context); },
          size: M3EButtonSize.md, shape: M3EButtonShape.round, child: const Text('确定'),
        ),
      ],
    );
  }
}

Widget _hsvRow(String label, double value, double min, double max, SliderM3EEmphasis emphasis, ValueChanged<double> onChanged) {
  return Row(
    children: [
      SizedBox(width: 24, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
      Expanded(child: SliderM3E(value: value, min: min, max: max, emphasis: emphasis, shapeFamily: SliderM3EShapeFamily.round, onChanged: onChanged)),
    ],
  );
}
