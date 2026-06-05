import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';

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
