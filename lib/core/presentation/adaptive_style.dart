import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';

/// Resolves design style. Since Cupertino UI has been removed,
/// this always resolves to Material 3.
class AdaptiveStyle {
  const AdaptiveStyle._();

  /// Always returns [DesignStyle.material].
  static DesignStyle resolve([DesignStyle? setting]) => DesignStyle.material;

  /// Always false since the app is unified on Material 3.
  static bool isCupertino([DesignStyle? setting]) => false;
}
