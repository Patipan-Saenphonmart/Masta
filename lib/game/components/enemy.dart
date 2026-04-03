import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../rabbit_game.dart';

enum EnemyState { idle, walk, run, hit, dead }

class Enemy extends SpriteAnimationGroupComponent<EnemyState> with HasGameRef {
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
  bool _isHitPlaying = false;
  double _hitElapsed = 0.0;
  final double _hitStepTime = 0.12;
  final int _hitFrames = 4;

  // --- Pathfinding ---
  List<Vector2> currentPath = [];
  double pathRecalculateTimer = 0.0;

  Vector2 velocity = Vector2.zero();

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
          current: EnemyState.idle,
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

    // 3. ✅ โหลดภาพและ Animation ตามธาตุมอนสเตอร์ (64x64 Frames)
    String prefix = 'battle_enemy_$element';
    
    // ✅ จัดการเรื่องชื่อไฟล์ (อาคาน่าและไวต้าใช้ _idle แต่พ่นไฟใช้ชื่อหลักเลย)
    String idleFile = element == 'ignis' || element == 'nexus' ? '$prefix.png' : '${prefix}_idle.png';
    String walkFile = '${prefix}_walk.png';
    String hitFile = '${prefix}_hit.png';
    String deadFile = '${prefix}_dead.png';

    final idleImage = await gameRef.images.load(idleFile);
    final walkImage = await gameRef.images.load(walkFile);
    final hitImage = await gameRef.images.load(hitFile);
    final deadImage = await gameRef.images.load(deadFile);

    // การกำหนดจำนวนเฟรมต่อธาตุ (อิงจากขนาดภาพที่ตรวจพบ 320=5f, 512=8f, 384=6f)
    int idleFrames = 5;
    int walkFrames = 8;
    int hitFrames = 5;
    int deadFrames = 6;

    final idleAnim = SpriteAnimation.fromFrameData(
      idleImage,
      SpriteAnimationData.sequenced(
        amount: idleFrames,
        stepTime: 0.3,
        textureSize: Vector2(64, 64),
      ),
    );
    
    final walkAnim = SpriteAnimation.fromFrameData(
      walkImage,
      SpriteAnimationData.sequenced(
        amount: walkFrames,
        stepTime: 0.15,
        textureSize: Vector2(64, 64),
      ),
    );

    final hitAnim = SpriteAnimation.fromFrameData(
      hitImage,
      SpriteAnimationData.sequenced(
        amount: hitFrames,
        stepTime: _hitStepTime,
        textureSize: Vector2(64, 64),
        loop: false,
      ),
    );

    final deadAnim = SpriteAnimation.fromFrameData(
      deadImage,
      SpriteAnimationData.sequenced(
        amount: deadFrames,
        stepTime: 0.15,
        textureSize: Vector2(64, 64),
        loop: false,
      ),
    );

    animations = {
      EnemyState.idle: idleAnim,
      EnemyState.walk: walkAnim,
      EnemyState.run: walkAnim, // Overwatch run ใช้ walk เหมือนกัน
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