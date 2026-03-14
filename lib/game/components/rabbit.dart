import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/game.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart'; // สำหรับ Colors
import '../../game_data.dart'; // ✅ Import GameData

enum RabbitState { idle, run, jump, hit, dead }

class Rabbit extends SpriteAnimationGroupComponent<RabbitState>
    with HasGameRef<FlameGame>, CollisionCallbacks {
  
  double moveSpeed = 120; // ปรับความเร็วตามต้องการ
  Vector2 velocity = Vector2.zero();
  final Vector2 _lastPosition = Vector2.zero();

  bool _isHitPlaying = false;
  double _hitElapsed = 0.0;
  final double _hitStepTime = 0.12;
  final int _hitFrames = 4;
  bool _isDead = false;

  // ✅ 1. กำหนดขนาดตัวละครในเกมให้คงที่ (Display Size)
  static final Vector2 characterSize = Vector2.all(50.0); 

  Rabbit({Vector2? position})
      : super(
          size: characterSize, // ✅ ใช้ขนาดคงที่
          position: position ?? Vector2.zero(),
          anchor: Anchor.center,
          current: RabbitState.idle,
        );

  bool get isHitPlaying => _isHitPlaying;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Hitbox ปรับให้พอดีกับ characterSize (50x50)
    add(RectangleHitbox(
      position: Vector2(12, 12), // ปรับตำแหน่งให้เข้ากลาง (ลองปรับค่านี้ให้พอดีกับตัวกระต่าย)
      size: Vector2(26, 30),     // ขนาด Hitbox
    ));

    // เช็คว่าใส่เกราะไหม
    bool hasArmor = GameData.isEquipped("เกราะวิเศษ (Magic Armor)");
    
    // ✅ 2. กำหนดชื่อไฟล์และพารามิเตอร์ Animation
    String suffix = hasArmor ? "_armor" : "";
    
    // ขนาดภาพต้นฉบับ 1 ช่อง (Frame Size)
    // 384 / 12 = 32, ดังนั้นใช้ 32x32 ทั้งใส่เกราะและไม่ใส่
    double srcSize = 32.0;

    // โหลดภาพ
    final idleImage = await gameRef.images.load('rabbit_idle$suffix.png');
    final runImage = await gameRef.images.load('rabbit_run$suffix.png'); 
    final jumpImage = await gameRef.images.load('rabbit_jump.png');
    final hitImage = await gameRef.images.load('rabbit_hit.png');
    // ใช้ hitImage แทน deadImage ไปก่อนถ้าไม่มีไฟล์แยก
    final deadImage = await gameRef.images.load('rabbit_hit.png'); 

    // ✅ 3. สร้าง SpriteSheet
    final idleSheet = SpriteSheet(image: idleImage, srcSize: Vector2.all(srcSize));
    final runSheet = SpriteSheet(image: runImage, srcSize: Vector2.all(srcSize));
    final jumpSheet = SpriteSheet(image: jumpImage, srcSize: Vector2(32, 32));
    final hitSheet = SpriteSheet(image: hitImage, srcSize: Vector2(32, 32));
    final deadSheet = SpriteSheet(image: deadImage, srcSize: Vector2(32, 32));

    // ✅ 4. สร้าง Animation (แก้ให้เล่นครบเฟรมสำหรับชุดเกราะ)
    // ถ้าใส่เกราะ (384px / 32px) = 12 เฟรม -> เล่น 0 ถึง 11
    // ถ้าไม่ใส่ (128px / 32px) = 4 เฟรม -> เล่น 0 ถึง 3
    int runFrameCount = 12;
    double runStepTime = 0.08; // ชุดเกราะเฟรมเยอะกว่า เร่งเวลาหน่อยจะได้ลื่น

    animations = {
      RabbitState.idle: idleSheet.createAnimation(row: 0, stepTime: 0.35, from: 0, to: 3),
      
      // ✅ แก้ไขตรงนี้: ใช้ตัวแปร runFrameCount เพื่อเล่นให้ครบทุกเฟรมที่มี
      RabbitState.run: runSheet.createAnimation(
          row: 0, 
          stepTime: runStepTime, 
          from: 0, 
          to: runFrameCount - 1
      ),
      
      RabbitState.jump: jumpSheet.createAnimation(row: 0, stepTime: 0.20, from: 0, to: 3),
      RabbitState.hit: hitSheet.createAnimation(row: 0, stepTime: _hitStepTime, from: 0, to: _hitFrames - 1, loop: false),
      RabbitState.dead: deadSheet.createAnimation(row: 0, stepTime: 0.25, from: 0, to: 3, loop: false),
    };
  }

  void faceDirection(double dirX) {
    if (dirX < 0 && scale.x > 0) {
      flipHorizontally();
    } else if (dirX > 0 && scale.x < 0) {
      flipHorizontally();
    }
  }

  void setState(RabbitState state) {
    if (current == state) return;
    
    // ถ้าตายแล้วห้ามเปลี่ยนท่า
    if (_isDead) return; 

    current = state;

    if (state == RabbitState.hit) {
      _isHitPlaying = true;
      _hitElapsed = 0.0;
    } else if (state == RabbitState.idle ||
        state == RabbitState.run ||
        state == RabbitState.jump) {
      _isHitPlaying = false;
    }
  }

  @override
  void update(double dt) {
    _lastPosition.setFrom(position);
    super.update(dt);

    if (_isDead) return;

    if (!_isHitPlaying && velocity.length > 0.01) {
      position += velocity.normalized() * moveSpeed * dt;
    }

    if (_isHitPlaying) {
      _hitElapsed += dt;
      if (_hitElapsed >= _hitStepTime * _hitFrames) {
        _isHitPlaying = false;
        setState(RabbitState.idle);
      }
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    // เพิ่ม Logic ชนกำแพงหรือศัตรูที่นี่ถ้าต้องการ
  }
  
  void playHit() {
    if (_isDead) return;
    setState(RabbitState.hit);
    // ไม่ต้องใช้ Future.delayed เพื่อคืนค่า เพราะทำใน update แล้ว (แม่นยำกว่า)
  }

  void playDeath() {
    if (_isDead) return;
    _isDead = true;
    velocity = Vector2.zero(); // หยุดเดิน
    setState(RabbitState.dead);
    // ลบออกจากเกมเมื่อเล่นท่าตายจบ (หรือดีเลย์สักพัก)
    Future.delayed(const Duration(seconds: 2), () {
      removeFromParent();
    });
  }
}