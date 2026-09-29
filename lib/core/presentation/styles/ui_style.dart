import 'package:material_ui/material_ui.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';

/// Single option inside an adaptive segmented control / button group.
///
/// Each entry carries a label plus an optional icon and an opaque value tag.
/// Pass a list of these to [UiStyle.buildSegmentedControl] together with the
/// currently selected index to render either M3E's `M3EButtonGroup` or
/// Liquid Glass's `GlassSegmentedControl`.
class SegmentItem {
  final String label;
  final Widget? icon;
  final Object? value;

  const SegmentItem({required this.label, this.icon, this.value});
}

/// Configuration for a single navigation tab item.
class NavigationItemConfig {
  final String label;
  final Widget icon;
  final Widget? selectedIcon;
  final String? tooltip;

  const NavigationItemConfig({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.tooltip,
  });
}

/// Button visual styles.
enum UiButtonStyle { filled, tonal, outlined, text }

/// Generic dropdown option descriptor.
class DropdownOption<T> {
  final T value;
  final String label;
  final Widget? icon;

  const DropdownOption({required this.value, required this.label, this.icon});
}

/// Abstract contract for design-style icon sets.
///
/// Each concrete design style implements its own icon set (e.g. M3E Icons,
/// Liquid Glass / Cupertino SF Symbols, Fluent Icons, etc.) in a separate file.
abstract class UiStyleIcons {
  IconData get timetable;
  IconData get classroom;
  IconData get grades;
  IconData get exam;
  IconData get book;
  IconData get settings;
  IconData get search;
  IconData get add;
  IconData get refresh;
  IconData get filter;
  IconData get more;
  IconData get clear;
  IconData get arrowForward;
  IconData get arrowBack;
  IconData get check;
  IconData get close;
  IconData get info;
  IconData get palette;
  IconData get themeMode;
  IconData get colorLens;
  IconData get viewWeek;
  IconData get swapHoriz;
  IconData get lan;
  IconData get router;
  IconData get numbers;
  IconData get radar;
  IconData get vpnKey;
  IconData get syncIcon;
  IconData get storage;
  IconData get deleteSweep;
  IconData get lock;
  IconData get feedback;
  IconData get markUnread;
  IconData get visibility;
  IconData get visibilityOff;
  IconData get qrCode;
  IconData get eventNote;
  IconData get school;
  IconData get calendarToday;
  IconData get room;
  IconData get warning;
  IconData get error;
}

/// Abstract contract for UI Design Styles.
///
/// Decouples visual design paradigms (Material 3 Expressive, iOS 26 Liquid Glass,
/// Fluent, Neumorphic, Retro, etc.) into independent, self-contained implementations.
///
/// To add a new design style:
/// 1. Create a new directory under `lib/core/presentation/styles/<new_style>/`.
/// 2. Implement [UiStyle] and [UiStyleIcons].
/// 3. Register the implementation in [UiStyleRegistry].
abstract class UiStyle {
  /// The style enum identifier.
  DesignStyle get style;

  /// The human-readable name of this design style.
  String get name;

  /// Icon set for this design style.
  UiStyleIcons get icons;

  /// Returns the background color for top-level pages.
  ///
  /// For refractive styles like Liquid Glass, this returns transparent so that
  /// ambient lighting mesh and shaders can show through.
  Color pageBackgroundColor(ColorScheme colorScheme);

  /// Whether this style utilizes an ambient dynamic gradient mesh behind scaffolds.
  bool get usesAmbientBackground;

  /// Builds the top-level navigation shell (scaffold, bottom bar / tabs, etc.).
  Widget buildNavigationShell({
    required BuildContext context,
    required Brightness brightness,
    required int currentIndex,
    required ValueChanged<int> onIndexChanged,
    required List<NavigationItemConfig> items,
    required Widget body,
    Widget? actionButton,
  });

  /// Builds a floating / tab auxiliary action button for the navigation shell.
  Widget? buildNavigationActionButton({
    required BuildContext context,
    required Widget icon,
    required String label,
    required VoidCallback? onPressed,
    String? tooltip,
  });

  /// Builds the desktop / window title bar container.
  Widget buildTitleBarContainer({
    required BuildContext context,
    required Widget child,
    double height = 40,
  });

  /// Builds a surface / section card.
  Widget buildCard({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry? padding,
    double borderRadius = 20,
    Color? color,
    VoidCallback? onTap,
    bool isSelected = false,
    Color? accentColor,
  });

  /// Builds an interactive switch.
  Widget buildSwitch({
    required BuildContext context,
    required bool value,
    required ValueChanged<bool>? onChanged,
    Color? activeColor,
  });

  /// Builds a filter / selection chip.
  Widget buildChip({
    required BuildContext context,
    required String label,
    bool selected = false,
    Widget? icon,
    VoidCallback? onTap,
    VoidCallback? onDeleted,
    Color? selectedColor,
  });

  /// Builds an icon button.
  Widget buildIconButton({
    required BuildContext context,
    required Widget icon,
    required VoidCallback? onPressed,
    String? tooltip,
    double size = 36,
  });

  /// Builds a search bar input.
  Widget buildSearchBar({
    required BuildContext context,
    required TextEditingController? controller,
    required String placeholder,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onClear,
    Widget? trailing,
  });

  /// Builds an activity / loading indicator.
  Widget buildActivityIndicator({
    required BuildContext context,
    double size = 20,
    Color? color,
    double strokeWidth = 2,
  });

  /// Builds a linear progress bar / indicator.
  Widget buildLinearProgressIndicator({
    required BuildContext context,
    double? value,
    Color? color,
    Color? backgroundColor,
    double height = 4,
  });

  /// Builds a styled push button.
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
  });

  /// Builds an adaptive dropdown / picker menu.
  Widget buildDropdown<T>({
    required BuildContext context,
    required String hintText,
    required T? value,
    required List<DropdownOption<T>> items,
    required ValueChanged<T> onSelected,
    Widget? prefixIcon,
    double? width,
  });

  /// Builds an adaptive slider (M3ESlider in M3E, GlassSlider in Liquid Glass).
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
  });

  /// Builds an adaptive segmented control (M3EButtonGroup in M3E,
  /// GlassSegmentedControl in Liquid Glass).
  Widget buildSegmentedControl({
    required BuildContext context,
    required List<SegmentItem> segments,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    bool connected = true,
    IconData? iconOverride,
  });

  /// Builds an adaptive text input field (Material `TextField` in M3E,
  /// `GlassTextField` in Liquid Glass).
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
  });

  /// Returns the standard bottom-sheet / dialog surface decoration tokens.
  ///
  /// Used to paint a sheet's background container so that:
  ///   - M3E: solid surface with extra-large top radius.
  ///   - Liquid Glass: transparent so the ambient mesh / blur shows through,
  ///     plus a frosted glass body via [buildCard] wrapping the content.
  ///
  /// [child] is the sheet content; [topRadius] controls the top corners.
  Widget buildSheetBackground({
    required BuildContext context,
    required Widget child,
    double topRadius = 28,
    EdgeInsetsGeometry? padding,
    bool isScrollControlled = true,
    bool useSafeArea = true,
  });

  /// Builds a header bar for page tabs.
  Widget buildHeaderBar({
    required BuildContext context,
    required Widget child,
    double? height,
    EdgeInsetsGeometry? padding,
  });

  /// Shows a notification message (e.g. GlassToast or SnackBar).
  void showMessage(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  });

  /// Shows a confirmation dialog.
  Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = '确认',
    String cancelText = '取消',
    bool isDestructive = false,
  });

  /// Shows a text input dialog.
  Future<String?> showInputDialog(
    BuildContext context, {
    required String title,
    String? placeholder,
    String? initialValue,
    TextInputType? keyboardType,
    String confirmText = '确定',
    String cancelText = '取消',
  });

  /// Asynchronously initializes any runtime resources (e.g. shaders, fonts) needed by this style.
  Future<void> initialize() async {}

  /// Wraps the root [MaterialApp] with top-level styling or theme providers if needed.
  Widget wrapApp({
    required Widget child,
    required ColorScheme lightScheme,
    required ColorScheme darkScheme,
    required bool isDark,
  }) => child;

  /// Wraps inner content inside [MaterialApp.builder] with style-specific inherited widgets.
  Widget wrapContent({
    required BuildContext context,
    required Widget child,
    required bool isDark,
    required ColorScheme colorScheme,
  }) => child;
}
