import 'package:flame/components.dart';
import 'package:flutter/material.dart';


class Obstacle extends PositionComponent {
  String name;
  Obstacle({required Vector2 position, required Vector2 size, this.name = ''}) {
    this.position = position;
    this.size = size;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // วาดกล่องสีแดงทับไว้ เพื่อให้เห็นตำแหน่งตอนทดสอบ
    canvas.drawRect(
      size.toRect(),
      Paint()
        ..color = Colors.red.withValues(alpha: 0.3) // สีแดงโปร่งแสง
        ..style = PaintingStyle.fill,
    );
  }
}