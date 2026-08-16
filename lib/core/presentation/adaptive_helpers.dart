import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_3_expressive/components/buttons/enums/m3e_button_enums.dart';
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
      builder: (overlayContext) => Positioned(
        left: 16,
        right: 16,
        bottom: 24 + MediaQuery.of(overlayContext).padding.bottom,
        child: IgnorePointer(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.secondarySystemGroupedBackground
                  .resolveFrom(overlayContext)
                  .withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: CupertinoColors.separator
                    .resolveFrom(overlayContext)
                    .withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
                color: CupertinoColors.label.resolveFrom(overlayContext),
              ),
            ),
          ),
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
  return M3ELoadingIndicator(
    constraints: BoxConstraints.tight(Size(size, size)),
    color: color,
  );
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
          M3EButton.text(
            onPressed: () => Navigator.pop(ctx, false),
            size: M3EButtonSize.md,
            shape: M3EButtonShape.round,
            child: Text(cancelText),
          ),
          if (isDestructive)
            M3EButton.filled(
              onPressed: () => Navigator.pop(ctx, true),
              size: M3EButtonSize.md,
              shape: M3EButtonShape.round,
              decoration: M3EButtonDecoration.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: Text(confirmText),
            )
          else
            M3EButton.filled(
              onPressed: () => Navigator.pop(ctx, true),
              size: M3EButtonSize.md,
              shape: M3EButtonShape.round,
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
          M3EButton.text(
            onPressed: () => Navigator.pop(ctx),
            size: M3EButtonSize.md,
            shape: M3EButtonShape.round,
            child: Text(cancelText),
          ),
          M3EButton.filled(
            onPressed: () => Navigator.pop(ctx, controller.text),
            size: M3EButtonSize.md,
            shape: M3EButtonShape.round,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}
