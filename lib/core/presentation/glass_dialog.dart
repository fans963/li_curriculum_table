import 'package:flutter/cupertino.dart';

/// A zero-overhead wrapper that flattens the 8-layer Cupertino detail dialog
/// `Center → ConstrainedBox → DefaultTextStyle → Padding → Container(shadow) →
///  ClipRRect → CupertinoLiquidGlass → Container(bg+border)` pattern
/// into a single semantic widget.
class GlassDialog extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final double borderRadius;
  final EdgeInsets margin;

  const GlassDialog({
    super.key,
    required this.child,
    this.maxWidth = 400,
    this.borderRadius = 24,
    this.margin = const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = CupertinoTheme.of(context).textTheme.textStyle.copyWith(
      decoration: TextDecoration.none,
      color: CupertinoColors.label.resolveFrom(context),
    );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DefaultTextStyle(
          style: textStyle,
          child: Padding(
            padding: margin,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: CupertinoColors.secondarySystemGroupedBackground
                      .resolveFrom(context),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: CupertinoColors.separator
                        .resolveFrom(context)
                        .withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
