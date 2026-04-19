import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CutsceneTrigger extends PositionComponent {
  // [INPUT 1]: รับชื่อ Event ที่ตั้งไว้ในโปรแกรม Tiled
  final String actionName; 
  
  // สวิตช์ป้องกันการชนซ้ำรัวๆ
  bool hasTriggered = false; 

  // [INPUT 2]: รับพิกัด (position) และขนาด (size) จาก Tiled ผ่าน Constructor
  CutsceneTrigger({
    required Vector2 position,
    required Vector2 size,
    required this.actionName,
  }) : super(position: position, size: size);

  // [OUTPUT (Visual)]: ตีเส้นกล่องสีแดงกึ่งโปร่งใส เพื่อให้เรา (Dev) เห็นตอนทดสอบ
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(
      size.toRect(),
      Paint()..color = const Color.fromARGB(255, 41, 9, 246).withValues(alpha: 0.3)..style = PaintingStyle.fill,
    );
  }
}