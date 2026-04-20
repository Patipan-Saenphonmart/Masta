import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/game.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../data/game_data.dart';
enum RabbitState {
  idleDown,
  idleUp,
  idleLeft,
  idleRight,
  walkDown,
  walkUp,
  walkLeft,
  walkRight,
  runDown,
  runUp,
  runLeft,
  runRight,
  hitDown,
  hitUp,
  hitLeft,
  hitRight,
  deadDown,
  deadUp,
  deadLeft,
  deadRight,
  attackDown,
  attackUp,
  attackLeft,
  attackRight,
  runAttackDown,
  runAttackUp,
  runAttackLeft,
  runAttackRight,
  walkAttackDown,
  walkAttackUp,
  walkAttackLeft,
  walkAttackRight,
  sleeping,
}

class Rabbit extends SpriteAnimationGroupComponent<RabbitState>
    with HasGameReference<FlameGame>, CollisionCallbacks {
  double moveSpeed = 100; // ปรับความเร็วตามต้องการ
  Vector2 velocity = Vector2.zero();
  final Vector2 _lastPosition = Vector2.zero();

  bool _isHitPlaying = false;
  double _hitElapsed = 0.0;
  final double _hitStepTime = 0.12;
  final int _hitFrames = 4;
  bool _isDead = false;

  // ✅ Attack state
  bool _isAttacking = false;
  double _attackElapsed = 0.0;
  final double attackDuration = 8 * 0.06; // 8 frames * 0.06 step time

  // ✅ ทิศทางล่าสุดที่กระต่ายหันไป (Last facing direction)
  Vector2 lastDirection = Vector2(0, 1);

  // ✅ 1. กำหนดขนาดตัวละครในเกมให้คงที่ (Character Size)
  static final Vector2 characterSize = Vector2.all(100.0);

  Rabbit({Vector2? position})
      : super(
          size: characterSize, // ✅ ใช้ขนาดคงที่
          position: position ?? Vector2.zero(),
          anchor: Anchor.center,
          current: RabbitState.idleRight,
        );

  bool get isHitPlaying => _isHitPlaying;
  bool get isAttacking => _isAttacking;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Hitbox ปรับให้ครอบคลุมแค่บริเวณส่วนเท้าของตัวละคร
    add(RectangleHitbox(
      position: Vector2(20, 72), // ย้ายตำแหน่ง Y ลงมาที่ด้านล่าง (เท้า)
      size: Vector2(
          60, 28), // ลดความสูงให้เหลือแค่ช่วงเท้า และขยายความกว้างนิดหน่อย
    ));

    // ✅ 2. โหลดภาพ Sprite จาก GameData (centralized)
    final idleImage = await game.images.load(GameData.playerIdleSprite);
    final walkImage = await game.images.load(GameData.playerWalkSprite);
    final runImage = await game.images.load(GameData.playerRunSprite);
    final hitImage = await game.images.load(GameData.playerHitSprite);
    final deadImage = await game.images.load(GameData.playerDeadSprite);
    final attackImage = await game.images.load(GameData.playerAttackSprite);
    final runattackImage =
        await game.images.load(GameData.playerRunAttackSprite);
    final walkattackImage =
        await game.images.load(GameData.playerWalkAttackSprite);

    // ✅ 3. สร้าง SpriteSheet (ใช้ spriteFrameSize จาก GameData)
    final frameSize = Vector2.all(GameData.spriteFrameSize);
    final idleSheet = SpriteSheet(image: idleImage, srcSize: frameSize);
    final walkSheet = SpriteSheet(image: walkImage, srcSize: frameSize);
    final runSheet = SpriteSheet(image: runImage, srcSize: frameSize);
    final hitSheet = SpriteSheet(image: hitImage, srcSize: frameSize);
    final deadSheet = SpriteSheet(image: deadImage, srcSize: frameSize);
    final attackSheet = SpriteSheet(image: attackImage, srcSize: frameSize);
    final runattackSheet =
        SpriteSheet(image: runattackImage, srcSize: frameSize);
    final walkattackSheet =
        SpriteSheet(image: walkattackImage, srcSize: frameSize);

    // ✅ 4. สร้าง Animation (ใช้ frame count และ stepTime จาก GameData)
    final idleCount = GameData.idleFrameCount;
    final idleUpCount = GameData.idleUpFrameCount;
    final runCount = GameData.runFrameCount;
    final hitCount = GameData.hitFrameCount;
    final deadCount = GameData.deadFrameCount;

    animations = {
      RabbitState.idleDown: idleSheet.createAnimation(
          row: 0, stepTime: GameData.idleStepTime, from: 0, to: idleCount - 1),
      RabbitState.idleLeft: idleSheet.createAnimation(
          row: 1, stepTime: GameData.idleStepTime, from: 0, to: idleCount - 1),
      RabbitState.idleRight: idleSheet.createAnimation(
          row: 2, stepTime: GameData.idleStepTime, from: 0, to: idleCount - 1),
      RabbitState.idleUp: idleSheet.createAnimation(
          row: 3,
          stepTime: GameData.idleStepTime,
          from: 0,
          to: idleUpCount - 1),

      RabbitState.runDown: runSheet.createAnimation(
          row: 0, stepTime: GameData.runStepTime, from: 0, to: runCount - 1),
      RabbitState.runLeft: runSheet.createAnimation(
          row: 1, stepTime: GameData.runStepTime, from: 0, to: runCount - 1),
      RabbitState.runRight: runSheet.createAnimation(
          row: 2, stepTime: GameData.runStepTime, from: 0, to: runCount - 1),
      RabbitState.runUp: runSheet.createAnimation(
          row: 3, stepTime: GameData.runStepTime, from: 0, to: runCount - 1),

      RabbitState.hitDown: hitSheet.createAnimation(
          row: 0, stepTime: GameData.hitStepTime, from: 0, to: hitCount - 1, loop: false),
      RabbitState.hitLeft: hitSheet.createAnimation(
          row: 1, stepTime: GameData.hitStepTime, from: 0, to: hitCount - 1, loop: false),
      RabbitState.hitRight: hitSheet.createAnimation(
          row: 2, stepTime: GameData.hitStepTime, from: 0, to: hitCount - 1, loop: false),
      RabbitState.hitUp: hitSheet.createAnimation(
          row: 3, stepTime: GameData.hitStepTime, from: 0, to: hitCount - 1, loop: false),

      RabbitState.deadDown: deadSheet.createAnimation(
          row: 0, stepTime: GameData.deadStepTime, from: 0, to: deadCount - 1, loop: false),
      RabbitState.deadLeft: deadSheet.createAnimation(
          row: 1, stepTime: GameData.deadStepTime, from: 0, to: deadCount - 1, loop: false),
      RabbitState.deadRight: deadSheet.createAnimation(
          row: 2, stepTime: GameData.deadStepTime, from: 0, to: deadCount - 1, loop: false),
      RabbitState.deadUp: deadSheet.createAnimation(
          row: 3, stepTime: GameData.deadStepTime, from: 0, to: deadCount - 1, loop: false),
          
      // Attack Animations
      RabbitState.attackDown: attackSheet.createAnimation(
          row: 0, stepTime: 0.06, from: 0, to: 7, loop: false),
      RabbitState.attackLeft: attackSheet.createAnimation(
          row: 1, stepTime: 0.06, from: 0, to: 7, loop: false),
      RabbitState.attackRight: attackSheet.createAnimation(
          row: 2, stepTime: 0.06, from: 0, to: 7, loop: false),
      RabbitState.attackUp: attackSheet.createAnimation(
          row: 3, stepTime: 0.06, from: 0, to: 7, loop: false),

      // Run Attack Animations
      RabbitState.runAttackDown: runattackSheet.createAnimation(
          row: 0, stepTime: 0.06, from: 0, to: 7, loop: false),
      RabbitState.runAttackLeft: runattackSheet.createAnimation(
          row: 1, stepTime: 0.06, from: 0, to: 7, loop: false),
      RabbitState.runAttackRight: runattackSheet.createAnimation(
          row: 2, stepTime: 0.06, from: 0, to: 7, loop: false),
      RabbitState.runAttackUp: runattackSheet.createAnimation(
          row: 3, stepTime: 0.06, from: 0, to: 7, loop: false),

      // ใช้ dead sprite เป็น placeholder (จะหมุน 90 องศาใน setSleeping)
      RabbitState.sleeping: deadSheet.createAnimation(
          row: 0, stepTime: 0.8, from: 0, to: 1, loop: true),

      // ✅ Attack Animations (Sword_attack_with_shadow)
      RabbitState.attackDown: attackSheet.createAnimation(
          row: 0, stepTime: GameData.attackStepTime, from: 0, to: GameData.attackFrameCount - 1, loop: false),
      RabbitState.attackLeft: attackSheet.createAnimation(
          row: 1, stepTime: GameData.attackStepTime, from: 0, to: GameData.attackFrameCount - 1, loop: false),
      RabbitState.attackRight: attackSheet.createAnimation(
          row: 2, stepTime: GameData.attackStepTime, from: 0, to: GameData.attackFrameCount - 1, loop: false),
      RabbitState.attackUp: attackSheet.createAnimation(
          row: 3, stepTime: GameData.attackStepTime, from: 0, to: GameData.attackFrameCount - 1, loop: false),

      // ✅ Run Attack Animations (Sword_Run_Attack_with_shadow)
      RabbitState.runAttackDown: runattackSheet.createAnimation(
          row: 0, stepTime: GameData.runAttackStepTime, from: 0, to: GameData.runAttackFrameCount - 1, loop: false),
      RabbitState.runAttackLeft: runattackSheet.createAnimation(
          row: 1, stepTime: GameData.runAttackStepTime, from: 0, to: GameData.runAttackFrameCount - 1, loop: false),
      RabbitState.runAttackRight: runattackSheet.createAnimation(
          row: 2, stepTime: GameData.runAttackStepTime, from: 0, to: GameData.runAttackFrameCount - 1, loop: false),
      RabbitState.runAttackUp: runattackSheet.createAnimation(
          row: 3, stepTime: GameData.runAttackStepTime, from: 0, to: GameData.runAttackFrameCount - 1, loop: false),

      // ✅ Walk Attack Animations (Sword_Walk_Attack_with_shadow)
      RabbitState.walkAttackDown: walkattackSheet.createAnimation(
          row: 0, stepTime: GameData.runAttackStepTime, from: 0, to: GameData.walkAttackFrameCount - 1, loop: false),
      RabbitState.walkAttackLeft: walkattackSheet.createAnimation(
          row: 1, stepTime: GameData.runAttackStepTime, from: 0, to: GameData.walkAttackFrameCount - 1, loop: false),
      RabbitState.walkAttackRight: walkattackSheet.createAnimation(
          row: 2, stepTime: GameData.runAttackStepTime, from: 0, to: GameData.walkAttackFrameCount - 1, loop: false),
      RabbitState.walkAttackUp: walkattackSheet.createAnimation(
          row: 3, stepTime: GameData.runAttackStepTime, from: 0, to: GameData.walkAttackFrameCount - 1, loop: false),
    };
  }

  // ✅ เพิ่ม logic การเปลี่ยน state สำหรับ 4 ทิศทาง ตึงๆ
  void updateAnimationState() {
    if (_isHitPlaying || _isDead || _isAttacking || current == RabbitState.sleeping) return;

    // Determine Run State based on velocity
    if (velocity.x > 0) {
      current = RabbitState.runRight;
    } else if (velocity.x < 0) {
      current = RabbitState.runLeft;
    } else if (velocity.y > 0) {
      current = RabbitState.runDown;
    } else if (velocity.y < 0) {
      current = RabbitState.runUp;
    } else {
      // If velocity is 0, switch to the matching Idle state
      if (current == RabbitState.runRight) current = RabbitState.idleRight;
      if (current == RabbitState.runLeft) current = RabbitState.idleLeft;
      if (current == RabbitState.runUp) current = RabbitState.idleUp;
      if (current == RabbitState.runDown) current = RabbitState.idleDown;
    }
  }

  void setState(RabbitState state) {
    if (current == state) return;

    // ถ้าตายแล้วห้ามเปลี่ยนท่า
    if (_isDead) return;

    current = state;

    if (state == RabbitState.deadDown ||
        state == RabbitState.deadUp ||
        state == RabbitState.deadLeft ||
        state == RabbitState.deadRight ||
        state == RabbitState.hitDown ||
        state == RabbitState.hitUp ||
        state == RabbitState.hitLeft ||
        state == RabbitState.hitRight) {
      _isHitPlaying = true;
      _hitElapsed = 0.0;
    } else if (state == RabbitState.idleDown ||
        state == RabbitState.idleUp ||
        state == RabbitState.idleLeft ||
        state == RabbitState.idleRight) {
      _isHitPlaying = false;
    }
  }

  @override
  void update(double dt) {
    _lastPosition.setFrom(position);
    super.update(dt);

    if (_isDead) return;

    if (!_isHitPlaying && !_isAttacking && velocity.length > 0.01) {
      lastDirection = velocity.normalized();
      position += velocity.normalized() * moveSpeed * dt;
    }



    if (_isHitPlaying) {
      _hitElapsed += dt;
      if (_hitElapsed >= _hitStepTime * _hitFrames) {
        _isHitPlaying = false;
        setState(RabbitState.idleDown);
      }
    }

    // ✅ Attack timer: กลับ idle เมื่อเล่นท่าจบ
    if (_isAttacking) {
      _attackElapsed += dt;
      final attackDuration = GameData.attackStepTime * GameData.attackFrameCount;
      if (_attackElapsed >= attackDuration) {
        _isAttacking = false;
        _attackElapsed = 0.0;
        // กลับไปท่า idle ตามทิศทาง
        if (current == RabbitState.attackRight || current == RabbitState.runAttackRight || current == RabbitState.walkAttackRight) {
          current = RabbitState.idleRight;
        } else if (current == RabbitState.attackLeft || current == RabbitState.runAttackLeft || current == RabbitState.walkAttackLeft) {
          current = RabbitState.idleLeft;
        } else if (current == RabbitState.attackUp || current == RabbitState.runAttackUp || current == RabbitState.walkAttackUp) {
          current = RabbitState.idleUp;
        } else {
          current = RabbitState.idleDown;
        }
      }
    }
  }


  void playHit({Vector2? attackerPos}) {
    if (_isDead) return;
    
    // หากมีตำแหน่งคนตี ให้หันหน้าไปทางนั้น ถ้าไม่มีให้ใช้ทิศทางล่าสุด
    Vector2 hitDir = lastDirection;
    if (attackerPos != null) {
      hitDir = (attackerPos - position).normalized();
    }

    // เลือกทิศทางให้ตรงกับค่าที่คำนวณได้
    if (hitDir.x.abs() >= hitDir.y.abs()) {
      if (hitDir.x > 0) {
        setState(RabbitState.hitRight);
      } else {
        setState(RabbitState.hitLeft);
      }
    } else {
      if (hitDir.y > 0) {
        setState(RabbitState.hitDown);
      } else {
        setState(RabbitState.hitUp);
      }
    }
  }

  // ✅ ฟังก์ชันเล่นท่าโจมตี (เลือกทิศทางตาม state ปัจจุบัน)
  void playAttack({bool isRunning = false}) {
    if (_isDead || _isHitPlaying || _isAttacking) return;
    _isAttacking = true;
    _attackElapsed = 0.0;

    // เลือกท่าโจมตีตามทิศทางปัจจุบัน
    if (isRunning) {
      // ใช้ Run Attack
      switch (current) {
        case RabbitState.runRight:
        case RabbitState.idleRight:
        case RabbitState.attackRight:
          current = RabbitState.runAttackRight;
          break;
        case RabbitState.runLeft:
        case RabbitState.idleLeft:
        case RabbitState.attackLeft:
          current = RabbitState.runAttackLeft;
          break;
        case RabbitState.runUp:
        case RabbitState.idleUp:
        case RabbitState.attackUp:
          current = RabbitState.runAttackUp;
          break;
        default:
          current = RabbitState.runAttackDown;
      }
    } else {
      // ใช้ Standing Attack
      switch (current) {
        case RabbitState.runRight:
        case RabbitState.idleRight:
        case RabbitState.runAttackRight:
          current = RabbitState.attackRight;
          break;
        case RabbitState.runLeft:
        case RabbitState.idleLeft:
        case RabbitState.runAttackLeft:
          current = RabbitState.attackLeft;
          break;
        case RabbitState.runUp:
        case RabbitState.idleUp:
        case RabbitState.runAttackUp:
          current = RabbitState.attackUp;
          break;
        default:
          current = RabbitState.attackDown;
      }
    }
  }

  // ✅ ฟังก์ชันสำหรับชุบชีวิต
  void reset() {
    _isDead = false;
    _isHitPlaying = false;
    _isAttacking = false;
    velocity = Vector2.zero();
    current = RabbitState.idleDown;
  }

  void playDeath() {
    if (_isDead) return;
    
    velocity = Vector2.zero(); // หยุดเดิน
    
    // ✅ เลือกทิศทางล้มตายให้ตรงกับที่หันอยู่
    if (lastDirection.x.abs() >= lastDirection.y.abs()) {
      if (lastDirection.x > 0) {
        setState(RabbitState.deadRight);
      } else {
        setState(RabbitState.deadLeft);
      }
    } else {
      if (lastDirection.y > 0) {
        setState(RabbitState.deadDown);
      } else {
        setState(RabbitState.deadUp);
      }
    }

    _isDead = true;

    // ลบออกจากเกมเมื่อเล่นท่าตายจบ (หรือดีเลย์สักพัก)
    Future.delayed(const Duration(seconds: 2), () {
      if (_isDead) {
        // ✅ ตรวจสอบก่อนเผื่อว่าผู้เล่นกดเริ่มใหม่ไปแล้วก่อน 2 วิ
        removeFromParent();
      }
    });
  }

  // ✅ Cutscene: ท่านอนสลบ
  void setSleeping() {
    _isDead = false;
    _isHitPlaying = false;
    velocity = Vector2.zero();
    current = RabbitState.sleeping;
    angle = 1.5708; // หมุน 90 องศา (นอนตะแคง)
  }

  // ✅ Cutscene: ลุกขึ้นยืน
  void wakeUp() {
    angle = 0; // คืนค่าหมุนปกติ
    _isDead = false;
    _isHitPlaying = false;
    velocity = Vector2.zero();
    current = RabbitState.idleRight;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // ✅ วาดกรอบ Hitbox สำหรับรับดาเมจ (Hurtbox Margin) ให้อยู่ส่วนเท้า
    // จุดศูนย์กลางของ Component คือ 50, 50 (จากขนาด 100x100)
    // เลื่อนลงไปที่เท้า (center y = 86, size 60x28)
    canvas.drawRect(
      Rect.fromCenter(center: const Offset(50, 65), width: 20, height: 10),
      Paint()
        ..color = const Color.fromRGBO(33, 150, 243, 0.5) // Colors.blue.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}
