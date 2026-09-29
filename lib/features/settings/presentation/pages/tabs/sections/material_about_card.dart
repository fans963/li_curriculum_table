import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/settings/presentation/pages/tabs/sections/liquid_glass_about_card.dart';
import 'package:li_curriculum_table/features/settings/presentation/pages/tabs/sections/m3e_about_card.dart';

export 'liquid_glass_about_card.dart';
export 'm3e_about_card.dart';

/// Adaptive "关于" card delegating to M3E or Liquid Glass.
class AboutCard extends StatelessWidget {
  final DesignStyle? designStyle;
  const AboutCard({super.key, this.designStyle});

  @override
  Widget build(BuildContext context) {
    final ds = designStyle ?? sl<SettingsController>().state.value.designStyle;
    final concrete = UiStyleRegistry.resolveConcreteStyle(ds);

    if (concrete == DesignStyle.cupertino) {
      return const LiquidGlassAboutCard();
    }
    return M3EAboutCard();
  }
}

/// Backward compatibility alias.
typedef MaterialAboutCard = AboutCard;
