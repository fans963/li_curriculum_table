import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';

/// Shows a message via standard SnackBar.
void showAdaptiveMessage(
  BuildContext context, {
  DesignStyle? designStyle,
  required String message,
  Duration duration = const Duration(seconds: 2),
}) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message), duration: duration));
}

/// Returns a Material 3 Expressive loading indicator.
Widget adaptiveActivityIndicator({
  DesignStyle? designStyle,
  double size = 20,
  Color? color,
  double strokeWidth = 2,
}) {
  return M3ELoadingIndicator(
    constraints: BoxConstraints.tight(Size(size, size)),
    color: color,
  );
}

/// Shows a Material 3 Expressive confirmation dialog.
Future<bool> showAdaptiveConfirmDialog(
  BuildContext context, {
  DesignStyle? designStyle,
  required String title,
  required String content,
  String confirmText = '确认',
  String cancelText = '取消',
  bool isDestructive = false,
}) async {
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

/// Shows a Material input dialog (for entering a value like a port number).
Future<String?> showAdaptiveInputDialog(
  BuildContext context, {
  DesignStyle? designStyle,
  required String title,
  String? placeholder,
  String? initialValue,
  TextInputType keyboardType = TextInputType.text,
  String confirmText = '保存',
  String cancelText = '取消',
}) async {
  final controller = TextEditingController(text: initialValue);

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
