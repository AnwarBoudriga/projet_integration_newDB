import 'package:flutter/material.dart';

/// Zone à bordure pointillée (zone de dépôt de fichier).
class DashedBorderBox extends StatelessWidget {
  const DashedBorderBox({
    super.key,
    required this.child,
    required this.color,
    this.fill,
    this.radius = 8,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final Color color;
  final Color? fill;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(color: color, fill: fill, radius: radius),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _DashedPainter extends CustomPainter {
  _DashedPainter({required this.color, required this.fill, required this.radius});

  final Color color;
  final Color? fill;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, Radius.circular(radius));
    if (fill != null) {
      canvas.drawRRect(rrect, Paint()..color = fill!);
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPainter old) =>
      old.color != color || old.fill != fill || old.radius != radius;
}
