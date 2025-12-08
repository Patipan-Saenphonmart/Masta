import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart'; // ✅ เพิ่มเพื่อใช้ Colors

enum EnemyState { idle, walk, run, hit, dead }

class Enemy extends SpriteAnimationGroupComponent<EnemyState> with HasGameRef {
  // --- Stats ---
  int maxHp = 50;
  int hp = 50;
  double detectionRange = 200.0; // ✅ ระยะมองเห็น (ไล่ตามเมื่อเข้าใกล้นี้)

  // --- UI Components ---
  late RectangleComponent hpBar;
  late RectangleComponent hpBg;

  // --- Flags ---
  bool alive = true;
  bool _isHitPlaying = false;
  double _hitElapsed = 0.0;
  final double _hitStepTime = 0.12;
  final int _hitFrames = 4;

  Vector2 velocity = Vector2.zero();

  Enemy({Vector2? position})
      : super(
          position: position ?? Vector2.zero(),
          size: Vector2.all(32),
          anchor: Anchor.center,
          current: EnemyState.idle,
        );

  bool get isHitPlaying => _isHitPlaying;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1. เพิ่ม Hitbox
    add(RectangleHitbox(
      position: Vector2(4, 4),
      size: Vector2(24, 24),
      isSolid: true,
    ));

    // 2. ✅ สร้างหลอดเลือด (HP Bar)
    // พื้นหลังหลอดเลือด (สีแดงจางๆ)
    hpBg = RectangleComponent(
      position: Vector2(0, -8), // อยู่บนหัวเล็กน้อย
      size: Vector2(32, 4),     // ความกว้างเท่าตัว (32)
      paint: Paint()..color = Colors.red.withOpacity(0.3),
    );
    
    // หลอดเลือดจริง (สีเขียว)
    hpBar = RectangleComponent(
      position: Vector2(0, -8),
      size: Vector2(32, 4),
      paint: Paint()..color = Colors.green,
    );

    add(hpBg);
    add(hpBar);

    // 3. โหลดภาพและ Animation
    final idleImage = await gameRef.images.load('enemy_idle.png');
    final walkImage = await gameRef.images.load('enemy_walk.png');
    final runImage = await gameRef.images.load('enemy_run.png');
    final hitImage = await gameRef.images.load('enemy_hit.png');
    final deadImage = await gameRef.images.load('enemy_hit.png');

    final idleAnim = SpriteAnimation.fromFrameData(
      idleImage,
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.3,
        textureSize: Vector2(32, 32),
      ),
    );
    
    final walkAnim = SpriteAnimation.fromFrameData(
      walkImage,
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.2,
        textureSize: Vector2(32, 32),
      ),
    );

    final runAnim = SpriteAnimation.fromFrameData(
      runImage,
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.12,
        textureSize: Vector2(32, 32),
      ),
    );

    final hitAnim = SpriteAnimation.fromFrameData(
      hitImage,
      SpriteAnimationData.sequenced(
        amount: _hitFrames,
        stepTime: _hitStepTime,
        textureSize: Vector2(32, 32),
        loop: false,
      ),
    );

    final deadAnim = SpriteAnimation.fromFrameData(
      deadImage,
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.2,
        textureSize: Vector2(32, 32),
        loop: false,
      ),
    );

    animations = {
      EnemyState.idle: idleAnim,
      EnemyState.walk: walkAnim,
      EnemyState.run: runAnim,
      EnemyState.hit: hitAnim,
      EnemyState.dead: deadAnim,
    };
  }

  // ✅ ฟังก์ชันโดนดาเมจ (ใช้แทนการเรียก playHit ตรงๆ)
  void takeDamage(int damage) {
    if (!alive) return;

    hp -= damage;
    
    // อัปเดตหลอดเลือด
    double hpPercent = (hp / maxHp).clamp(0.0, 1.0);
    hpBar.width = 32 * hpPercent; // 32 คือความกว้างเต็ม
    
    // เปลี่ยนสีหลอดเลือดตามความวิกฤต
    if (hpPercent < 0.3) {
      hpBar.paint.color = Colors.red;
    } else {
      hpBar.paint.color = Colors.green;
    }

    if (hp <= 0) {
      hp = 0;
      die();
    } else {
      playHit();
    }
  }

  void setState(EnemyState state) {
    if (current == state) return;
    
    if (state == EnemyState.hit) {
      _isHitPlaying = true;
      _hitElapsed = 0.0;
    } else if (state == EnemyState.dead) {
      alive = false;
      // ซ่อนหลอดเลือดเมื่อตาย
      hpBar.removeFromParent();
      hpBg.removeFromParent();
    }

    current = state;
  }

  void faceDirection(double dirX) {
    if (dirX < 0) {
      scale.x = -scale.x.abs();
    } else if (dirX > 0) {
      scale.x = scale.x.abs();
    }
  }

  void playHit() {
    if (!_isHitPlaying && alive) {
      setState(EnemyState.hit);
    }
  }

  void die() {
    if (!alive) return;
    setState(EnemyState.dead);
    Future.delayed(const Duration(seconds: 1), () {
      removeFromParent();
    });
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!alive) return;

    position += velocity * dt;

    if (_isHitPlaying) {
      _hitElapsed += dt;
      if (_hitElapsed >= _hitStepTime * _hitFrames) {
        _isHitPlaying = false;
        if (alive && current == EnemyState.hit) {
          setState(EnemyState.idle);
        }
      }
    }
  }
}