import 'package:flutter/foundation.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';

/// Resolves the effective [DesignStyle] at runtime.
///
/// When the user picks [DesignStyle.system], this returns
/// [DesignStyle.cupertino] on iOS/macOS and [DesignStyle.material] everywhere else.
class AdaptiveStyle {
  const AdaptiveStyle._();

  /// Returns the concrete style for the given [setting].
  static DesignStyle resolve(DesignStyle setting) {
    if (setting != DesignStyle.system) return setting;
    return defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS
        ? DesignStyle.cupertino
        : DesignStyle.material;
  }

  /// Convenience: `true` when the resolved style is Cupertino.
  static bool isCupertino(DesignStyle setting) =>
      resolve(setting) == DesignStyle.cupertino;
}
