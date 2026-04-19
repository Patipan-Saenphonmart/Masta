import 'dart:math';
import 'package:flutter/material.dart';



// =====================================================================
// CustomPainter: สัญลักษณ์ MASTA (ชามสปาเก็ตตี้ silhouette + glow)
// =====================================================================

class MastaSymbolPainter extends CustomPainter {
  final double glowIntensity;

  MastaSymbolPainter({required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Glow effect
    final glowPaint = Paint()
      ..color = Color.fromRGBO(
        180,
        130,
        255,
        0.15 + glowIntensity * 0.2,
      )
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30 + glowIntensity * 20);

    canvas.drawCircle(center, 70 + glowIntensity * 10, glowPaint);

    // ชาม (Bowl shape)
    final bowlPaint = Paint()
      ..color = Color.fromRGBO(180, 130, 255, 0.3 + glowIntensity * 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + glowIntensity * 3);

    // วาดรูปชาม
    final bowlPath = Path();
    bowlPath.moveTo(center.dx - 45, center.dy);
    bowlPath.quadraticBezierTo(
      center.dx - 50,
      center.dy + 40,
      center.dx,
      center.dy + 45,
    );
    bowlPath.quadraticBezierTo(
      center.dx + 50,
      center.dy + 40,
      center.dx + 45,
      center.dy,
    );
    canvas.drawPath(bowlPath, bowlPaint);

    // ขอบชามด้านบน
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx, center.dy), width: 90, height: 16),
      0,
      pi,
      false,
      bowlPaint,
    );

    // ฐานชาม
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 50),
        width: 30,
        height: 8,
      ),
      0,
      pi,
      false,
      bowlPaint,
    );

    // เส้นสปาเก็ตตี้ (เส้นหยัก ๆ ด้านบนชาม)
    final noodlePaint = Paint()
      ..color = Color.fromRGBO(255, 220, 150, 0.25 + glowIntensity * 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1 + glowIntensity * 2);

    for (int i = 0; i < 3; i++) {
      final noodlePath = Path();
      double startX = center.dx - 30 + i * 15;
      noodlePath.moveTo(startX, center.dy - 5);
      noodlePath.quadraticBezierTo(
        startX + 5,
        center.dy - 20 - i * 5,
        startX + 10,
        center.dy - 10,
      );
      noodlePath.quadraticBezierTo(
        startX + 15,
        center.dy - 30 - i * 3,
        startX + 20,
        center.dy - 15,
      );
      canvas.drawPath(noodlePath, noodlePaint);
    }

    // ไอน้ำ (steam)
    final steamPaint = Paint()
      ..color = Color.fromRGBO(200, 180, 255, 0.1 + glowIntensity * 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..maskFilter =
          MaskFilter.blur(BlurStyle.normal, 3 + glowIntensity * 4);

    for (int i = 0; i < 2; i++) {
      final steamPath = Path();
      double sx = center.dx - 15 + i * 30;
      steamPath.moveTo(sx, center.dy - 20);
      steamPath.quadraticBezierTo(
        sx - 5,
        center.dy - 40 - glowIntensity * 10,
        sx + 3,
        center.dy - 55 - glowIntensity * 10,
      );
      canvas.drawPath(steamPath, steamPaint);
    }

    // ข้อความ MASTA
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'MASTA',
        style: TextStyle(
          color: Color.fromRGBO(
            200,
            170,
            255,
            0.4 + glowIntensity * 0.2,
          ),
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 8,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy + 65,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant MastaSymbolPainter oldDelegate) {
    return oldDelegate.glowIntensity != glowIntensity;
  }
}
