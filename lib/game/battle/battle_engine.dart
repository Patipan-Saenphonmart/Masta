import '../../data/game_data.dart';
import '../components/enemy.dart';
import 'battle_models.dart';

/// Battle Engine: จัดการ state และ logic ของการต่อสู้แบบ Quiz Battle
class BattleEngine {
  final Enemy enemy;
  bool isShieldActive = true;

  // --- Battle State ---
  BattleTurn currentTurn = BattleTurn.enemyAsks;
  int turnCount = 0;
  bool battleEnded = false;
  String? winner; // 'player' หรือ 'enemy'

  // --- Config ---
  static const int maxSeconds = 15;
  static const int baseDamage = 15;

  BattleEngine({required this.enemy});

  // =====================================================================
  // PHASE 1: ศัตรูถาม → ผู้เล่นตอบ
  // =====================================================================

  /// คำนวณผลเมื่อผู้เล่นตอบคำถาม
  BattleResult processPlayerAnswer({
    required bool correct,
    required double timeUsed,
  }) {
    final subject = enemy.strongSubject; // ศัตรูถามวิชาที่ตัวเองถนัด
    GameData.recordAnswer(subject, correct);

    if (correct) {
      // ตอบถูก → โจมตีศัตรูแต่ไม่มี damage
      isShieldActive = false;
      
      battleEnded = true;
      winner = 'player';
      
      return BattleResult(
        damage: 0,
        multiplier: 1.0,
        isCounter: false,
        comboCount: GameData.comboCount,
        timeUsed: timeUsed,
        correct: true,
      );
    } else {
      // ตอบผิด → โดนศัตรูโจมตี
      final damage = baseDamage;
      return BattleResult(
        damage: damage,
        multiplier: 1.0,
        isCounter: false,
        comboCount: 0,
        timeUsed: timeUsed,
        correct: false,
      );
    }
  }

  // =====================================================================
  // PHASE 2: ผู้เล่นเลือกวิชาถาม → AI ตอบ
  // =====================================================================

  /// ผู้เล่นเลือกวิชาเพื่อถามศัตรู → AI ตอบคำถาม
  BattleResult processEnemyAnswer({required String chosenSubject}) {
    final result = enemy.answerQuestion(chosenSubject);
    final bool aiCorrect = result['correct'] as bool;
    final double aiTime = result['timeUsed'] as double;

    if (aiCorrect) {
      // AI ตอบถูก → ศัตรูโจมตีผู้เล่น
      final multiplier = _timeMultiplier(aiTime);
      final damage = baseDamage;

      return BattleResult(
        damage: damage,
        multiplier: multiplier,
        isCounter: aiTime <= 5.0,
        comboCount: 0,
        timeUsed: aiTime,
        correct: true,
      );
    } else {
      // AI ตอบผิด → ศัตรูโดนดาเมจ
      final damage = baseDamage;
      enemy.takeDamage(damage);
      if (enemy.hp <= 0) {
        battleEnded = true;
        winner = 'player';
      }

      return BattleResult(
        damage: damage,
        multiplier: 1.0,
        isCounter: false,
        comboCount: 0,
        timeUsed: aiTime,
        correct: false,
      );
    }
  }

  // =====================================================================
  // เปลี่ยนเทิร์น
  // =====================================================================

  /// สลับเทิร์น/เริ่มเทิร์นถัดไป
  void nextTurn() {
    turnCount++;
  }

  // =====================================================================
  // Helpers
  // =====================================================================

  /// คำนวณ damage multiplier จากเวลาที่ใช้ตอบ
  double _timeMultiplier(double timeUsed) {
    if (timeUsed <= 5.0) return 2.0;   // Counter Attack!
    if (timeUsed <= 10.0) return 1.5;  // ดี
    return 1.0;                         // ปกติ
  }

  /// สร้าง EnemyBattleProfile สำหรับ UI
  EnemyBattleProfile get enemyProfile => EnemyBattleProfile(
    name: enemy.enemyName,
    element: enemy.element,
    strongSubject: enemy.strongSubject,
    weakSubject: enemy.weakSubject,
    maxHp: enemy.maxHp,
    currentHp: enemy.hp,
    proficiency: enemy.proficiency,
  );

  /// รายชื่อวิชาที่ผู้เล่นสามารถเลือกถามได้
  List<String> get availableSubjects => ['ฟิสิกส์', 'เคมี', 'ชีววิทยา', 'คณิตศาสตร์'];

  /// คำนวณรางวัลเมื่อชนะ
  Map<String, int> calculateRewards() {
    final gold = 20 + (turnCount * 5) + (GameData.comboCount * 3);
    final exp = 15 + (turnCount * 3);
    return {'gold': gold, 'exp': exp};
  }

  // class การโจมตีทางกายภาพ
  Map<String, dynamic> processPhysicalAttack() {
    if (isShieldActive) {
      // Shield is up: Attack fails!
      return {
        'success': false,
        'damage': 0,
        'message': 'The shield is too thick! Scan the equation first!'
      };
    } else {
      // Shield is broken: Deal massive damage!
      int damage = baseDamage * 2; // Double damage for breaking the shield!
      enemy.takeDamage(damage);
      
      if (enemy.hp <= 0) {
        battleEnded = true;
        winner = 'player';
      }
      
      // ✅ Optional: Reset the shield if you want them to scan again for the next hit
      // isShieldActive = true; 

      return {
        'success': true,
        'damage': damage,
        'message': 'Critical Hit! You dealt $damage damage!'
      };
    }
  }
}
