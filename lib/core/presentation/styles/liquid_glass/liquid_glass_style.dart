import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:material_ui/material_ui.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:li_curriculum_table/core/presentation/styles/ui_style.dart';
import 'package:li_curriculum_table/core/presentation/styles/liquid_glass/liquid_glass_icons.dart';
import 'package:li_curriculum_table/core/presentation/styles/liquid_glass/liquid_glass_navigation_scaffold.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
// iOS 26 Liquid Glass — Design Tokens
// ═══════════════════════════════════════════════════════════════════════════
//
// Source of truth: liquid_glass_widgets/example/lib/constants/glass_settings.dart
// and Apple's iOS 26 HIG guidelines.
//
// Key rules:
// • Glass = navigation chrome ONLY (bars, buttons, sheets, menus, overlays).
// • Content areas remain opaque (lists, cells, article tiles).
// • All surfaces share a single consistent 135° upper-left light source.
// • Use LiquidRoundedSuperellipse (iOS squircle) rather than rounded rects.
// ═══════════════════════════════════════════════════════════════════════════

/// Apple-standard upper-left light angle (135° in radians).
const double _kLightAngle = 0.75 * math.pi;

/// Glass settings aligned with RecommendedGlassSettings.standard —
/// optimized for scrollable content cards.
const _kCardSettings = LiquidGlassSettings(
  blur: 4,
  thickness: 10,
  glassColor: Color.fromRGBO(255, 255, 255, 0.08),
  lightAngle: _kLightAngle,
  lightIntensity: 0.7,
  ambientStrength: 0,
  saturation: 1.2,
  refractiveIndex: 1.2,
  chromaticAberration: 0.01,
  specularSharpness: GlassSpecularSharpness.medium,
);

/// Glass settings for surface / header / title bars.
const _kSurfaceSettings = LiquidGlassSettings(
  blur: 10,
  thickness: 10,
  glassColor: Color.fromRGBO(255, 255, 255, 0.20),
  lightAngle: _kLightAngle,
  lightIntensity: 0.7,
  ambientStrength: 0.3,
  saturation: 1.2,
  refractiveIndex: 1.15,
  chromaticAberration: 0.0,
  specularSharpness: GlassSpecularSharpness.medium,
);

/// Glass settings for interactive elements (icon buttons, etc.).
const _kInteractiveSettings = LiquidGlassSettings(
  blur: 10,
  thickness: 10,
  glassColor: Color.fromRGBO(255, 255, 255, 0.20),
  lightAngle: _kLightAngle,
  lightIntensity: 0.7,
  ambientStrength: 0.3,
  saturation: 0.0, // animated to 1.0 on press by GlassIconButton
  refractiveIndex: 0.7,
  chromaticAberration: 0.0,
);

/// Matches the example's RecommendedGlassSettings.input. Input fields need
/// their own softer, translucent surface instead of the desaturated button
/// glass used by icon controls.
const _kInputSettings = LiquidGlassSettings(
  blur: 20,
  thickness: 10,
  glassColor: Color.fromRGBO(255, 255, 255, 0.12),
  lightAngle: _kLightAngle,
  lightIntensity: 0.7,
  ambientStrength: 0.4,
  saturation: 1.2,
  refractiveIndex: 0.7,
  chromaticAberration: 0.0,
);

/// Concrete implementation of [UiStyle] for iOS 26 Liquid Glass.
class LiquidGlassStyle implements UiStyle {
  const LiquidGlassStyle();

  @override
  DesignStyle get style => DesignStyle.cupertino;

  @override
  String get name => 'iOS 26 Liquid Glass';

  @override
  UiStyleIcons get icons => const LiquidGlassIcons();

  @override
  Color pageBackgroundColor(ColorScheme colorScheme) => Colors.transparent;

  @override
  bool get usesAmbientBackground => true;

  // ─── Navigation Shell ───────────────────────────────────────────────────

  @override
  Widget buildNavigationShell({
    required BuildContext context,
    required Brightness brightness,
    required int currentIndex,
    required ValueChanged<int> onIndexChanged,
    required List<NavigationItemConfig> items,
    required Widget body,
    Widget? actionButton,
  }) {
    return LiquidGlassNavigationScaffold(
      brightness: brightness,
      currentIndex: currentIndex,
      onIndexChanged: onIndexChanged,
      items: items,
      body: body,
      extraButton: actionButton,
    );
  }

  @override
  Widget? buildNavigationActionButton({
    required BuildContext context,
    required Widget icon,
    required String label,
    required VoidCallback? onPressed,
    String? tooltip,
  }) {
    return LiquidGlassExtraButtonWidget(
      GlassTabBarExtraButton(
        icon: icon,
        label: label,
        onTap: onPressed ?? () {},
      ),
    );
  }

  // ─── Title Bar ──────────────────────────────────────────────────────────

  @override
  Widget buildTitleBarContainer({
    required BuildContext context,
    required Widget child,
    double height = 40,
  }) {
    return GlassContainer(
      height: height,
      useOwnLayer: true,
      settings: _kSurfaceSettings,
      child: child,
    );
  }

  // ─── Card ───────────────────────────────────────────────────────────────

  @override
  Widget buildCard({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry? padding,
    double borderRadius = 20,
    Color? color,
    VoidCallback? onTap,
    bool isSelected = false,
    Color? accentColor,
  }) {
    final cs = Theme.of(context).colorScheme;

    // iOS 26 uses superellipse (squircle) corners, not simple rounded rects.
    final shape = LiquidRoundedSuperellipse(borderRadius: borderRadius);

    final selectedGlassColor = isSelected
        ? (accentColor ?? cs.primary).withValues(alpha: 0.14)
        : null;

    final card = GlassCard(
      useOwnLayer: true,
      shape: shape,
      settings: _kCardSettings.copyWith(
        glassColor: selectedGlassColor ?? color ?? _kCardSettings.glassColor,
      ),
      padding: padding ?? const EdgeInsets.all(20),
      child: child,
    );

    // iOS does NOT use Material InkWell ripple — use GestureDetector instead.
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }
    return card;
  }

  // ─── Switch ─────────────────────────────────────────────────────────────

  @override
  Widget buildSwitch({
    required BuildContext context,
    required bool value,
    required ValueChanged<bool>? onChanged,
    Color? activeColor,
  }) {
    return GlassSwitch(
      value: value,
      onChanged: onChanged ?? (_) {},
      activeColor: activeColor,
      useOwnLayer: true,
    );
  }

  // ─── Chip ───────────────────────────────────────────────────────────────

  @override
  Widget buildChip({
    required BuildContext context,
    required String label,
    bool selected = false,
    Widget? icon,
    VoidCallback? onTap,
    VoidCallback? onDeleted,
    Color? selectedColor,
  }) {
    return GlassChip(
      label: label,
      icon: icon,
      selected: selected,
      selectedColor: selectedColor,
      onTap: onTap,
      onDeleted: onDeleted,
    );
  }

  // ─── Icon Button ────────────────────────────────────────────────────────

  @override
  Widget buildIconButton({
    required BuildContext context,
    required Widget icon,
    required VoidCallback? onPressed,
    String? tooltip,
    double size = 36,
  }) {
    final btn = GlassIconButton(
      icon: icon,
      size: size,
      onPressed: onPressed,
      useOwnLayer: true,
      settings: _kInteractiveSettings,
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip, child: btn);
    }
    return btn;
  }

  // ─── Search Bar ─────────────────────────────────────────────────────────

  @override
  Widget buildSearchBar({
    required BuildContext context,
    required TextEditingController? controller,
    required String placeholder,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onClear,
    Widget? trailing,
  }) {
    final bar = GlassSearchBar(
      controller: controller,
      placeholder: placeholder,
      useOwnLayer: true,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
    if (trailing != null) {
      return Row(
        children: [
          Expanded(child: bar),
          const SizedBox(width: 8),
          trailing,
        ],
      );
    }
    return bar;
  }

  // ─── Activity Indicator ─────────────────────────────────────────────────

  @override
  Widget buildActivityIndicator({
    required BuildContext context,
    double size = 20,
    Color? color,
    double strokeWidth = 2,
  }) {
    return GlassProgressIndicator.circular(
      useOwnLayer: true,
      size: size,
      strokeWidth: strokeWidth,
      color: color,
    );
  }

  @override
  Widget buildLinearProgressIndicator({
    required BuildContext context,
    double? value,
    Color? color,
    Color? backgroundColor,
    double height = 4,
  }) {
    return GlassProgressIndicator.linear(
      useOwnLayer: true,
      value: value,
      color: color,
    );
  }

  @override
  Widget buildButton({
    required BuildContext context,
    required Widget child,
    required VoidCallback? onPressed,
    UiButtonStyle style = UiButtonStyle.filled,
    Widget? icon,
    EdgeInsetsGeometry? padding,
    double? width,
    double height = 40,
    Color? color,
  }) {
    final glassStyle = switch (style) {
      UiButtonStyle.filled => GlassButtonStyle.prominent,
      UiButtonStyle.tonal => GlassButtonStyle.filled,
      UiButtonStyle.outlined => GlassButtonStyle.filled,
      UiButtonStyle.text => GlassButtonStyle.transparent,
    };
    final cs = Theme.of(context).colorScheme;
    final content = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [icon, const SizedBox(width: 8), child],
          )
        : child;

    final btn = GlassButton.custom(
      onTap: onPressed ?? () {},
      style: glassStyle,
      useOwnLayer: true,
      height: height,
      width: width,
      shape: LiquidRoundedSuperellipse(borderRadius: height / 2),
      glowColor: color ?? (style == UiButtonStyle.filled ? cs.primary : null),
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          widthFactor: 1.0,
          child: DefaultTextStyle.merge(
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color:
                  style == UiButtonStyle.text || style == UiButtonStyle.filled
                  ? cs.primary
                  : cs.onSurface,
            ),
            child: content,
          ),
        ),
      ),
    );

    return Opacity(opacity: onPressed == null ? 0.45 : 1.0, child: btn);
  }

  @override
  Widget buildDropdown<T>({
    required BuildContext context,
    required String hintText,
    required T? value,
    required List<DropdownOption<T>> items,
    required ValueChanged<T> onSelected,
    Widget? prefixIcon,
    double? width,
  }) {
    final currentOption = items.where((i) => i.value == value).firstOrNull;
    final labelText = currentOption?.label ?? hintText;

    final menuItems = items.map((opt) {
      final isSelected = opt.value == value;
      return GlassMenuItem(
        title: opt.label,
        icon:
            opt.icon ??
            (isSelected
                ? const Icon(CupertinoIcons.checkmark, size: 14)
                : null),
        isSelected: isSelected,
        onTap: () => onSelected(opt.value),
      );
    }).toList();

    return GlassPullDownButton(
      label: labelText,
      icon: prefixIcon ?? const Icon(CupertinoIcons.chevron_down, size: 14),
      buttonHeight: 38,
      buttonWidth: width ?? 140,
      buttonShape: const LiquidRoundedSuperellipse(borderRadius: 12),
      items: menuItems,
    );
  }

  // ─── Header Bar ─────────────────────────────────────────────────────────

  @override
  Widget buildHeaderBar({
    required BuildContext context,
    required Widget child,
    double? height,
    EdgeInsetsGeometry? padding,
  }) {
    // Glass-based header with subtle frosted surface — no opaque background.
    return GlassContainer(
      height: height,
      useOwnLayer: true,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      settings: _kSurfaceSettings,
      child: child,
    );
  }

  // ─── Messages / Toast ───────────────────────────────────────────────────

  @override
  void showMessage(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    GlassToast.show(
      context,
      message: message,
      duration: duration,
      position: GlassToastPosition.top,
      type: GlassToastType.info,
    );
  }

  // ─── Confirm Dialog ─────────────────────────────────────────────────────

  @override
  Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = '确认',
    String cancelText = '取消',
    bool isDestructive = false,
  }) async {
    final result = await GlassDialog.show<bool>(
      context: context,
      title: title,
      message: content,
      actions: [
        GlassDialogAction(
          label: cancelText,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        GlassDialogAction(
          label: confirmText,
          isDestructive: isDestructive,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    return result ?? false;
  }

  // ─── Input Dialog ───────────────────────────────────────────────────────

  @override
  Future<String?> showInputDialog(
    BuildContext context, {
    required String title,
    String? placeholder,
    String? initialValue,
    TextInputType? keyboardType,
    String confirmText = '确定',
    String cancelText = '取消',
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await GlassDialog.show<String>(
      context: context,
      title: title,
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: GlassTextField(
          controller: controller,
          placeholder: placeholder,
          autofocus: true,
          keyboardType: keyboardType,
        ),
      ),
      actions: [
        GlassDialogAction(
          label: cancelText,
          onPressed: () => Navigator.of(context).pop(),
        ),
        GlassDialogAction(
          label: confirmText,
          isPrimary: true,
          onPressed: () => Navigator.of(context).pop(controller.text),
        ),
      ],
    );
    return result;
  }

  // ─── Lifecycle ──────────────────────────────────────────────────────────

  @override
  Future<void> initialize() async {
    await LiquidGlassWidgets.initialize();
  }

  @override
  Widget wrapApp({
    required Widget child,
    required ColorScheme lightScheme,
    required ColorScheme darkScheme,
    required bool isDark,
  }) {
    return LiquidGlassWidgets.wrap(
      brightnessResolver: (ctx) => isDark ? Brightness.dark : Brightness.light,
      child: child,
    );
  }

  @override
  Widget wrapContent({
    required BuildContext context,
    required Widget child,
    required bool isDark,
    required ColorScheme colorScheme,
  }) => child;

  // ─── Slider ─────────────────────────────────────────────────────────────
  //
  // Liquid Glass: iOS-style glass slider with jelly thumb and ambient track.
  // `useOwnLayer: true` keeps the slider self-contained inside parent sheets
  // and form rows.

  @override
  Widget buildSlider({
    required BuildContext context,
    required double value,
    required ValueChanged<double>? onChanged,
    double min = 0,
    double max = 1,
    int? divisions,
    String? label,
    ValueChanged<double>? onChangeEnd,
    bool enabled = true,
  }) {
    return GlassSlider(
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      onChanged: enabled ? onChanged : null,
      onChangeEnd: onChangeEnd,
      useOwnLayer: true,
      settings: _kInteractiveSettings,
      thumbRadius: 13,
      trackHeight: 4,
    );
  }

  // ─── Segmented Control ──────────────────────────────────────────────────
  //
  // Liquid Glass: GlassSegmentedControl — fixed-extent iOS UISegmentedControl
  // with an animated glass indicator and jelly physics.

  @override
  Widget buildSegmentedControl({
    required BuildContext context,
    required List<SegmentItem> segments,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    bool connected = true,
    IconData? iconOverride,
  }) {
    final segs = segments
        .map((s) => GlassSegment(label: s.label, icon: s.icon))
        .toList();
    final hasIconAndLabel = segments.any(
      (segment) => segment.icon != null && segment.label.isNotEmpty,
    );
    final controlHeight = hasIconAndLabel ? 48.0 : 36.0;
    if (segments.length > 5) {
      return GlassSegmentedControl.scrollable(
        segments: segs,
        selectedIndex: selectedIndex.clamp(0, segments.length - 1),
        onSegmentSelected: onSelected,
        height: controlHeight,
        useOwnLayer: true,
        settings: _kInteractiveSettings,
      );
    }
    return GlassSegmentedControl(
      segments: segs,
      selectedIndex: selectedIndex.clamp(0, segments.length - 1),
      onSegmentSelected: onSelected,
      height: controlHeight,
      useOwnLayer: true,
      settings: _kInteractiveSettings,
    );
  }

  // ─── Text Field ─────────────────────────────────────────────────────────
  //
  // Liquid Glass: GlassTextField in standalone mode so each field renders its
  // own glass surface (helpful when stacked inside a sheet).

  @override
  Widget buildTextField({
    required BuildContext context,
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool autofocus = false,
    bool obscureText = false,
    int minLines = 1,
    int? maxLines,
    int? maxLength,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    bool enabled = true,
  }) {
    final colors = Theme.of(context).colorScheme;
    return GlassTextField(
      controller: controller,
      placeholder: hintText ?? labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofocus: autofocus,
      obscureText: obscureText,
      maxLines: maxLines ?? (minLines > 1 ? minLines : 1),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      textStyle: TextStyle(color: colors.onSurface),
      placeholderStyle: TextStyle(
        color: colors.onSurface.withValues(alpha: 0.68),
      ),
      useOwnLayer: true,
      settings: _kInputSettings,
    );
  }

  // ─── Sheet Background ───────────────────────────────────────────────────
  //
  // Liquid Glass: transparent so the ambient mesh / blur shows through; the
  // top radius uses LiquidRoundedSuperellipse for the iOS squircle shape.

  @override
  Widget buildSheetBackground({
    required BuildContext context,
    required Widget child,
    double topRadius = 28,
    EdgeInsetsGeometry? padding,
    bool isScrollControlled = true,
    bool useSafeArea = true,
  }) {
    final radius = BorderRadius.vertical(top: Radius.circular(topRadius));
    final shape = LiquidRoundedSuperellipse(borderRadius: topRadius);
    return ClipRRect(
      borderRadius: radius,
      child: GlassContainer(
        useOwnLayer: true,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        settings: const LiquidGlassSettings(
          blur: 10,
          thickness: 10,
          glassColor: Color.fromRGBO(255, 255, 255, 0.12),
          lightAngle: _kLightAngle,
          lightIntensity: 0.7,
          ambientStrength: 0.4,
          saturation: 1.2,
          refractiveIndex: 0.15,
          chromaticAberration: 0.0,
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}
