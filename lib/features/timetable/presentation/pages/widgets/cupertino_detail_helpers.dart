import 'package:cupertino_ui/cupertino_ui.dart';

/// iOS-style details card container with rounded corners and subtle border.
Widget buildIOSDetailsCard(
  BuildContext context, {
  required List<Widget> children,
}) {
  return Container(
    decoration: BoxDecoration(
      color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
        context,
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: CupertinoColors.separator
            .resolveFrom(context)
            .withValues(alpha: 0.2),
        width: 0.5,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

/// iOS-style divider with left padding for use inside detail cards.
Widget buildIOSDivider(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(left: 62),
    child: Container(
      height: 0.5,
      color: CupertinoColors.separator
          .resolveFrom(context)
          .withValues(alpha: 0.3),
    ),
  );
}

/// Cupertino-style info row with icon, label, and value.
Widget buildCupertinoInfoRow(
  BuildContext context, {
  required IconData icon,
  required String label,
  required String value,
  required Color iconColor,
  required Color secondaryColor,
}) {
  if (value.trim().isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
