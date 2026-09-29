import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';

class TermsSectionItem {
  final IconData icon;
  final String title;
  final String body;

  const TermsSectionItem({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class LiquidGlassTermsDialog extends StatelessWidget {
  final String title;
  final List<TermsSectionItem> sections;
  final String footer;

  const LiquidGlassTermsDialog({
    super.key,
    required this.title,
    required this.sections,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: GlassContainer(
        shape: const LiquidRoundedSuperellipse(borderRadius: 32),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: cs.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Scrollable body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < sections.length; i++) ...[
                        _buildSectionRow(context, sections[i], isDark, cs, tt),
                        if (i < sections.length - 1) const SizedBox(height: 14),
                      ],
                      const SizedBox(height: 16),
                      GlassContainer(
                        shape: const LiquidRoundedSuperellipse(
                          borderRadius: 16,
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          footer,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: adaptiveButton(
                      context: context,
                      designStyle: DesignStyle.cupertino,
                      style: UiButtonStyle.text,
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('不同意'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: adaptiveButton(
                      context: context,
                      designStyle: DesignStyle.cupertino,
                      style: UiButtonStyle.filled,
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('同意并继续'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionRow(
    BuildContext context,
    TermsSectionItem section,
    bool isDark,
    ColorScheme cs,
    TextTheme tt,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: isDark ? 0.3 : 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(section.icon, size: 18, color: cs.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                section.body,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
