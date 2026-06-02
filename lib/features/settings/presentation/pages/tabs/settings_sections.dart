import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:li_curriculum_table/app/app.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';

// ─── Constants ───────────────────────────────────────────────────────────────

const sectionSpacing = 20.0;
const cardPadding = EdgeInsets.all(16);

// ─── Theme Settings ──────────────────────────────────────────────────────────

class ThemeSettingsSection extends StatelessWidget {
  const ThemeSettingsSection({super.key});

  static const seedColors = [
    Color(0xFF0A7C6D), // Teal (default)
    Color(0xFF6750A4), // Purple
    Color(0xFF0061A4), // Blue
    Color(0xFF006E1C), // Green
    Color(0xFF904D00), // Orange
    Color(0xFFBA1A1A), // Red
    Color(0xFF5C6200), // Olive
    Color(0xFF006493), // Cyan
    Color(0xFF8B5000), // Amber
    Color(0xFF5E5B8E), // Indigo Grey
  ];

  @override
  Widget build(BuildContext context) {
    final settings = sl<SettingsController>().state.value;
    final notifier = sl<SettingsController>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ds = settings.designStyle;

    return SectionCard(
      icon: AppIcons.palette(ds),
      title: '外观',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Theme mode
          Center(
            child: Text('主题模式',
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 10),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_rounded),
                    label: Text('跟随系统'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_rounded),
                    label: Text('浅色'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_rounded),
                    label: Text('深色'),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (modes) => notifier.setThemeMode(modes.first),
                showSelectedIcon: false,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Dynamic color toggle
          SettingsTile(
            icon: AppIcons.colorLens(ds),
            title: '动态取色',
            subtitle: '从壁纸或系统提取主题色（仅部分设备支持）',
            trailing: Switch(
              value: settings.useDynamicColor,
              onChanged: (val) => notifier.setUseDynamicColor(val),
            ),
          ),

          // Seed color picker
          if (!settings.useDynamicColor) ...[
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text('主题色', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ...seedColors.map((color) {
                  final isSelected = settings.seedColor.toARGB32() == color.toARGB32();
                  return GestureDetector(
                    onTap: () => notifier.setSeedColor(color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: colorScheme.onSurface, width: 2.5)
                            : Border.all(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                width: 1,
                              ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Icon(Icons.check_rounded,
                              color: color.computeLuminance() > 0.5
                                  ? Colors.black87
                                  : Colors.white,
                              size: 20)
                          : null,
                    ),
                  );
                }),
                // Custom color button
                GestureDetector(
                  onTap: () => _showMaterialCustomColorPicker(context, settings.seedColor, notifier),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(Icons.palette_outlined, size: 20, color: colorScheme.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Color scheme type
            Text('配色方案', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ColorSchemeType.values.map((type) {
                final isSelected = settings.colorSchemeType == type;
                return ChoiceChip(
                  label: Text(type.label),
                  selected: isSelected,
                  onSelected: (_) => notifier.setColorSchemeType(type),
                  avatar: Icon(type.icon, size: 18),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

void _showMaterialCustomColorPicker(
  BuildContext context,
  Color current,
  SettingsController notifier,
) {
  final hsv = HSVColor.fromColor(current);
  double hue = hsv.hue;
  double saturation = hsv.saturation;
  double value = hsv.value;

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final picked = HSVColor.fromAHSV(1, hue, saturation, value).toColor();
          return AlertDialog(
            title: const Text('自定义颜色'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: picked,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 0.5),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const SizedBox(width: 24, child: Text('H', style: TextStyle(fontWeight: FontWeight.w600))),
                    Expanded(
                      child: Slider(
                        value: hue,
                        min: 0,
                        max: 360,
                        activeColor: HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
                        onChanged: (v) => setState(() => hue = v),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(width: 24, child: Text('S', style: TextStyle(fontWeight: FontWeight.w600))),
                    Expanded(
                      child: Slider(
                        value: saturation,
                        min: 0,
                        max: 1,
                        onChanged: (v) => setState(() => saturation = v),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(width: 24, child: Text('V', style: TextStyle(fontWeight: FontWeight.w600))),
                    Expanded(
                      child: Slider(
                        value: value,
                        min: 0.2,
                        max: 1,
                        onChanged: (v) => setState(() => value = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () {
                  notifier.setSeedColor(picked);
                  Navigator.pop(ctx);
                },
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
    },
  );
}

// ─── Design Style Settings ───────────────────────────────────────────────────

class DesignStyleSection extends StatelessWidget {
  const DesignStyleSection({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = sl<SettingsController>().state.value;
    final notifier = sl<SettingsController>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ds = settings.designStyle;

    return SectionCard(
      icon: Icons.phone_android,
      title: '设计风格',
      subtitle: '切换 Material 或 Cupertino 界面风格',
      child: Column(
        children: [
          ...DesignStyle.values.map((style) {
            final isSelected = settings.designStyle == style;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => notifier.setDesignStyle(style),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant.withValues(alpha: 0.5),
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? colorScheme.primaryContainer.withValues(alpha: 0.15)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          style.icon,
                          size: 22,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                style.label,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                _styleDescription(style),
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            AppIcons.checkCircle(ds),
                            size: 20,
                            color: colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _styleDescription(DesignStyle style) {
    switch (style) {
      case DesignStyle.material:
        return 'Google Material Design 3 风格';
      case DesignStyle.cupertino:
        return 'Apple iOS/macOS 风格';
      case DesignStyle.system:
        return 'Android 用 Material，iOS 用 Cupertino';
    }
  }
}

// ─── Proxy Settings ──────────────────────────────────────────────────────────

class ProxySettingsSection extends StatelessWidget {
  const ProxySettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = sl<SettingsController>().state.value;
    final notifier = sl<SettingsController>();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final ds = settings.designStyle;

    return SectionCard(
      icon: AppIcons.lan(ds),
      title: '本地代理',
      subtitle: '允许其他设备通过此应用中转教务系统请求',
      child: Column(
        children: [
          if (!isWeb) ...[
            SettingsTile(
              icon: AppIcons.router(ds),
              title: '开启本地代理网关',
              subtitle: '其他设备或本机网页版可通过此应用共享会话',
              trailing: Switch(
                value: settings.proxyEnabled,
                onChanged: (val) => notifier.setProxyEnabled(val),
              ),
            ),
            SettingsTile(
              icon: AppIcons.numbers(ds),
              title: '服务端监听端口',
              subtitle: '${settings.proxyPort}（重启服务后生效）',
              onTap: () =>
                  showPortDialog(context, settings.proxyPort, (p) => notifier.setProxyPort(p)),
            ),
          ] else ...[
            SettingsTile(
              icon: AppIcons.radar(ds),
              title: 'Native 代理探测端口',
              subtitle: '${settings.proxyPort}（刷新网页后生效）',
              onTap: () =>
                  showPortDialog(context, settings.proxyPort, (p) => notifier.setProxyPort(p)),
            ),
          ],
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.info(ds), size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '设置正确的端口可让网页版自动识别并使用手机端的登录状态，无需重复验证。',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showPortDialog(BuildContext context, int currentPort, Function(int) onSave) async {
    final result = await showAdaptiveInputDialog(
      context,
      designStyle: sl<SettingsController>().designStyle.value,
      title: '设置代理端口',
      placeholder: '默认 9999',
      initialValue: currentPort.toString(),
      keyboardType: TextInputType.number,
      confirmText: '保存',
      cancelText: '取消',
    );
    if (result != null) {
      final port = int.tryParse(result);
      if (port != null && port >= 1024 && port <= 65535) {
        onSave(port);
      }
    }
  }
}

// ─── Timetable Display Settings ──────────────────────────────────────────────

class TimetableDisplaySettingsSection extends StatelessWidget {
  const TimetableDisplaySettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = sl<SettingsController>().state.value;
    final notifier = sl<SettingsController>();
    final ds = settings.designStyle;

    return SectionCard(
      icon: AppIcons.viewWeek(ds),
      title: '课表显示',
      child: SettingsTile(
        icon: AppIcons.swapHoriz(ds),
        title: '按星期滑动',
        subtitle: '开启后，课表以整周为单位左右对齐滑动；关闭则自由无极滑动',
        trailing: Switch(
          value: settings.weeklyScroll,
          onChanged: (val) => notifier.setWeeklyScroll(val),
        ),
      ),
    );
  }
}

// ─── Shared UI Components ────────────────────────────────────────────────────

/// A card that wraps a settings section with a header.
class SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 18, color: colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// A consistent settings list tile with icon, title, subtitle, and optional switch or chevron.
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final effectiveIconColor = iconColor ?? colorScheme.onSurfaceVariant;

    final tile = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 20, color: effectiveIconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.bodyMedium),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
          if (trailing == null && onTap != null)
            Icon(
              AdaptiveStyle.isCupertino(
                sl<SettingsController>().state.value.designStyle,
              )
                  ? CupertinoIcons.chevron_right
                  : Icons.chevron_right_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: tile,
      );
    }
    return tile;
  }
}
