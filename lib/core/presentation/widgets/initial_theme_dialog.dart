import 'package:flutter/material.dart' hide ThemeMode;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';

class InitialThemeSelection {
  const InitialThemeSelection(this.designStyle, this.themeMode);

  final DesignStyle designStyle;
  final ThemeMode themeMode;
}

/// First-use appearance choice, shown immediately after accepting the terms.
Future<InitialThemeSelection?> showInitialThemeDialog(
  BuildContext context, {
  required DesignStyle designStyle,
  required ThemeMode themeMode,
  required ValueChanged<InitialThemeSelection> onPreview,
}) {
  var selectedStyle = designStyle;
  var selectedMode = themeMode;
  return showDialog<InitialThemeSelection>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        final isGlass =
            UiStyleRegistry.resolveConcreteStyle(selectedStyle) ==
            DesignStyle.cupertino;
        void preview({DesignStyle? style, ThemeMode? mode}) {
          setDialogState(() {
            selectedStyle = style ?? selectedStyle;
            selectedMode = mode ?? selectedMode;
          });
          onPreview(InitialThemeSelection(selectedStyle, selectedMode));
        }

        final content = ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '选择外观',
                  style: Theme.of(dialogContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _ThemeChoiceContent(
                  designStyle: selectedStyle,
                  themeMode: selectedMode,
                  onDesignStyleChanged: (value) => preview(style: value),
                  onThemeModeChanged: (value) => preview(mode: value),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: adaptiveButton(
                    context: dialogContext,
                    designStyle: selectedStyle,
                    style: UiButtonStyle.filled,
                    onPressed: () => Navigator.of(
                      dialogContext,
                    ).pop(InitialThemeSelection(selectedStyle, selectedMode)),
                    child: const Text('开始使用'),
                  ),
                ),
              ],
            ),
          ),
        );
        return Dialog(
          backgroundColor: isGlass ? Colors.transparent : null,
          elevation: isGlass ? 0 : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: isGlass
              ? GlassContainer(
                  shape: const LiquidRoundedSuperellipse(borderRadius: 28),
                  padding: EdgeInsets.zero,
                  child: content,
                )
              : content,
        );
      },
    ),
  );
}

class _ThemeChoiceContent extends StatelessWidget {
  const _ThemeChoiceContent({
    required this.designStyle,
    required this.themeMode,
    required this.onDesignStyleChanged,
    required this.onThemeModeChanged,
  });

  final DesignStyle designStyle;
  final ThemeMode themeMode;
  final ValueChanged<DesignStyle> onDesignStyleChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = (MediaQuery.sizeOf(context).height * 0.65).clamp(
      200.0,
      480.0,
    );
    return SizedBox(
      height: maxHeight,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '选择喜欢的界面风格和明暗模式。以后可在「设置 → 外观」中更改。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text('界面风格', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final style in DesignStyle.values) ...[
              _ChoiceRow(
                icon: style.icon,
                label: style.label,
                subtitle: switch (style) {
                  DesignStyle.system => '根据设备自动选择界面风格',
                  DesignStyle.material => '大圆角与鲜明色彩',
                  DesignStyle.cupertino => '悬浮玻璃与柔和模糊',
                },
                selected: designStyle == style,
                onTap: () => onDesignStyleChanged(style),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 10),
            Text('明暗模式', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final mode in ThemeMode.values) ...[
              _ChoiceRow(
                icon: switch (mode) {
                  ThemeMode.system => Icons.brightness_auto_rounded,
                  ThemeMode.light => Icons.light_mode_rounded,
                  ThemeMode.dark => Icons.dark_mode_rounded,
                },
                label: switch (mode) {
                  ThemeMode.system => '跟随系统',
                  ThemeMode.light => '浅色',
                  ThemeMode.dark => '深色',
                },
                selected: themeMode == mode,
                onTap: () => onThemeModeChanged(mode),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected
                ? colors.primary.withValues(alpha: 0.15)
                : colors.onSurface.withValues(alpha: 0.05),
            border: Border.all(
              color: selected
                  ? colors.primary.withValues(alpha: 0.55)
                  : colors.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 21,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, size: 20, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
