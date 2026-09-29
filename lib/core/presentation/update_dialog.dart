import 'package:material_ui/material_ui.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/presentation/update/liquid_glass_update_dialog.dart';
import 'package:li_curriculum_table/core/presentation/update/material_update_dialog.dart';
import 'package:li_curriculum_table/core/services/update_service.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';

/// Shows update dialog if [updateInfo] indicates a new version is available.
/// Returns true if an update dialog was shown, false otherwise.
Future<bool> showUpdateDialogIfNeeded(
  BuildContext context,
  UpdateInfo? updateInfo, {
  bool silent = true,
  DesignStyle? designStyle,
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

  final ds = designStyle ?? sl<SettingsController>().state.value.designStyle;
  final concrete = UiStyleRegistry.resolveConcreteStyle(ds);

  await showDialog(
    context: context,
    builder: (_) => concrete == DesignStyle.cupertino
        ? LiquidGlassUpdateDialog(updateInfo: updateInfo)
        : MaterialUpdateDialog(updateInfo: updateInfo),
  );
  return true;
}
