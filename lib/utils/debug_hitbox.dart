import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// ✅ กล่องสีแดงสำหรับเช็คระยะ Hitbox (แก้ไขให้มี 2 สถานะ: เตือน กับ โจมตีจริง)
class DebugHitbox extends PositionComponent {
  final double lifetime;
  final bool isWarning;
  double elapsed = 0.0;

  DebugHitbox({
    required Vector2 position,
    required Vector2 size,
    this.lifetime = 0.3,
    this.isWarning = false,
  }) : super(position: position, size: size, anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (isWarning) {
      // ✅ 1. State: Warning (เตือนผู้เล่น: พิ้นที่อันตรายสีเหลืองส้ม มีขอบ)
      canvas.drawRect(
        size.toRect(),
        Paint()
          ..color = Colors.orange.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        size.toRect(),
        Paint()
          ..color = Colors.orangeAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    } else {
      // ✅ 2. State: Real attack (โจมตีจริง: สีแดงเข้ม)
      canvas.drawRect(
        size.toRect(),
        Paint()
          ..color = Colors.red.withValues(alpha: 0.7)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt;
    if (elapsed >= lifetime) {
      removeFromParent();
    }
  }
}