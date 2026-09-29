import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/styles/ui_style.dart';
import 'package:li_curriculum_table/core/presentation/styles/material_3/m3e_style.dart';
import 'package:li_curriculum_table/core/presentation/styles/liquid_glass/liquid_glass_style.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';

/// Registry that maps [DesignStyle] to its concrete [UiStyle] implementation.
///
/// Decouples styles so that new design paradigms (e.g. Fluent, Cyberpunk, Retro)
/// can be added simply by implementing [UiStyle] and registering it here.
class UiStyleRegistry {
  UiStyleRegistry._();

  static final Map<DesignStyle, UiStyle> _registry = {
    DesignStyle.material: const Material3ExpressiveStyle(),
    DesignStyle.cupertino: const LiquidGlassStyle(),
  };

  /// Register a new design style implementation.
  static void register(DesignStyle style, UiStyle implementation) {
    _registry[style] = implementation;
  }

  /// Initializes runtime resources for all registered styles.
  static Future<void> initializeAll() async {
    for (final style in _registry.values) {
      await style.initialize();
    }
  }

  /// Resolves the concrete [UiStyle] for the given [DesignStyle] setting.
  ///
  /// If [style] is null or [DesignStyle.system], it automatically follows the
  /// platform default: iOS/macOS -> Liquid Glass, others -> Material 3 Expressive.
  static UiStyle resolve([DesignStyle? style]) {
    final concrete = resolveConcreteStyle(style);
    return _registry[concrete] ?? const Material3ExpressiveStyle();
  }

  /// Resolves the concrete enum value (excluding [DesignStyle.system]).
  static DesignStyle resolveConcreteStyle([DesignStyle? setting]) {
    final style = setting ?? sl<SettingsController>().designStyle.value;
    if (style != DesignStyle.system) return style;
    return defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS
        ? DesignStyle.cupertino
        : DesignStyle.material;
  }

  /// Current active [UiStyle] resolved from user settings.
  static UiStyle get current => resolve();
}

/// Extension on [BuildContext] for ergonomic access to the active [UiStyle].
extension UiStyleContextExtension on BuildContext {
  /// The active [UiStyle] for the current app context.
  UiStyle get uiStyle => UiStyleRegistry.current;

  /// The active icon set for the current app context.
  UiStyleIcons get uiIcons => UiStyleRegistry.current.icons;
}
