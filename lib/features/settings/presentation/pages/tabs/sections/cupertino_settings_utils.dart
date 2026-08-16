import 'package:material_ui/material_ui.dart' show ThemeMode;

String statusText(dynamic state) {
  if (state.isLoading) return '正在同步...';
  if (state.data != null) return '已同步';
  return '未同步';
}

String themeModeLabel(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return '跟随系统';
    case ThemeMode.light:
      return '浅色';
    case ThemeMode.dark:
      return '深色';
  }
}
