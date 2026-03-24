/// โมเดลข้อมูลสำหรับ Quiz Battle System

/// เทิร์นปัจจุบันของการต่อสู้
enum BattleTurn {
  /// เฟส 1: ศัตรูถามคำถาม → ผู้เล่นตอบ
  enemyAsks,

  /// เฟส 2: ผู้เล่นเลือกวิชา → ศัตรูตอบ
  playerAsks,
}

/// ผลลัพธ์การต่อสู้ในแต่ละเทิร์น
class BattleResult {
  final int damage;
  final double multiplier;
  final bool isCounter;
  final int comboCount;
  final double timeUsed;
  final bool correct;

  const BattleResult({
    required this.damage,
    required this.multiplier,
    required this.isCounter,
    required this.comboCount,
    required this.timeUsed,
    required this.correct,
  });

  /// ดาเมจสุดท้ายหลังคูณ multiplier
  int get finalDamage => (damage * multiplier).round();
}

/// ข้อมูล proficiency ของศัตรู (ใช้ใน UI แสดงข้อมูลให้ผู้เล่น)
class EnemyBattleProfile {
  final String name;
  final String element;
  final String strongSubject;
  final String weakSubject;
  final int maxHp;
  final int currentHp;
  final Map<String, double> proficiency;

  const EnemyBattleProfile({
    required this.name,
    required this.element,
    required this.strongSubject,
    required this.weakSubject,
    required this.maxHp,
    required this.currentHp,
    required this.proficiency,
  });

  /// Icon/Color ตามธาตุ
  String get elementEmoji {
    switch (element) {
      case 'ignis': return '🔥';
      case 'arcana': return '🧪';
      case 'vita': return '🌿';
      case 'nexus': return '📐';
      default: return '⚔️';
    }
  }
}
