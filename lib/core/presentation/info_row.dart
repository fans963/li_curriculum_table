import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isMonospace;
  final int maxLines;
  final DesignStyle ds;
  final Color? iconColor;

  const InfoRow({
    super.key,
    required this.icon,
    required this.text,
    required this.ds,
    this.isMonospace = false,
    this.maxLines = 1,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    if (ds == DesignStyle.cupertino) {
      final cs = Theme.of(context).colorScheme;
      final tt = Theme.of(context).textTheme;
      return Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: iconColor ?? cs.onSurfaceVariant.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                fontFamily: isMonospace ? 'monospace' : null,
                fontWeight: isMonospace ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      );
    } else {
      final cs = Theme.of(context).colorScheme;
      final tt = Theme.of(context).textTheme;
      return Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: iconColor ?? cs.primary.withValues(alpha: 0.8)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.3,
                fontFamily: isMonospace ? 'monospace' : null,
                fontWeight: isMonospace ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      );
    }
  }
}
