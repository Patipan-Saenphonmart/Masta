import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/game.dart';
import 'package:flame/collisions.dart';
import '../../game_data.dart';

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
  // ไม่ว่ารูปต้นฉบับจะมา 32, 36 หรือ 64 จะถูกย่อ/ขยายมาเหลือเท่านี้บนหน้าจอ
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

    // Hitbox ปรับให้พอดีกับ characterSize
    add(RectangleHitbox(
      position: Vector2(12, 16), // ปรับตำแหน่งให้เข้ากลาง (x: (48-24)/2, y: ...)
      size: Vector2(24, 24),     // ขนาด Hitbox
    ));

    // เช็คว่าใส่เกราะไหม
    bool hasArmor = GameData.isEquipped("เกราะวิเศษ (Magic Armor)");
    
    // ✅ 2. กำหนดขนาดภาพต้นฉบับ (Source Size) แยกตามท่าทาง
    String suffix = hasArmor ? "_armor" : "";
    
    // Idle: ปกติ 32, ใส่เกราะ 64
    double idleSourceSize = hasArmor ? 32 : 32.0;
    
    // Run: ปกติ 32, ใส่เกราะ 36 (ตามที่คุณแจ้ง)
    double runSourceSize = hasArmor ? 32 : 32.0; 

    // โหลดภาพ (แก้ให้โหลด run แบบมี suffix ด้วย)
    final idleImage = await gameRef.images.load('rabbit_idle$suffix.png');
    final runImage = await gameRef.images.load('rabbit_run$suffix.png'); // ✅ แก้ให้โหลด rabbit_run_armor.png ได้
    final jumpImage = await gameRef.images.load('rabbit_jump.png');
    final hitImage = await gameRef.images.load('rabbit_hit.png');
    final deadImage = await gameRef.images.load('rabbit_hit.png');

    // ✅ 3. สร้าง SpriteSheet โดยใช้ sourceSize ที่ถูกต้องแยกกัน
    final idleSheet = SpriteSheet(image: idleImage, srcSize: Vector2.all(idleSourceSize));
    final runSheet = SpriteSheet(image: runImage, srcSize: Vector2.all(runSourceSize)); // ✅ ใช้ขนาด 36 ถ้าใส่เกราะ
    
    final jumpSheet = SpriteSheet(image: jumpImage, srcSize: Vector2(32, 32));
    final hitSheet = SpriteSheet(image: hitImage, srcSize: Vector2(32, 32));
    final deadSheet = SpriteSheet(image: deadImage, srcSize: Vector2(32, 32));

    animations = {
      RabbitState.idle: idleSheet.createAnimation(row: 0, stepTime: 0.35, from: 0, to: 3),
      RabbitState.run: runSheet.createAnimation(row: 0, stepTime: 0.18, from: 0, to: 3),
      RabbitState.jump: jumpSheet.createAnimation(row: 0, stepTime: 0.20, from: 0, to: 3),
      RabbitState.hit: hitSheet.createAnimation(row: 0, stepTime: _hitStepTime, from: 0, to: _hitFrames - 1, loop: false),
      RabbitState.dead: deadSheet.createAnimation(row: 0, stepTime: 0.25, from: 0, to: 3, loop: false),
    };
  }

  void faceDirection(double dirX) {
    if (dirX < 0) {
      scale.x = -scale.x.abs();
    } else if (dirX > 0) {
      scale.x = scale.x.abs();
    }
  }

  void setState(RabbitState state) {
    if (current == state) return;
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
  }
  
  void playHit() {
    setState(RabbitState.hit);
    _hitElapsed = 0.0;
    Future.delayed(Duration(milliseconds: (_hitStepTime * _hitFrames * 1000).toInt()), () {
      if (!_isDead) {
        _isHitPlaying = false;
        setState(RabbitState.idle);
      }
    });
  }

  void playDeath() {
    _isDead = true;
    setState(RabbitState.dead);
    Future.delayed(const Duration(seconds: 1), () {
      removeFromParent();
    });
  }
}