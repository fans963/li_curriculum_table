import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';

/// Resolves the effective [DesignStyle] at runtime.
///
/// When the user picks [DesignStyle.system], this delegates to
/// [UiStyleRegistry.resolveConcreteStyle] to determine the active style.
class AdaptiveStyle {
  const AdaptiveStyle._();

  /// Returns the concrete style for the given [setting].
  static DesignStyle resolve([DesignStyle? setting]) =>
      UiStyleRegistry.resolveConcreteStyle(setting);

  /// Convenience: `true` when the resolved style is iOS 26 Liquid Glass.
  static bool isCupertino([DesignStyle? setting]) =>
      resolve(setting) == DesignStyle.cupertino;

  /// Alias for clarity: `true` when the resolved style is Liquid Glass.
  static bool isLiquidGlass([DesignStyle? setting]) => isCupertino(setting);
}
