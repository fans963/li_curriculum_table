import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';

/// Shows an adaptive notification message (GlassToast or SnackBar).
void showAdaptiveMessage(
  BuildContext context, {
  DesignStyle? designStyle,
  required String message,
  Duration duration = const Duration(seconds: 2),
}) {
  UiStyleRegistry.resolve(designStyle).showMessage(
    context,
    message: message,
    duration: duration,
  );
}

/// Returns an adaptive loading indicator.
Widget adaptiveActivityIndicator({
  BuildContext? context,
  DesignStyle? designStyle,
  double size = 20,
  Color? color,
  double strokeWidth = 2,
}) {
  final ctx = context ?? (WidgetsBinding.instance.rootElement as BuildContext);
  return UiStyleRegistry.resolve(designStyle).buildActivityIndicator(
    context: ctx,
    size: size,
    color: color,
    strokeWidth: strokeWidth,
  );
}

/// Shows an adaptive confirmation dialog.
Future<bool> showAdaptiveConfirmDialog(
  BuildContext context, {
  DesignStyle? designStyle,
  required String title,
  required String content,
  String confirmText = '确认',
  String cancelText = '取消',
  bool isDestructive = false,
}) {
  return UiStyleRegistry.resolve(designStyle).showConfirmDialog(
    context,
    title: title,
    content: content,
    confirmText: confirmText,
    cancelText: cancelText,
    isDestructive: isDestructive,
  );
}

/// Shows an adaptive single input dialog.
Future<String?> showAdaptiveInputDialog(
  BuildContext context, {
  DesignStyle? designStyle,
  required String title,
  String? placeholder,
  String? initialValue,
  TextInputType keyboardType = TextInputType.text,
  String confirmText = '保存',
  String cancelText = '取消',
}) {
  return UiStyleRegistry.resolve(designStyle).showInputDialog(
    context,
    title: title,
    placeholder: placeholder,
    initialValue: initialValue,
    keyboardType: keyboardType,
    confirmText: confirmText,
    cancelText: cancelText,
  );
}

/// Renders an adaptive switch (GlassSwitch in Liquid Glass mode, Switch in M3 mode).
Widget adaptiveSwitch({
  BuildContext? context,
  DesignStyle? designStyle,
  required bool value,
  required ValueChanged<bool>? onChanged,
  Color? activeColor,
}) {
  final ctx = context ?? (WidgetsBinding.instance.rootElement as BuildContext);
  return UiStyleRegistry.resolve(designStyle).buildSwitch(
    context: ctx,
    value: value,
    onChanged: onChanged,
    activeColor: activeColor,
  );
}

/// Renders an adaptive chip (GlassChip in Liquid Glass mode, FilterChip in M3 mode).
Widget adaptiveChip({
  BuildContext? context,
  DesignStyle? designStyle,
  required String label,
  bool selected = false,
  Widget? icon,
  VoidCallback? onTap,
  VoidCallback? onDeleted,
  Color? selectedColor,
}) {
  final ctx = context ?? (WidgetsBinding.instance.rootElement as BuildContext);
  return UiStyleRegistry.resolve(designStyle).buildChip(
    context: ctx,
    label: label,
    selected: selected,
    icon: icon,
    onTap: onTap,
    onDeleted: onDeleted,
    selectedColor: selectedColor,
  );
}

/// Renders an adaptive icon button (GlassIconButton in Liquid Glass mode, M3EIconButton in M3 mode).
Widget adaptiveIconButton({
  BuildContext? context,
  DesignStyle? designStyle,
  required Widget icon,
  required VoidCallback? onPressed,
  String? tooltip,
  double size = 36,
}) {
  final ctx = context ?? (WidgetsBinding.instance.rootElement as BuildContext);
  return UiStyleRegistry.resolve(designStyle).buildIconButton(
    context: ctx,
    icon: icon,
    onPressed: onPressed,
    tooltip: tooltip,
    size: size,
  );
}

/// Renders an adaptive search bar (GlassSearchBar in Liquid Glass mode, SearchBar in M3 mode).
Widget adaptiveSearchBar({
  required BuildContext context,
  DesignStyle? designStyle,
  required TextEditingController? controller,
  required String placeholder,
  ValueChanged<String>? onChanged,
  ValueChanged<String>? onSubmitted,
  VoidCallback? onClear,
  Widget? trailing,
}) {
  return UiStyleRegistry.resolve(designStyle).buildSearchBar(
    context: context,
    controller: controller,
    placeholder: placeholder,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    onClear: onClear,
    trailing: trailing,
  );
}

/// Renders an adaptive surface card (GlassCard in Liquid Glass mode, M3ECard in M3 mode).
Widget adaptiveCard({
  required BuildContext context,
  DesignStyle? designStyle,
  required Widget child,
  EdgeInsetsGeometry? padding,
  double borderRadius = 20,
  Color? color,
  VoidCallback? onTap,
  bool isSelected = false,
  Color? accentColor,
}) {
  return UiStyleRegistry.resolve(designStyle).buildCard(
    context: context,
    child: child,
    padding: padding,
    borderRadius: borderRadius,
    color: color,
    onTap: onTap,
    isSelected: isSelected,
    accentColor: accentColor,
  );
}

/// Renders an adaptive button (GlassButton in Liquid Glass mode, M3EButton in M3 mode).
Widget adaptiveButton({
  required BuildContext context,
  DesignStyle? designStyle,
  required Widget child,
  required VoidCallback? onPressed,
  UiButtonStyle style = UiButtonStyle.filled,
  Widget? icon,
  EdgeInsetsGeometry? padding,
  double? width,
  double height = 40,
  Color? color,
}) {
  return UiStyleRegistry.resolve(designStyle).buildButton(
    context: context,
    child: child,
    onPressed: onPressed,
    style: style,
    icon: icon,
    padding: padding,
    width: width,
    height: height,
    color: color,
  );
}

/// Renders an adaptive linear progress bar (GlassProgressIndicator.linear in Liquid Glass, M3EProgressIndicator.linear in M3).
Widget adaptiveLinearProgressIndicator({
  required BuildContext context,
  DesignStyle? designStyle,
  double? value,
  Color? color,
  Color? backgroundColor,
  double height = 4,
}) {
  return UiStyleRegistry.resolve(designStyle).buildLinearProgressIndicator(
    context: context,
    value: value,
    color: color,
    backgroundColor: backgroundColor,
    height: height,
  );
}

/// Renders an adaptive dropdown selector (GlassPullDownButton in Liquid Glass, M3EDropdownMenu in M3).
Widget adaptiveDropdown<T>({
  required BuildContext context,
  DesignStyle? designStyle,
  required String hintText,
  required T? value,
  required List<DropdownOption<T>> items,
  required ValueChanged<T> onSelected,
  Widget? prefixIcon,
  double? width,
}) {
  return UiStyleRegistry.resolve(designStyle).buildDropdown(
    context: context,
    hintText: hintText,
    value: value,
    items: items,
    onSelected: onSelected,
    prefixIcon: prefixIcon,
    width: width,
  );
}

/// Renders an adaptive slider (GlassSlider in Liquid Glass mode, M3ESlider in M3 mode).
Widget adaptiveSlider({
  required BuildContext context,
  DesignStyle? designStyle,
  required double value,
  required ValueChanged<double>? onChanged,
  double min = 0,
  double max = 1,
  int? divisions,
  String? label,
  ValueChanged<double>? onChangeEnd,
  bool enabled = true,
}) {
  return UiStyleRegistry.resolve(designStyle).buildSlider(
    context: context,
    value: value,
    onChanged: onChanged,
    min: min,
    max: max,
    divisions: divisions,
    label: label,
    onChangeEnd: onChangeEnd,
    enabled: enabled,
  );
}

/// Renders an adaptive segmented control
/// (GlassSegmentedControl in Liquid Glass mode, M3EButtonGroup in M3 mode).
Widget adaptiveSegmentedControl({
  required BuildContext context,
  DesignStyle? designStyle,
  required List<SegmentItem> segments,
  required int selectedIndex,
  required ValueChanged<int> onSelected,
  bool connected = true,
}) {
  return UiStyleRegistry.resolve(designStyle).buildSegmentedControl(
    context: context,
    segments: segments,
    selectedIndex: selectedIndex,
    onSelected: onSelected,
    connected: connected,
  );
}

/// Renders an adaptive text input field
/// (GlassTextField in Liquid Glass mode, Material TextField in M3 mode).
Widget adaptiveTextField({
  required BuildContext context,
  DesignStyle? designStyle,
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
  return UiStyleRegistry.resolve(designStyle).buildTextField(
    context: context,
    controller: controller,
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    autofocus: autofocus,
    obscureText: obscureText,
    minLines: minLines,
    maxLines: maxLines,
    maxLength: maxLength,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    enabled: enabled,
  );
}

/// Renders the adaptive bottom-sheet background.
///
/// In M3 mode this returns an opaque surface container with rounded top
/// corners; in Liquid Glass mode it returns a frosted GlassContainer so the
/// ambient mesh shows through.
Widget adaptiveSheetBackground({
  required BuildContext context,
  DesignStyle? designStyle,
  required Widget child,
  double topRadius = 28,
  EdgeInsetsGeometry? padding,
}) {
  return UiStyleRegistry.resolve(designStyle).buildSheetBackground(
    context: context,
    child: child,
    topRadius: topRadius,
    padding: padding,
  );
}
