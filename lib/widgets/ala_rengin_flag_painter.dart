import 'package:flutter/material.dart';
import 'dart:math' as math;

class AlaRenginFlag extends StatelessWidget {
  final double width;
  final double height;

  const AlaRenginFlag({
    super.key,
    this.width = 32,
    this.height = 20,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AlaRenginFlagPainter(),
      size: Size(width, height),
    );
  }
}

class _AlaRenginFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Rot (oben)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height / 3),
      Paint()..color = const Color(0xFFEE3333), // Rot der Ala rengin
    );

    // Weiß (Mitte)
    canvas.drawRect(
      Rect.fromLTWH(0, size.height / 3, size.width, size.height / 3),
      Paint()..color = Colors.white,
    );

    // Grün (unten)
    canvas.drawRect(
      Rect.fromLTWH(0, 2 * size.height / 3, size.width, size.height / 3),
      Paint()..color = const Color(0xFF2E8B57), // Grün der Ala rengin
    );

    // Goldene Sonne in der Mitte
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final sunRadius = size.height / 4;

    final sunPaint = Paint()..color = const Color(0xFFFFC700); // Gold

    // Sonnenkugel
    canvas.drawCircle(Offset(centerX, centerY), sunRadius * 0.6, sunPaint);

    // Sonnenstrahlen (12 Stück wie Ala rengin)
    for (int i = 0; i < 12; i++) {
      final angle = (i * 360 / 12) * (math.pi / 180);
      final startX = centerX + (sunRadius * 0.7) * (i % 2 == 0 ? 1.2 : 0.9) * math.cos(angle);
      final startY = centerY + (sunRadius * 0.7) * (i % 2 == 0 ? 1.2 : 0.9) * math.sin(angle);
      final endX = centerX + sunRadius * 1.3 * math.cos(angle);
      final endY = centerY + sunRadius * 1.3 * math.sin(angle);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        Paint()
          ..color = const Color(0xFFFFC700)
          ..strokeWidth = sunRadius * 0.15,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
