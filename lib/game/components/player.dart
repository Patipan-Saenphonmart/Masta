import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/game.dart';
import 'package:flame/collisions.dart';
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
    with HasGameRef<FlameGame>, CollisionCallbacks {
  double moveSpeed = 100; // ปรับความเร็วตามต้องการ
  Vector2 velocity = Vector2.zero();
  final Vector2 _lastPosition = Vector2.zero();

  bool _isHitPlaying = false;
  double _hitElapsed = 0.0;
  final double _hitStepTime = 0.12;
  final int _hitFrames = 4;
  bool _isDead = false;

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
    final idleImage = await gameRef.images.load(GameData.playerIdleSprite);
    final walkImage = await gameRef.images.load(GameData.playerWalkSprite);
    final runImage = await gameRef.images.load(GameData.playerRunSprite);
    final hitImage = await gameRef.images.load(GameData.playerHitSprite);
    final deadImage = await gameRef.images.load(GameData.playerDeadSprite);
    final attackImage = await gameRef.images.load(GameData.playerAttackSprite);
    final runattackImage =
        await gameRef.images.load(GameData.playerRunAttackSprite);
    final walkattackImage =
        await gameRef.images.load(GameData.playerWalkAttackSprite);

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
      // ใช้ dead sprite เป็น placeholder (จะหมุน 90 องศาใน setSleeping)
      RabbitState.sleeping: deadSheet.createAnimation(
          row: 0, stepTime: 0.8, from: 0, to: 1, loop: true),
    };
  }

  // ✅ เพิ่ม logic การเปลี่ยน state สำหรับ 4 ทิศทาง ตึงๆ
  void updateAnimationState() {
    if (_isHitPlaying || _isDead || current == RabbitState.sleeping) return;

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
        state == RabbitState.deadRight) {
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

    if (!_isHitPlaying && velocity.length > 0.01) {
      position += velocity.normalized() * moveSpeed * dt;
    }

    if (_isHitPlaying) {
      _hitElapsed += dt;
      if (_hitElapsed >= _hitStepTime * _hitFrames) {
        _isHitPlaying = false;
        setState(RabbitState.idleDown);
      }
    }
  }

  void playHit() {
    if (_isDead) return;
    setState(RabbitState.hitDown);
    // ไม่ต้องใช้ Future.delayed เพื่อคืนค่า เพราะทำใน update แล้ว (แม่นยำกว่า)
  }

  // ✅ ฟังก์ชันสำหรับชุบชีวิต
  void reset() {
    _isDead = false;
    _isHitPlaying = false;
    velocity = Vector2.zero();
    current = RabbitState.idleDown;
  }

  void playDeath() {
    if (_isDead) return;
    _isDead = true;
    velocity = Vector2.zero(); // หยุดเดิน
    setState(RabbitState.deadDown);
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
}
