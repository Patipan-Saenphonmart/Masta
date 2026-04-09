import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../main_game.dart';
import '../../data/game_data.dart';
import 'player.dart';

class Enemy extends SpriteAnimationGroupComponent<RabbitState> with HasGameRef {
  // --- Stats ---
  int maxHp = 50;
  int hp = 50;
  double detectionRange = 200.0;

  // --- ✅ Quiz Battle: ข้อมูลธาตุ/วิชา ---
  final String enemyName;
  final String element;       // 'ignis', 'arcana', 'vita', 'nexus'
  final String strongSubject; // วิชาที่ถนัด
  final String weakSubject;   // วิชาที่อ่อน
  final Map<String, double> proficiency; // ความถนัดแต่ละวิชา (0.0 - 1.0)

  // --- UI Components ---
  late RectangleComponent hpBar;
  late RectangleComponent hpBg;

  // --- Flags ---
  bool alive = true;
  bool hasShield = true; // ✅ Enemy starts with a shield

  bool _isHitPlaying = false;
  double _hitElapsed = 0.0;
  final double _hitStepTime = 0.12;
  final int _hitFrames = 4;

  bool _isAttackPlaying = false;
  double _attackElapsed = 0.0;
  final double _attackStepTime = 0.15;
  final int _attackFrames = 6;

  // ✅ เพิ่มตัวแปรสำหรับระบบต่อสู้จังหวะตี
  bool hasDealtDamageThisAttack = false;
  Vector2 attackTargetDir = Vector2.zero();
  double attackCooldownTimer = 0.0; // ✅ คูลดาวน์การโจมตี
  bool isPreAttacking = false; // ✅ แจ้งสถานะกำลังเตรียมโจมตี (หน่วงเวลา)
  double preAttackTimer = 0.0; // ✅ ระยะเวลาหน่วงก่อนโจมตีจริง

  double get attackElapsed => _attackElapsed;
  double get attackStepTime => _attackStepTime;
  int get attackFrames => _attackFrames;
  bool get isAttacking => _isAttackPlaying;

  // --- Pathfinding ---
  List<Vector2> currentPath = [];
  double pathRecalculateTimer = 0.0;

  Vector2 velocity = Vector2.zero();
  Vector2 lastDirection = Vector2(0, 1);

  static final Random _rng = Random();

  Enemy({
    Vector2? position,
    this.enemyName = 'ศัตรู',
    this.element = 'ignis',
    this.strongSubject = 'ฟิสิกส์',
    this.weakSubject = 'เคมี',
    Map<String, double>? proficiency,
  })  : proficiency = proficiency ?? _defaultProficiency(element),
        super(
          position: position ?? Vector2.zero(),
          size: Vector2.all(64), // ✅ ปรับขนาดเป็น 64 ตามเฟรม
          anchor: Anchor.center,
          current: RabbitState.idleDown,
        );

  /// สร้าง proficiency map เริ่มต้นจากธาตุ
  static Map<String, double> _defaultProficiency(String element) {
    switch (element) {
      case 'ignis':
        return {'ฟิสิกส์': 0.9, 'เคมี': 0.3, 'ชีววิทยา': 0.5, 'คณิตศาสตร์': 0.5};
      case 'arcana':
        return {'ฟิสิกส์': 0.5, 'เคมี': 0.9, 'ชีววิทยา': 0.3, 'คณิตศาสตร์': 0.5};
      case 'vita':
        return {'ฟิสิกส์': 0.5, 'เคมี': 0.5, 'ชีววิทยา': 0.9, 'คณิตศาสตร์': 0.3};
      case 'nexus':
        return {'ฟิสิกส์': 0.3, 'เคมี': 0.5, 'ชีววิทยา': 0.5, 'คณิตศาสตร์': 0.9};
      default:
        return {'ฟิสิกส์': 0.5, 'เคมี': 0.5, 'ชีววิทยา': 0.5, 'คณิตศาสตร์': 0.5};
    }
  }

  /// AI ตอบคำถามวิชา [subject] — คืน {correct: bool, timeUsed: double (วินาที)}
  Map<String, dynamic> answerQuestion(String subject) {
    final skill = proficiency[subject] ?? 0.5;
    // โอกาสตอบถูกตาม proficiency
    final bool correct = _rng.nextDouble() < skill;
    // เวลาตอบ: ถนัดมาก → ตอบเร็ว (2-5วิ), ไม่ถนัด → ตอบช้า (8-14วิ)
    final double baseTime = correct ? (3.0 + (1 - skill) * 10) : (8.0 + _rng.nextDouble() * 5);
    final double timeUsed = baseTime.clamp(2.0, 14.0);
    return {'correct': correct, 'timeUsed': timeUsed};
  }

  bool get isHitPlaying => _isHitPlaying;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1. เพิ่ม Hitbox — ปรับขนาดให้เข้ากับเฟรม 64x64
    add(RectangleHitbox(
      position: Vector2(16, 16),
      size: Vector2(32, 32),
      isSolid: true,
    ));

    // 2. ✅ สร้างหลอดเลือด (HP Bar) — ย้ายให้พ้นหัวเฟรมสูงขึ้น
    hpBg = RectangleComponent(
      position: Vector2(16, -10),
      size: Vector2(32, 4),
      paint: Paint()..color = Colors.red.withOpacity(0.3),
    );
    
    hpBar = RectangleComponent(
      position: Vector2(16, -10),
      size: Vector2(32, 4),
      paint: Paint()..color = Colors.green,
    );

    add(hpBg);
    add(hpBar);

    // 3. ✅ ชั่วคราว: โหลดภาพผู้เล่น 4 ทิศทางมาใช้ทดสอบ
    final idleImage = await gameRef.images.load(GameData.playerIdleSprite);
    final runImage = await gameRef.images.load(GameData.playerRunSprite);
    final hitImage = await gameRef.images.load(GameData.playerHitSprite);
    final deadImage = await gameRef.images.load(GameData.playerDeadSprite);
    final attackImage = await gameRef.images.load(GameData.playerAttackSprite);

    final frameSize = Vector2.all(GameData.spriteFrameSize);
    final idleSheet = SpriteSheet(image: idleImage, srcSize: frameSize);
    final runSheet = SpriteSheet(image: runImage, srcSize: frameSize);
    final hitSheet = SpriteSheet(image: hitImage, srcSize: frameSize);
    final deadSheet = SpriteSheet(image: deadImage, srcSize: frameSize);
    final attackSheet = SpriteSheet(image: attackImage, srcSize: frameSize);

    final idleCount = GameData.idleFrameCount;
    final idleUpCount = GameData.idleUpFrameCount;
    final runCount = GameData.runFrameCount;
    final hitCount = GameData.hitFrameCount;
    final deadCount = GameData.deadFrameCount;

    animations = {
      RabbitState.idleDown: idleSheet.createAnimation(row: 0, stepTime: GameData.idleStepTime, from: 0, to: idleCount - 1),
      RabbitState.idleLeft: idleSheet.createAnimation(row: 1, stepTime: GameData.idleStepTime, from: 0, to: idleCount - 1),
      RabbitState.idleRight: idleSheet.createAnimation(row: 2, stepTime: GameData.idleStepTime, from: 0, to: idleCount - 1),
      RabbitState.idleUp: idleSheet.createAnimation(row: 3, stepTime: GameData.idleStepTime, from: 0, to: idleUpCount - 1),

      RabbitState.runDown: runSheet.createAnimation(row: 0, stepTime: GameData.runStepTime, from: 0, to: runCount - 1),
      RabbitState.runLeft: runSheet.createAnimation(row: 1, stepTime: GameData.runStepTime, from: 0, to: runCount - 1),
      RabbitState.runRight: runSheet.createAnimation(row: 2, stepTime: GameData.runStepTime, from: 0, to: runCount - 1),
      RabbitState.runUp: runSheet.createAnimation(row: 3, stepTime: GameData.runStepTime, from: 0, to: runCount - 1),

      RabbitState.hitDown: hitSheet.createAnimation(row: 0, stepTime: GameData.hitStepTime, from: 0, to: hitCount - 1, loop: false),
      RabbitState.hitLeft: hitSheet.createAnimation(row: 1, stepTime: GameData.hitStepTime, from: 0, to: hitCount - 1, loop: false),
      RabbitState.hitRight: hitSheet.createAnimation(row: 2, stepTime: GameData.hitStepTime, from: 0, to: hitCount - 1, loop: false),
      RabbitState.hitUp: hitSheet.createAnimation(row: 3, stepTime: GameData.hitStepTime, from: 0, to: hitCount - 1, loop: false),

      RabbitState.deadDown: deadSheet.createAnimation(row: 0, stepTime: GameData.deadStepTime, from: 0, to: deadCount - 1, loop: false),
      RabbitState.deadLeft: deadSheet.createAnimation(row: 1, stepTime: GameData.deadStepTime, from: 0, to: deadCount - 1, loop: false),
      RabbitState.deadRight: deadSheet.createAnimation(row: 2, stepTime: GameData.deadStepTime, from: 0, to: deadCount - 1, loop: false),
      RabbitState.deadUp: deadSheet.createAnimation(row: 3, stepTime: GameData.deadStepTime, from: 0, to: deadCount - 1, loop: false),

      RabbitState.attackDown: attackSheet.createAnimation(row: 0, stepTime: GameData.attackStepTime, from: 0, to: GameData.attackFrameCount - 1, loop: false),
      RabbitState.attackLeft: attackSheet.createAnimation(row: 1, stepTime: GameData.attackStepTime, from: 0, to: GameData.attackFrameCount - 1, loop: false),
      RabbitState.attackRight: attackSheet.createAnimation(row: 2, stepTime: GameData.attackStepTime, from: 0, to: GameData.attackFrameCount - 1, loop: false),
      RabbitState.attackUp: attackSheet.createAnimation(row: 3, stepTime: GameData.attackStepTime, from: 0, to: GameData.attackFrameCount - 1, loop: false),
    };
    
    current = RabbitState.idleDown;
  }

  // ✅ ฟังก์ชันโดนดาเมจ (ส่งตำแหน่งคนตีมาด้วยเพื่อหันหน้าไปทางคนตี)
  void takeDamage(int damage, {Vector2? attackerPos}) {
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
      playHit(attackerPos: attackerPos);
    }
  }

  void updateAnimationState() {
    if (!alive) return;
    
    if (_isHitPlaying || _isAttackPlaying) {
      // ให้มันแช่ท่าเดิมตอนตีหรือถูกตีจนเพลย์จบ
      return; 
    }

    if (velocity.length > 0.01) {
      if (velocity.x.abs() >= velocity.y.abs()) {
        if (velocity.x > 0) {
          current = RabbitState.runRight;
        } else {
          current = RabbitState.runLeft;
        }
      } else {
        if (velocity.y > 0) {
          current = RabbitState.runDown;
        } else {
          current = RabbitState.runUp;
        }
      }
      lastDirection = velocity.normalized();
    } else {
      if (lastDirection.x.abs() >= lastDirection.y.abs()) {
        if (lastDirection.x > 0) {
          current = RabbitState.idleRight;
        } else {
          current = RabbitState.idleLeft;
        }
      } else {
        if (lastDirection.y > 0) {
          current = RabbitState.idleDown;
        } else {
          current = RabbitState.idleUp;
        }
      }
    }
  }

  void playHit({Vector2? attackerPos}) {
    if (!_isHitPlaying && alive && !_isAttackPlaying) {
      _isHitPlaying = true;
      _hitElapsed = 0.0;
      
      Vector2 hitDir = lastDirection;
      if (attackerPos != null) {
        hitDir = (attackerPos - position).normalized();
      }

      if (hitDir.x.abs() >= hitDir.y.abs()) {
        current = hitDir.x > 0 ? RabbitState.hitRight : RabbitState.hitLeft;
      } else {
        current = hitDir.y > 0 ? RabbitState.hitDown : RabbitState.hitUp;
      }
    }
  }

  void playAttack() {
    if (!_isAttackPlaying && alive && !_isHitPlaying) {
      _isAttackPlaying = true;
      _attackElapsed = 0.0;
      if (attackTargetDir.x.abs() >= attackTargetDir.y.abs()) {
        current = attackTargetDir.x > 0 ? RabbitState.attackRight : RabbitState.attackLeft;
      } else {
        current = attackTargetDir.y > 0 ? RabbitState.attackDown : RabbitState.attackUp;
      }
    }
  }

  void die() {
    if (!alive) return;
    alive = false;
    
    // ซ่อนหลอดเลือดเมื่อตาย
    hpBar.removeFromParent();
    hpBg.removeFromParent();

    if (lastDirection.x.abs() >= lastDirection.y.abs()) {
      current = lastDirection.x > 0 ? RabbitState.deadRight : RabbitState.deadLeft;
    } else {
      current = lastDirection.y > 0 ? RabbitState.deadDown : RabbitState.deadUp;
    }
    
    // ✅ แจ้งเตือนเมนเกมเพื่อดรอปของและเริ่มคิวเกิดใหม่
    if (gameRef is RabbitGame) {
      (gameRef as RabbitGame).handleEnemyDeath(this);
    }

    Future.delayed(const Duration(seconds: 1), () {
      removeFromParent();
    });
  }

  @override
  void update(double dt) {
    // ✅ หยุดแอนิเมชันศัตรูทันที ถ้าโลกถูกแช่แข็ง (The World)
    if (gameRef is RabbitGame && (gameRef as RabbitGame).isWorldFrozen) {
      return; 
    }
    super.update(dt);

    if (!alive) return;

    if (attackCooldownTimer > 0) {
      attackCooldownTimer -= dt;
    }

    if (_isHitPlaying) {
      _hitElapsed += dt;
      if (_hitElapsed >= GameData.hitStepTime * GameData.hitFrameCount) {
        _isHitPlaying = false;
        _hitElapsed = 0.0;
      }
    }

    if (_isAttackPlaying) {
      _attackElapsed += dt;
      if (_attackElapsed >= GameData.attackStepTime * GameData.attackFrameCount) {
        _isAttackPlaying = false;
        _attackElapsed = 0.0;
        // ✅ เลือกระยะเวลาคูลดาวน์ตามผลการโจมตี
        if (hasDealtDamageThisAttack) {
          attackCooldownTimer = 0.5; // ถ้าตีโดนผู้เล่น: คูลดาวน์นานขึ้น (พักเหนื่อย)
        } else {
          attackCooldownTimer = 0.25; // ถ้าตีไม่โดน (วืด): คูลดาวน์สั้นลง (ก้าวร้าวขึ้น)
        }
        
        hasDealtDamageThisAttack = false;
      }
    }

    updateAnimationState();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // ✅ วาดกรอบ Hitbox สำหรับรับดาเมจ (Hurtbox Margin) ให้อยู่ส่วนเท้า
    // จุดศูนย์กลางของ Component คือ 32, 32 (จากขนาด 64x64)
    // เลื่อนลงไปที่เท้า (center y = 48, size 32x24)
    canvas.drawRect(
      Rect.fromCenter(center: const Offset(25, 37), width: 12, height: 6),
      Paint()
        ..color = const Color.fromRGBO(76, 175, 80, 0.5) // Colors.green.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // ✅ แสดงวงกลมบ่งบอกระยะ "Attack Trigger Range" (40.0) หรือระยะเข้าโจมตี
    canvas.drawCircle(
      const Offset(32, 32), // จุดศูนย์กลางของตัวละคร 64x64
      40.0,
      Paint()
        ..color = const Color.fromRGBO(255, 193, 7, 0.3) // สีเหลืองโปร่งแสง
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}