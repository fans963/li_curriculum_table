import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';

/// A widget that builds either a Material or Cupertino child
/// based on the resolved [DesignStyle].
class AdaptiveBuilder extends StatelessWidget {
  final DesignStyle designStyle;
  final Widget Function(BuildContext context) material;
  final Widget Function(BuildContext context) cupertino;

  const AdaptiveBuilder({
    super.key,
    required this.designStyle,
    required this.material,
    required this.cupertino,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveStyle.isCupertino(designStyle)
        ? cupertino(context)
        : material(context);
  }
}

// ─── Scaffold ────────────────────────────────────────────────────────────────

/// Wraps [Scaffold] (Material) / [CupertinoPageScaffold] (Cupertino).
class AdaptiveScaffold extends StatelessWidget {
  final DesignStyle designStyle;
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;

  const AdaptiveScaffold({
    super.key,
    required this.designStyle,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
  });

  @override
  Widget build(BuildContext context) {
    if (AdaptiveStyle.isCupertino(designStyle)) {
      return CupertinoPageScaffold(
        navigationBar: appBar is AdaptiveAppBar
            ? (appBar as AdaptiveAppBar).asCupertinoNavigationBar(context)
            : null,
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset ?? true,
        child: _ScaffoldBody(
          hasAppBar: appBar != null,
          isCupertino: true,
          child: body ?? const SizedBox.shrink(),
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}

/// Internal widget that adds top padding for Cupertino nav bars.
class _ScaffoldBody extends StatelessWidget {
  final Widget child;
  final bool hasAppBar;
  final bool isCupertino;

  const _ScaffoldBody({
    required this.child,
    required this.hasAppBar,
    required this.isCupertino,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCupertino || !hasAppBar) return child;
    // CupertinoNavigationBar height (44pt) + status bar
    final topPadding =
        MediaQuery.of(context).padding.top + kMinInteractiveDimensionCupertino;
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: child,
    );
  }
}

// ─── AppBar ──────────────────────────────────────────────────────────────────

/// Wraps [AppBar] (Material) / [CupertinoNavigationBar] (Cupertino).
///
/// Use as the `appBar` parameter of [AdaptiveScaffold].
/// For Material, this IS a [PreferredSizeWidget].
/// For Cupertino, extract via [asCupertinoNavigationBar].
class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final DesignStyle designStyle;
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool? centerTitle;
  final Color? backgroundColor;
  final double? elevation;

  const AdaptiveAppBar({
    super.key,
    required this.designStyle,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle,
    this.backgroundColor,
    this.elevation,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  /// Returns a [CupertinoNavigationBar] for use in [CupertinoPageScaffold].
  CupertinoNavigationBar asCupertinoNavigationBar(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return CupertinoNavigationBar(
      middle: title,
      leading: leading,
      trailing: actions != null && actions!.isNotEmpty
          ? Row(mainAxisSize: MainAxisSize.min, children: actions!)
          : null,
      backgroundColor: backgroundColor ?? theme.barBackgroundColor,
      border: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (AdaptiveStyle.isCupertino(designStyle)) {
      // When used standalone (not in AdaptiveScaffold), render as a sized box
      // since CupertinoNavigationBar is typically in CupertinoPageScaffold.
      return const SizedBox.shrink();
    }
    return AppBar(
      title: title,
      leading: leading,
      actions: actions,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      elevation: elevation,
      scrolledUnderElevation: 0,
    );
  }
}

// ─── Navigation Bar ─────────────────────────────────────────────────────────

/// Wraps [NavigationBar] (Material) / [CupertinoTabBar] (Cupertino).
class AdaptiveNavigationBar extends StatelessWidget {
  final DesignStyle designStyle;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  const AdaptiveNavigationBar({
    super.key,
    required this.designStyle,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    if (AdaptiveStyle.isCupertino(designStyle)) {
      return CupertinoTabBar(
        currentIndex: selectedIndex,
        onTap: onDestinationSelected,
        items: destinations.map((d) {
          return BottomNavigationBarItem(
            icon: d.icon,
            activeIcon: d.selectedIcon ?? d.icon,
            label: d.label,
          );
        }).toList(),
      );
    }
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: destinations,
    );
  }
}

// ─── Dialog ──────────────────────────────────────────────────────────────────

/// Shows an adaptive dialog (Material or Cupertino).
Future<T?> showAdaptiveDialog<T>({
  required BuildContext context,
  required DesignStyle designStyle,
  required String title,
  required String content,
  List<AdaptiveDialogAction>? actions,
  bool barrierDismissible = true,
}) {
  if (AdaptiveStyle.isCupertino(designStyle)) {
    return showCupertinoDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: (actions ?? []).map((a) {
          return CupertinoDialogAction(
            isDefaultAction: a.isDefault,
            isDestructiveAction: a.isDestructive,
            onPressed: () => Navigator.pop(context, a.result),
            child: Text(a.label),
          );
        }).toList(),
      ),
    );
  }

  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: (actions ?? []).map((a) {
        if (a.isDestructive) {
          return FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, a.result),
            child: Text(a.label),
          );
        }
        if (a.isDefault) {
          return FilledButton(
            onPressed: () => Navigator.pop(context, a.result),
            child: Text(a.label),
          );
        }
        return TextButton(
          onPressed: () => Navigator.pop(context, a.result),
          child: Text(a.label),
        );
      }).toList(),
    ),
  );
}

class AdaptiveDialogAction {
  final String label;
  final dynamic result;
  final bool isDefault;
  final bool isDestructive;

  const AdaptiveDialogAction({
    required this.label,
    this.result,
    this.isDefault = false,
    this.isDestructive = false,
  });
}

// ─── Switch ──────────────────────────────────────────────────────────────────

/// Wraps [Switch] (Material) / [CupertinoSwitch] (Cupertino).
class AdaptiveSwitch extends StatelessWidget {
  final DesignStyle designStyle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AdaptiveSwitch({
    super.key,
    required this.designStyle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (AdaptiveStyle.isCupertino(designStyle)) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
      );
    }
    return Switch(
      value: value,
      onChanged: onChanged,
    );
  }
}

// ─── Button ──────────────────────────────────────────────────────────────────

/// Wraps [FilledButton] / [ElevatedButton] (Material) / [CupertinoButton.filled] (Cupertino).
class AdaptiveButton extends StatelessWidget {
  final DesignStyle designStyle;
  final VoidCallback? onPressed;
  final Widget child;
  final bool filled;

  const AdaptiveButton({
    super.key,
    required this.designStyle,
    required this.onPressed,
    required this.child,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (AdaptiveStyle.isCupertino(designStyle)) {
      if (filled) {
        return CupertinoButton.filled(
          onPressed: onPressed,
          child: child,
        );
      }
      return CupertinoButton(
        onPressed: onPressed,
        child: child,
      );
    }
    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        child: child,
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      child: child,
    );
  }
}

// ─── Bottom Sheet ────────────────────────────────────────────────────────────

/// Shows an adaptive bottom sheet.
Future<T?> showAdaptiveBottomSheet<T>({
  required BuildContext context,
  required DesignStyle designStyle,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  Color? backgroundColor,
}) {
  if (AdaptiveStyle.isCupertino(designStyle)) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: backgroundColor ?? CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: CupertinoColors.separator.resolveFrom(context),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Flexible(child: builder(context)),
          ],
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: builder,
  );
}

// ─── Adaptive Page ───────────────────────────────────────────────────────────

/// Wraps a Material [Scaffold] + [AppBar] into a Cupertino equivalent
/// when the resolved style is Cupertino.
///
/// Use this as a drop-in replacement for `Scaffold(appBar: AppBar(...))`.
/// The [materialScaffold] must contain a [Scaffold] with an [AppBar].
class AdaptivePage extends StatelessWidget {
  final DesignStyle designStyle;
  final Widget materialScaffold;

  /// The title for the Cupertino navigation bar (only used in Cupertino mode).
  final Widget? cupertinoTitle;

  /// Actions for the Cupertino navigation bar (only used in Cupertino mode).
  final List<Widget>? cupertinoActions;

  /// The body content (shared between both modes).
  final Widget? body;

  /// Whether to apply top padding for the Cupertino nav bar. Defaults to true.
  final bool applyCupertinoTopPadding;

  const AdaptivePage({
    super.key,
    required this.designStyle,
    required this.materialScaffold,
    this.cupertinoTitle,
    this.cupertinoActions,
    this.body,
    this.applyCupertinoTopPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!AdaptiveStyle.isCupertino(designStyle)) {
      return materialScaffold;
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: cupertinoTitle,
        trailing: cupertinoActions != null && cupertinoActions!.isNotEmpty
            ? Row(mainAxisSize: MainAxisSize.min, children: cupertinoActions!)
            : null,
        border: null,
      ),
      child: applyCupertinoTopPadding
          ? SafeArea(
              top: true, // only pad for the nav bar
              bottom: false,
              child: body ?? const SizedBox.shrink(),
            )
          : (body ?? const SizedBox.shrink()),
    );
  }
}

/// Wraps an [AppBar] so its title/actions can be extracted for Cupertino.
class AppBarAdapter extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final bool? centerTitle;
  final Color? backgroundColor;
  final double? elevation;
  final Widget? bottom;

  const AppBarAdapter({
    super.key,
    this.title,
    this.actions,
    this.centerTitle,
    this.backgroundColor,
    this.elevation,
    this.bottom,
  });

  @override
  Size get preferredSize {
    final bottomHeight = (bottom is PreferredSizeWidget)
        ? (bottom as PreferredSizeWidget).preferredSize.height
        : 0.0;
    return Size.fromHeight(56 + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      elevation: elevation,
      scrolledUnderElevation: 0,
      bottom: bottom is PreferredSizeWidget
          ? bottom as PreferredSizeWidget
          : null,
    );
  }
}

// ─── Loading Indicator ───────────────────────────────────────────────────────

/// Wraps [CircularProgressIndicator] (Material) / [CupertinoActivityIndicator] (Cupertino).
class AdaptiveActivityIndicator extends StatelessWidget {
  final DesignStyle designStyle;
  final double? size;
  final Color? color;

  const AdaptiveActivityIndicator({
    super.key,
    required this.designStyle,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (AdaptiveStyle.isCupertino(designStyle)) {
      return CupertinoActivityIndicator(
        radius: (size ?? 20) / 2,
        color: color,
      );
    }
    return SizedBox(
      width: size ?? 20,
      height: size ?? 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: color,
      ),
    );
  }
}

// ─── List Tile ───────────────────────────────────────────────────────────────

/// Wraps [ListTile] (Material) / [CupertinoListTile] (Cupertino).
class AdaptiveListTile extends StatelessWidget {
  final DesignStyle designStyle;
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AdaptiveListTile({
    super.key,
    required this.designStyle,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (AdaptiveStyle.isCupertino(designStyle)) {
      return CupertinoListTile(
        leading: leading,
        title: title ?? const SizedBox.shrink(),
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
      );
    }
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
