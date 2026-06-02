import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';

/// Shows an adaptive message — SnackBar (Material) or CupertinoAlertDialog (Cupertino).
void showAdaptiveMessage(
  BuildContext context, {
  required DesignStyle designStyle,
  required String message,
  Duration duration = const Duration(seconds: 2),
}) {
  if (AdaptiveStyle.isCupertino(designStyle)) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Center(
        child: CupertinoAlertDialog(
          content: Text(message, style: const TextStyle(fontSize: 13)),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('好的'),
              onPressed: () => entry.remove(),
            ),
          ],
        ),
      ),
    );
    Overlay.of(context).insert(entry);
    Future.delayed(duration, () {
      if (entry.mounted) entry.remove();
    });
  } else {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message), duration: duration));
  }
}

/// Returns an adaptive loading indicator.
Widget adaptiveActivityIndicator({
  required DesignStyle designStyle,
  double size = 20,
  Color? color,
  double strokeWidth = 2,
}) {
  if (AdaptiveStyle.isCupertino(designStyle)) {
    return CupertinoActivityIndicator(radius: size / 2, color: color);
  }
  return SizedBox(
    width: size,
    height: size,
    child: CircularProgressIndicator(strokeWidth: strokeWidth, color: color),
  );
}

/// Returns an adaptive progress indicator (indeterminate).
Widget adaptiveProgressIndicator({
  required DesignStyle designStyle,
  Color? color,
  double? minHeight,
}) {
  if (AdaptiveStyle.isCupertino(designStyle)) {
    return CupertinoActivityIndicator(color: color);
  }
  return LinearProgressIndicator(color: color, minHeight: minHeight ?? 4);
}

/// Shows an adaptive confirmation dialog.
Future<bool> showAdaptiveConfirmDialog(
  BuildContext context, {
  required DesignStyle designStyle,
  required String title,
  required String content,
  String confirmText = '确认',
  String cancelText = '取消',
  bool isDestructive = false,
}) async {
  if (AdaptiveStyle.isCupertino(designStyle)) {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content, style: const TextStyle(fontSize: 13)),
        actions: [
          CupertinoDialogAction(
            child: Text(cancelText),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: isDestructive,
            isDefaultAction: !isDestructive,
            child: Text(confirmText),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    return result ?? false;
  } else {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelText),
          ),
          FilledButton(
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

/// Shows an adaptive input dialog (for entering a value like a port number).
Future<String?> showAdaptiveInputDialog(
  BuildContext context, {
  required DesignStyle designStyle,
  required String title,
  String? placeholder,
  String? initialValue,
  TextInputType keyboardType = TextInputType.text,
  String confirmText = '保存',
  String cancelText = '取消',
}) async {
  final controller = TextEditingController(text: initialValue);

  if (AdaptiveStyle.isCupertino(designStyle)) {
    return showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            keyboardType: keyboardType,
            placeholder: placeholder,
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(cancelText),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(confirmText),
            onPressed: () => Navigator.pop(ctx, controller.text),
          ),
        ],
      ),
    );
  } else {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: placeholder),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}

/// Returns adaptive background colors following iOS/Material conventions.
class AdaptiveColors {
  const AdaptiveColors._();

  /// Main scaffold background.
  static Color scaffoldBackground(BuildContext context, DesignStyle style) {
    if (AdaptiveStyle.isCupertino(style)) {
      return CupertinoColors.systemGroupedBackground.resolveFrom(context);
    }
    return Theme.of(context).colorScheme.surface;
  }

  /// Card / section background.
  static Color cardBackground(BuildContext context, DesignStyle style) {
    if (AdaptiveStyle.isCupertino(style)) {
      return CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
    }
    return Theme.of(context).colorScheme.surfaceContainerLow;
  }

  /// Primary text color.
  static Color primaryText(BuildContext context, DesignStyle style) {
    if (AdaptiveStyle.isCupertino(style)) {
      return CupertinoColors.label.resolveFrom(context);
    }
    return Theme.of(context).colorScheme.onSurface;
  }

  /// Secondary text color.
  static Color secondaryText(BuildContext context, DesignStyle style) {
    if (AdaptiveStyle.isCupertino(style)) {
      return CupertinoColors.secondaryLabel.resolveFrom(context);
    }
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  /// Tint / accent color.
  static Color tint(BuildContext context, DesignStyle style) {
    if (AdaptiveStyle.isCupertino(style)) {
      return CupertinoColors.systemBlue.resolveFrom(context);
    }
    return Theme.of(context).colorScheme.primary;
  }

  /// Destructive color.
  static Color destructive(BuildContext context, DesignStyle style) {
    if (AdaptiveStyle.isCupertino(style)) {
      return CupertinoColors.systemRed.resolveFrom(context);
    }
    return Theme.of(context).colorScheme.error;
  }

  /// Separator / divider color.
  static Color separator(BuildContext context, DesignStyle style) {
    if (AdaptiveStyle.isCupertino(style)) {
      return CupertinoColors.separator.resolveFrom(context);
    }
    return Theme.of(context).colorScheme.outlineVariant;
  }
}

/// Returns adaptive border radius following iOS/Material conventions.
class AdaptiveRadius {
  const AdaptiveRadius._();

  /// Card corner radius. iOS: 12pt, Material: 16pt.
  static double card(DesignStyle style) =>
      AdaptiveStyle.isCupertino(style) ? 12 : 16;

  /// Dialog corner radius. iOS: 14pt, Material: 16pt.
  static double dialog(DesignStyle style) =>
      AdaptiveStyle.isCupertino(style) ? 14 : 16;

  /// Search bar corner radius. iOS: 10pt, Material: 12pt.
  static double searchBar(DesignStyle style) =>
      AdaptiveStyle.isCupertino(style) ? 10 : 12;

  /// Button corner radius. iOS: 8pt, Material: 16pt.
  static double button(DesignStyle style) =>
      AdaptiveStyle.isCupertino(style) ? 8 : 16;
}
