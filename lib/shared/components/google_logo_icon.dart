import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Logo Google officiel (4 couleurs) — sans asset externe.
class GoogleLogoIcon extends StatelessWidget {
  const GoogleLogoIcon({super.key, this.size = 20});

  final double size;

  static const Color blue = Color(0xFF4285F4);
  static const Color red = Color(0xFFEA4335);
  static const Color yellow = Color(0xFFFBBC05);
  static const Color green = Color(0xFF34A853);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter(strokeWidth: size * 0.19)),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  _GoogleLogoPainter({required this.strokeWidth});

  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;
    final rect = Rect.fromCircle(center: center, radius: radius);

    void drawArc(Color color, double start, double sweep) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep, false, paint);
    }

    drawArc(GoogleLogoIcon.blue, -math.pi * 0.25, math.pi * 0.5);
    drawArc(GoogleLogoIcon.green, math.pi * 0.25, math.pi * 0.5);
    drawArc(GoogleLogoIcon.yellow, math.pi * 0.75, math.pi * 0.5);
    drawArc(GoogleLogoIcon.red, -math.pi * 0.75, math.pi * 0.35);

    final barPaint = Paint()
      ..color = GoogleLogoIcon.blue
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - strokeWidth * 0.05,
        center.dy - strokeWidth / 2,
        size.width * 0.26,
        strokeWidth,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) =>
      oldDelegate.strokeWidth != strokeWidth;
}
