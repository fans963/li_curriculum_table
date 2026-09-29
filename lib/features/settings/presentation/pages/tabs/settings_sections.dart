import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:material_ui/material_ui.dart';

export 'sections/theme_settings_section.dart';
export 'sections/timetable_display_settings_section.dart';
export 'sections/proxy_settings_section.dart';

const sectionSpacing = 12.0;
const cardPadding = EdgeInsets.all(16);

// ═══════════════════════════════════════════════════════════════════════════
// Shared Components — adapted per DesignStyle
// ═══════════════════════════════════════════════════════════════════════════

class SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;
  final DesignStyle? designStyle;

  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
    this.designStyle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ds = designStyle ?? sl<SettingsController>().designStyle.value;
    final style = UiStyleRegistry.resolve(ds);
    final isLiquidGlass =
        ds == DesignStyle.cupertino ||
        (ds == DesignStyle.system && style.usesAmbientBackground);

    // Icon badge shape adapts per platform:
    // M3E → rounded rect (12dp), Liquid Glass → continuous superellipse.
    final iconBadge = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isLiquidGlass
            ? cs.primary.withValues(alpha: 0.12)
            : cs.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(isLiquidGlass ? 10 : 12),
      ),
      child: Icon(icon, size: 20, color: cs.primary),
    );

    final header = Row(
      children: [
        iconBadge,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    // M3E uses extraLarge (28dp) for section cards; Liquid Glass uses 20dp superellipse.
    final radius = isLiquidGlass ? 20.0 : 28.0;

    return style.buildCard(
      context: context,
      borderRadius: radius,
      padding: isLiquidGlass ? const EdgeInsets.all(20) : cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [header, const SizedBox(height: 16), child],
      ),
    );
  }
}

/// A clickable settings row with optional trailing widget.
///
/// Adapts InkWell border radius per the active design style.
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final tile = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor ?? cs.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: tt.bodyMedium),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
        ],
      ),
    );

    if (onTap != null && trailing == null) {
      final ds = sl<SettingsController>().designStyle.value;
      if (UiStyleRegistry.resolveConcreteStyle(ds) == DesignStyle.cupertino) {
        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: tile,
        );
      }
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: tile,
      );
    }
    return tile;
  }
}
