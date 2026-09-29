import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:li_curriculum_table/core/presentation/styles/ui_style.dart';
import 'package:li_curriculum_table/core/presentation/styles/material_3/m3e_icons.dart';
import 'package:li_curriculum_table/core/presentation/styles/material_3/m3e_navigation_scaffold.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Material 3 Expressive — Design Tokens (from official specification)
// ═══════════════════════════════════════════════════════════════════════════
//
// Shape corner radius scale (dp):
//   none=0, extraSmall=4, small=8, medium=12, large=16,
//   largeIncreased=20, extraLarge=28, extraLargeIncreased=32,
//   extraExtraLarge=48, full=pill
//
// Spacing: 8dp baseline grid (space50=4, space100=8, space150=12,
//          space200=16, space300=24, space400=32)
//
// Elevation: cards=0-1, navBar=0, FAB=6, dialogs=6
//
// Color roles: primary → main actions, secondary → variety,
//              tertiary → accents/highlights, surfaceContainerLow → card bg,
//              surfaceContainerHigh → search bg, outlineVariant → subtle borders
// ═══════════════════════════════════════════════════════════════════════════

/// M3E shape tokens as constants for single-source-of-truth.
class _M3eShape {
  const _M3eShape._();
  static const double none = 0;
  static const double extraSmall = 4;
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double largeIncreased = 20;
  static const double extraLarge = 28;
  static const double extraLargeIncreased = 32;
  static const double extraExtraLarge = 48;
  // "Full" → dynamically computed as pill (height/2).
}

/// M3E spacing tokens (8dp baseline grid).
// ignore: unused_element
class _M3eSpacing {
  const _M3eSpacing._();
  // ignore: unused_field
  static const double space50 = 4;
  static const double space100 = 8;
  // ignore: unused_field
  static const double space150 = 12;
  static const double space200 = 16;
  // ignore: unused_field
  static const double space300 = 24;
  // ignore: unused_field
  static const double space400 = 32;
}

/// Concrete implementation of [UiStyle] for Material Design 3 Expressive.
class Material3ExpressiveStyle implements UiStyle {
  const Material3ExpressiveStyle();

  @override
  DesignStyle get style => DesignStyle.material;

  @override
  String get name => 'Material 3 Expressive';

  @override
  UiStyleIcons get icons => const Material3Icons();

  @override
  Color pageBackgroundColor(ColorScheme colorScheme) => colorScheme.surface;

  @override
  bool get usesAmbientBackground => false;

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
    return M3eNavigationScaffold(
      currentIndex: currentIndex,
      onIndexChanged: onIndexChanged,
      items: items,
      body: body,
      floatingActionButton: actionButton,
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
    return M3EFab(
      onPressed: onPressed,
      tooltip: tooltip ?? label,
      color: M3EFabColor.secondary,
      icon: icon,
    );
  }

  // ─── Title Bar ──────────────────────────────────────────────────────────

  @override
  Widget buildTitleBarContainer({
    required BuildContext context,
    required Widget child,
    double height = 40,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: height,
      color: cs.surfaceContainerHigh,
      child: child,
    );
  }

  // ─── Card ───────────────────────────────────────────────────────────────
  //
  // M3E cards default to Outlined variant with `extraLarge` (28dp) radius
  // for settings/hero sections, or `largeIncreased` (20dp) for list items.
  // Elevation: 0 (outlined variant), border: outlineVariant at 0.3 alpha.

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

    // Map the incoming radius to the nearest M3E shape token.
    final effectiveRadius = _nearestM3eRadius(borderRadius);

    final card = M3ECard(
      variant: M3ECardVariant.outlined,
      borderRadius: BorderRadius.circular(effectiveRadius),
      elevation: 0,
      color: color ?? cs.surfaceContainerLow,
      border: BorderSide(
        color: isSelected
            ? (accentColor ?? cs.primary)
            : cs.outlineVariant.withValues(alpha: 0.3),
        width: isSelected ? 2.0 : 0.8,
      ),
      padding: padding ?? const EdgeInsets.all(_M3eSpacing.space200),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: card,
      );
    }
    return card;
  }

  /// Snaps a raw borderRadius to the nearest M3E shape token.
  double _nearestM3eRadius(double raw) {
    const tokens = [
      _M3eShape.none,
      _M3eShape.extraSmall,
      _M3eShape.small,
      _M3eShape.medium,
      _M3eShape.large,
      _M3eShape.largeIncreased,
      _M3eShape.extraLarge,
      _M3eShape.extraLargeIncreased,
      _M3eShape.extraExtraLarge,
    ];
    double closest = tokens.first;
    double minDiff = (raw - closest).abs();
    for (final t in tokens.skip(1)) {
      final diff = (raw - t).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = t;
      }
    }
    return closest;
  }

  // ─── Switch ─────────────────────────────────────────────────────────────

  @override
  Widget buildSwitch({
    required BuildContext context,
    required bool value,
    required ValueChanged<bool>? onChanged,
    Color? activeColor,
  }) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: activeColor,
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
    return FilterChip(
      label: Text(label),
      selected: selected,
      avatar: icon,
      onSelected: onTap != null ? (_) => onTap() : null,
      selectedColor: selectedColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_M3eShape.largeIncreased),
      ),
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
    return M3EIconButton(
      icon: icon,
      variant: M3EIconButtonVariant.standard,
      shape: M3EIconButtonShapeVariant.round,
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }

  // ─── Search Bar ─────────────────────────────────────────────────────────
  //
  // M3E: search bars use "full" (pill) corner radius per spec.

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
    final cs = Theme.of(context).colorScheme;
    return SearchBar(
      controller: controller,
      hintText: placeholder,
      leading: Icon(icons.search, color: cs.onSurfaceVariant),
      trailing: [
        ?trailing,
        if (controller != null && controller.text.isNotEmpty)
          M3EIconButton(
            icon: Icon(icons.clear),
            variant: M3EIconButtonVariant.tonal,
            shape: M3EIconButtonShapeVariant.round,
            onPressed: () {
              controller.clear();
              onClear?.call();
            },
          ),
      ],
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      elevation: WidgetStateProperty.all(0),
      backgroundColor: WidgetStateProperty.all(cs.surfaceContainerHigh),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          // M3E spec: search bar uses "full" (pill) shape.
          borderRadius: BorderRadius.circular(_M3eShape.extraExtraLarge),
          side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
      ),
    );
  }

  // ─── Activity Indicator ─────────────────────────────────────────────────

  @override
  Widget buildActivityIndicator({
    required BuildContext context,
    double size = 20,
    Color? color,
    double strokeWidth = 2,
  }) {
    return M3ELoadingIndicator(
      constraints: BoxConstraints.tight(Size(size, size)),
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
    if (value != null) {
      return LinearProgressIndicator(
        value: value,
        color: color,
        backgroundColor: backgroundColor,
        minHeight: height,
        borderRadius: BorderRadius.circular(height / 2),
      );
    }
    return M3EProgressIndicator.linear(
      color: color,
      linearSize: height <= 4
          ? M3EProgressIndicatorSize.s
          : M3EProgressIndicatorSize.m,
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
    final m3Style = switch (style) {
      UiButtonStyle.filled => M3EButtonStyle.filled,
      UiButtonStyle.tonal => M3EButtonStyle.tonal,
      UiButtonStyle.outlined => M3EButtonStyle.outlined,
      UiButtonStyle.text => M3EButtonStyle.text,
    };
    Widget btn;
    final btnSize = height >= 44
        ? M3EButtonSize.lg
        : (height <= 34 ? M3EButtonSize.sm : M3EButtonSize.md);
    if (icon != null) {
      btn = M3EButton.icon(
        icon: icon,
        label: child,
        onPressed: onPressed,
        style: m3Style,
        size: btnSize,
        shape: M3EButtonShape.round,
      );
    } else {
      switch (style) {
        case UiButtonStyle.filled:
          btn = M3EButton.filled(
            onPressed: onPressed,
            size: btnSize,
            shape: M3EButtonShape.round,
            child: child,
          );
          break;
        case UiButtonStyle.tonal:
          btn = M3EButton.tonal(
            onPressed: onPressed,
            size: btnSize,
            shape: M3EButtonShape.round,
            child: child,
          );
          break;
        case UiButtonStyle.outlined:
          btn = M3EButton.outlined(
            onPressed: onPressed,
            size: btnSize,
            shape: M3EButtonShape.round,
            child: child,
          );
          break;
        case UiButtonStyle.text:
          btn = M3EButton.text(
            onPressed: onPressed,
            size: btnSize,
            shape: M3EButtonShape.round,
            child: child,
          );
          break;
      }
    }
    if (width != null) {
      return SizedBox(width: width, height: height, child: btn);
    }
    return SizedBox(height: height, child: btn);
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
    return _M3EDropdownWrapper<T>(
      hintText: hintText,
      value: value,
      items: items,
      onSelected: onSelected,
      prefixIcon: prefixIcon,
      width: width,
    );
  }

  // ─── Header Bar ─────────────────────────────────────────────────────────
  //
  // M3E: a clean surface with a subtle bottom divider for visual separation.

  @override
  Widget buildHeaderBar({
    required BuildContext context,
    required Widget child,
    double? height,
    EdgeInsetsGeometry? padding,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: height,
      padding:
          padding ??
          const EdgeInsets.symmetric(
            horizontal: _M3eSpacing.space200,
            vertical: _M3eSpacing.space100,
          ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: child,
    );
  }

  // ─── Messages / Snackbar ────────────────────────────────────────────────

  @override
  void showMessage(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message), duration: duration));
  }

  // ─── Confirm Dialog ─────────────────────────────────────────────────────
  //
  // M3E: dialog radius = extraLargeIncreased (32dp).

  @override
  Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = '确认',
    String cancelText = '取消',
    bool isDestructive = false,
  }) async {
    final cs = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_M3eShape.extraLargeIncreased),
        ),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelText),
          ),
          FilledButton(
            style: isDestructive
                ? FilledButton.styleFrom(backgroundColor: cs.error)
                : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
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
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_M3eShape.extraLargeIncreased),
        ),
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: placeholder,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_M3eShape.medium),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result;
  }

  // ─── Lifecycle ──────────────────────────────────────────────────────────

  @override
  Widget wrapContent({
    required BuildContext context,
    required Widget child,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    final theme = Theme.of(context);
    final m3eData = M3EThemeData.fromMaterial(theme);
    // ignore: deprecated_member_use
    return MaterialUiCompatibilityBridge(
      child: M3ETheme(data: m3eData, child: child),
    );
  }

  @override
  Future<void> initialize() async {}

  @override
  Widget wrapApp({
    required Widget child,
    required ColorScheme lightScheme,
    required ColorScheme darkScheme,
    required bool isDark,
  }) => child;

  // ─── Slider ─────────────────────────────────────────────────────────────
  //
  // M3E: M3ESlider with rounded track and an expressive thumb that grows
  // on press. Wrapped in fixed height to keep consistent track thickness.

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
    return M3ESlider(
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      label: label,
      onChanged: enabled ? onChanged : null,
      onChangeEnd: onChangeEnd,
      enabled: enabled,
    );
  }

  // ─── Segmented Control ──────────────────────────────────────────────────
  //
  // M3E: M3EButtonGroup (connected = pill outline, standard = loose chips).

  @override
  Widget buildSegmentedControl({
    required BuildContext context,
    required List<SegmentItem> segments,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    bool connected = true,
    IconData? iconOverride,
  }) {
    final actions = segments
        .map((s) => M3EButtonGroupAction(icon: s.icon, label: Text(s.label)))
        .toList();
    return M3EButtonGroup(
      type: connected
          ? M3EButtonGroupType.connected
          : M3EButtonGroupType.standard,
      style: M3EButtonStyle.tonal,
      size: M3EButtonSize.sm,
      shape: M3EButtonShape.round,
      overflow: connected
          ? M3EButtonGroupOverflow.none
          : M3EButtonGroupOverflow.scroll,
      neighborSquish: false,
      selectedIndex: selectedIndex,
      onSelectedIndexChanged: (i) {
        if (i != null) onSelected(i);
      },
      actions: actions,
    );
  }

  // ─── Text Field ─────────────────────────────────────────────────────────
  //
  // M3E: filled TextField with rounded border and inline label.

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
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      minLines: obscureText ? 1 : minLines,
      maxLines: obscureText ? 1 : (maxLines ?? minLines),
      maxLength: maxLength,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_M3eShape.medium),
        ),
      ),
    );
  }

  // ─── Sheet Background ───────────────────────────────────────────────────
  //
  // M3E: opaque surface with extra-large top radius.

  @override
  Widget buildSheetBackground({
    required BuildContext context,
    required Widget child,
    double topRadius = 28,
    EdgeInsetsGeometry? padding,
    bool isScrollControlled = true,
    bool useSafeArea = true,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
      ),
      padding: padding,
      child: child,
    );
  }
}

class _M3EDropdownWrapper<T> extends StatefulWidget {
  final String hintText;
  final T? value;
  final List<DropdownOption<T>> items;
  final ValueChanged<T> onSelected;
  final Widget? prefixIcon;
  final double? width;

  const _M3EDropdownWrapper({
    required this.hintText,
    required this.value,
    required this.items,
    required this.onSelected,
    this.prefixIcon,
    this.width,
  });

  @override
  State<_M3EDropdownWrapper<T>> createState() => _M3EDropdownWrapperState<T>();
}

class _M3EDropdownWrapperState<T> extends State<_M3EDropdownWrapper<T>> {
  late final M3EDropdownController<T> _controller;

  @override
  void initState() {
    super.initState();
    _controller = M3EDropdownController<T>()..initialize();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _M3EDropdownWrapper<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value || oldWidget.items != widget.items) {
      _sync();
    }
  }

  void _sync() {
    _controller.setItems(
      widget.items
          .map(
            (opt) => M3EDropdownItem<T>(
              label: opt.label,
              value: opt.value,
              selected: opt.value == widget.value,
            ),
          )
          .toList(),
    );
    if (widget.value != null) {
      _controller.selectWhere((item) => item.value == widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final menu = M3EDropdownMenu<T>(
      singleSelect: true,
      showChipAnimation: false,
      items: const [],
      controller: _controller,
      onSelectionChanged: (selected) {
        if (selected.isNotEmpty) widget.onSelected(selected.first.value);
      },
      containerRadius: 16,
      fieldStyle: M3EDropdownFieldStyle(
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: BorderSide(color: cs.outlineVariant, width: 0.5),
        focusedBorder: BorderSide(color: cs.primary, width: 1),
        borderRadius: BorderRadius.circular(12),
        selectedBorderRadius: 12,
      ),
      dropdownStyle: const M3EDropdownPanelStyle(
        maxHeight: 300,
        containerRadius: 16,
      ),
      itemStyle: M3EDropdownItemStyle(
        outerRadius: 12,
        innerRadius: 6,
        selectedIcon: Icon(Icons.check, size: 18, color: cs.primary),
      ),
    );

    if (widget.width != null) {
      return SizedBox(width: widget.width, child: menu);
    }
    return menu;
  }
}
