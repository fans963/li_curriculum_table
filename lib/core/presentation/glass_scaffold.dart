import 'package:cupertino_liquid_glass/cupertino_liquid_glass.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;

/// A zero-overhead scaffold that flattens the 7-layer
/// `CupertinoPageScaffold → Stack → Positioned.fill(ColoredBox(CustomScrollView))
///   + Positioned(IgnorePointer(CupertinoLiquidGlass(navbar)))`
/// nesting pattern shared across 5 Cupertino pages.
class GlassScaffold extends StatelessWidget {
  final String title;
  final List<Widget> slivers;
  final List<Widget>? trailingActions;

  const GlassScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.trailingActions,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: CupertinoColors.systemGroupedBackground
                  .resolveFrom(context),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(height: topPadding + 44),
                  ),
                  ...slivers,
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: topPadding + 44,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CupertinoLiquidGlass(
                        tintOpacity: 0.15,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  Positioned(
                    top: topPadding,
                    left: 16,
                    right: trailingActions != null ? 56 : 16,
                    child: SizedBox(
                      height: 44,
                      child: Center(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.41,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (trailingActions != null)
                    Positioned(
                      top: topPadding,
                      right: 8,
                      child: SizedBox(
                        height: 44,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: trailingActions!,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
