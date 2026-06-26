import 'package:cupertino_liquid_glass/cupertino_liquid_glass.dart';
import 'package:flutter/cupertino.dart';

/// A zero-overhead wrapper that flattens the 4-layer
/// `Container(shadow) → ClipRRect → CupertinoLiquidGlass → Container(bg+border)`
/// nesting pattern into a single semantic widget.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double shadowAlpha;
  final double tintOpacity;
  final Offset shadowOffset;
  final double shadowBlurRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0.5,
    this.shadowAlpha = 0.05,
    this.tintOpacity = 0.1,
    this.shadowOffset = const Offset(0, 4),
    this.shadowBlurRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: shadowAlpha),
            blurRadius: shadowBlurRadius,
            offset: shadowOffset,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CupertinoLiquidGlass(
          tintOpacity: tintOpacity,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: borderColor != null
                  ? Border.all(color: borderColor!, width: borderWidth)
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
