import 'package:flutter/material.dart';

/// Paints a dashed rounded-rectangle border.
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double borderRadius;

  const DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    canvas.drawPath(dashPath(path, dashWidth: 6, dashGap: 3), paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) => false;
}

/// Creates a dashed version of [source].
Path dashPath(
  Path source, {
  required double dashWidth,
  required double dashGap,
}) {
  final dest = Path();
  for (final metric in source.computeMetrics()) {
    double distance = 0;
    bool draw = true;
    while (distance < metric.length) {
      final len = draw ? dashWidth : dashGap;
      final end = (distance + len).clamp(0.0, metric.length).toDouble();
      if (draw) dest.addPath(metric.extractPath(distance, end), Offset.zero);
      distance += len;
      draw = !draw;
    }
  }
  return dest;
}
