import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/settings/presentation/pages/tabs/sections/liquid_glass_web_download_card.dart';
import 'package:li_curriculum_table/features/settings/presentation/pages/tabs/sections/m3e_web_download_card.dart';

export 'liquid_glass_web_download_card.dart';
export 'm3e_web_download_card.dart';

/// Adaptive web download card delegating to M3E or Liquid Glass.
class WebDownloadCard extends StatelessWidget {
  final DesignStyle? designStyle;
  const WebDownloadCard({super.key, this.designStyle});

  @override
  Widget build(BuildContext context) {
    final ds =
        designStyle ?? sl<SettingsController>().state.value.designStyle;
    final concrete = UiStyleRegistry.resolveConcreteStyle(ds);

    if (concrete == DesignStyle.cupertino) {
      return const LiquidGlassWebDownloadCard();
    }
    return const M3EWebDownloadCard();
  }
}

/// Backward compatibility alias.
typedef MaterialWebDownloadCard = WebDownloadCard;
