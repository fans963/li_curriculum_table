import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/core/services/update_service.dart';
import 'package:li_curriculum_table/core/presentation/update/cupertino_update_dialog.dart';
import 'package:li_curriculum_table/core/presentation/update/material_update_dialog.dart';

/// Shows update dialog if [updateInfo] indicates a new version is available.
/// Returns true if an update dialog was shown, false otherwise.
Future<bool> showUpdateDialogIfNeeded(
  BuildContext context,
  UpdateInfo? updateInfo, {
  bool silent = true,
}) async {
  if (updateInfo == null) {
    if (!silent && context.mounted) {
      final ds = sl<SettingsController>().designStyle.value;
      if (AdaptiveStyle.isCupertino(ds)) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            content: const Text('检查更新失败，请稍后重试'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('好的'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('检查更新失败，请稍后重试')));
      }
    }
    return false;
  }
  if (!updateInfo.hasUpdate) {
    if (!silent && context.mounted) {
      final ds = sl<SettingsController>().designStyle.value;
      if (AdaptiveStyle.isCupertino(ds)) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            content: const Text('当前已是最新版本 ✨'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('好的'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('当前已是最新版本 ✨')));
      }
    }
    return false;
  }

  if (!context.mounted) return false;

  final ds = sl<SettingsController>().designStyle.value;
  if (AdaptiveStyle.isCupertino(ds)) {
    await showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoUpdateDialog(updateInfo: updateInfo),
    );
  } else {
    await showDialog(
      context: context,
      builder: (_) => MaterialUpdateDialog(updateInfo: updateInfo),
    );
  }
  return true;
}
