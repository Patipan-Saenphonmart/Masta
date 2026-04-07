// สำหรับใช้ Colors
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'player.dart'; // import ตัวละคร Rabbit เพื่อเช็ค type

class Tree extends SpriteComponent with CollisionCallbacks {
  
  // สร้าง Constructor รับค่าตำแหน่งและภาพ
  Tree({
    required Vector2 position, 
    required Vector2 size, 
    required Sprite sprite
  }) : super(
    position: position, 
    size: size, 
    sprite: sprite, 
    anchor: Anchor.bottomLeft // จุดอ้างอิงอยู่ที่มุมซ้ายล่าง (ตาม Tiled)
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // สร้าง Hitbox ไว้เช็คว่าตัวละครเดินเข้าด้านหลังหรือยัง
    // ปรับขนาดให้เล็กลงหน่อย เพื่อให้ดูสมจริง (เช่น เฉพาะช่วงพุ่มใบ)
    add(RectangleHitbox(
      position: Vector2(size.x * 0.2, size.y * 0.1), // ขยับเข้ามาหน่อย
      size: Vector2(size.x * 0.6, size.y * 0.6),     // ขนาดเล็กกว่ารูปจริงนิดนึง
      isSolid: false, // สำคัญ! ตั้งเป็น false เพื่อให้เดินทะลุได้ (เป็นแค่เซนเซอร์)
    ));
  }

  // เมื่อเริ่มชน (เดินเข้าหลังต้นไม้)
  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    // เช็คว่าเป็นตัวกระต่ายไหม
    if (other is Rabbit) {
      // ปรับสีให้จางลง (Opacity 0.5)
      paint.color = Colors.white.withOpacity(0.5);
    }
  }

  // เมื่อเลิกชน (เดินออกมา)
  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    
    if (other is Rabbit) {
      // ปรับสีกลับเป็นปกติ (Opacity 1.0)
      paint.color = Colors.white.withOpacity(1.0);
    }
  }
}