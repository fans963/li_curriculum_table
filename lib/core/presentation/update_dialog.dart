import 'package:material_ui/material_ui.dart';
import 'package:li_curriculum_table/core/services/update_service.dart';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('检查更新失败，请稍后重试')));
    }
    return false;
  }
  if (!updateInfo.hasUpdate) {
    if (!silent && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前已是最新版本 ✨')));
    }
    return false;
  }

  if (!context.mounted) return false;

  await showDialog(
    context: context,
    builder: (_) => MaterialUpdateDialog(updateInfo: updateInfo),
  );
  return true;
}
