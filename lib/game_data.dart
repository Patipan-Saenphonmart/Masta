import 'package:flutter/foundation.dart';
import 'models/quest.dart'; // ✅ Import Quest

class GameData {
  static int playerGold = 99999;
  static int playerLevel = 1;
  static int currentExp = 0; // ✅ เพิ่มค่าประสบการณ์
  
  static List<String> inventory = []; 
  static List<String> unlockedSkills = [];
  
  static List<String> equippedItems = []; 
  // ✅ เพิ่ม: สกิลที่ติดตั้งอยู่ (จำกัดจำนวนได้ในอนาคต)
  static List<String> equippedSkills = []; 

  // ✅ ระบบเควสต์
  static List<Quest> activeQuests = [
    Quest(
      id: "q1",
      title: "ปราบมอนสเตอร์",
      description: "เอาชนะศัตรู 3 ตัว",
      targetAction: "kill_monster",
      targetCount: 3,
      rewardGold: 500,
      rewardExp: 300,
    ),
    Quest(
      id: "q2",
      title: "นักปราชญ์",
      description: "ตอบคำถามให้ถูกต้อง 5 ข้อ",
      targetAction: "answer_correct",
      targetCount: 5,
      rewardGold: 1000,
      rewardExp: 500,
    ),
  ];

  static ValueNotifier<int> questUpdateNotifier = ValueNotifier(0);

  // --- Base Stats ---
  static int baseHp = 100;
  static int baseStamina = 100;
  static int baseDefense = 0;
  static int baseAgility = 20;

  // --- Calculated Stats ---
  static int get maxHp {
    int bonus = 0;
    if (equippedItems.contains("เกราะวิเศษ (Magic Armor)")) bonus += 50; 
    return baseHp + bonus;
  }

  static int get stamina => baseStamina; 

  static int get defense {
    int bonus = 0;
    if (equippedItems.contains("เกราะวิเศษ (Magic Armor)")) bonus += 10;
    return baseDefense + bonus;
  }

  static int get agility {
    int bonus = 0;
    int penalty = 0;
    
    if (equippedItems.contains("เกราะวิเศษ (Magic Armor)")) penalty += 5; 
    if (equippedItems.contains("ดาบสายฟ้า (Thunder Sword)")) bonus += 2;

    return (baseAgility + bonus - penalty).clamp(0, 100);
  }

  // --- Functions ---

  static bool buyItem(String itemName, int price) {
    if (playerGold >= price) {
      playerGold -= price;
      inventory.add(itemName);
      return true;
    }
    return false;
  }

  static bool buySkill(String skillName, int price, int requiredLevel) {
    if (playerLevel < requiredLevel) return false;
    if (playerGold >= price && !unlockedSkills.contains(skillName)) {
      playerGold -= price;
      unlockedSkills.add(skillName);
      return true;
    }
    return false;
  }

  // --- Equip System ---

  static void equipItem(String itemName) {
    if (inventory.contains(itemName) && !equippedItems.contains(itemName)) {
      equippedItems.add(itemName);
    }
  }

  static void unequipItem(String itemName) {
    equippedItems.remove(itemName);
  }

  // ✅ ฟังก์ชันติดตั้งสกิล (จำกัด 4 ช่อง)
  static bool equipSkill(String skillName) {
    if (unlockedSkills.contains(skillName) && !equippedSkills.contains(skillName)) {
      if (equippedSkills.length < 4) {
        equippedSkills.add(skillName);
        return true;
      }
    }
    return false; // สล็อตเต็มหรือมีแล้ว
  }

  static void unequipSkill(String skillName) {
    equippedSkills.remove(skillName);
  }

  static bool isEquipped(String itemName) => equippedItems.contains(itemName);
  // ✅ เช็คว่าสกิลติดตั้งอยู่ไหม
  static bool isSkillEquipped(String skillName) => equippedSkills.contains(skillName);
  
  static bool hasItem(String itemName) => inventory.contains(itemName);
  static bool hasSkill(String skillName) => unlockedSkills.contains(skillName);

  static int get expToNextLevel => playerLevel * 100;

  static void addExp(int amount) {
    currentExp += amount;
    while (currentExp >= expToNextLevel) {
      currentExp -= expToNextLevel;
      levelUp();
    }
  }

  static void levelUp() {
    playerLevel++;
    baseHp += 20; // เพิ่ม Max HP ทุกครั้งที่เลเวลอัพ
    baseStamina += 10;
  }

  // =====================================================================
  // ✅ Quiz Battle System Data
  // =====================================================================

  /// Combo: ตอบถูกติดต่อกัน
  static int comboCount = 0;
  static int maxCombo = 0;

  /// สถิติการตอบคำถาม: { 'ฟิสิกส์': {'correct': 5, 'wrong': 2, 'total': 7} }
  static Map<String, Map<String, int>> questionStats = {};

  /// บันทึกความรู้ (Knowledge Journal)
  static List<Map<String, dynamic>> knowledgeJournal = [];

  /// ค่าความชำนาญแต่ละวิชา (0-100)
  static Map<String, int> subjectMastery = {
    'ฟิสิกส์': 0,
    'เคมี': 0,
    'ชีววิทยา': 0,
    'คณิตศาสตร์': 0,
  };

  /// บันทึกผลการตอบคำถาม
  static void recordAnswer(String subject, bool correct) {
    questionStats.putIfAbsent(subject, () => {'correct': 0, 'wrong': 0, 'total': 0});
    final stats = questionStats[subject]!;
    stats['total'] = (stats['total'] ?? 0) + 1;
    if (correct) {
      stats['correct'] = (stats['correct'] ?? 0) + 1;
      comboCount++;
      if (comboCount > maxCombo) maxCombo = comboCount;
      // เพิ่ม mastery
      subjectMastery[subject] = ((subjectMastery[subject] ?? 0) + 2).clamp(0, 100);
      
      // ✅ อัปเดตเควสต์ตอบคำถามถูก
      updateQuestProgress('answer_correct', 1);
    } else {
      stats['wrong'] = (stats['wrong'] ?? 0) + 1;
      comboCount = 0; // Reset combo
      // ลด mastery เล็กน้อย
      subjectMastery[subject] = ((subjectMastery[subject] ?? 0) - 1).clamp(0, 100);
    }
  }

  /// บันทึกคำถามลง Knowledge Journal
  static void recordQuestion(Map<String, dynamic> question, String subject, bool answeredCorrectly) {
    knowledgeJournal.add({
      'question': question,
      'subject': subject,
      'correct': answeredCorrectly,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// คำนวณ combo multiplier
  static double get comboMultiplier {
    if (comboCount >= 5) return 2.0;
    if (comboCount >= 3) return 1.5;
    if (comboCount >= 2) return 1.2;
    return 1.0;
  }

  // =====================================================================
  // ✅ ดำเนินการ Quest
  // =====================================================================
  static void updateQuestProgress(String actionType, int amount) {
    bool updated = false;
    for (var quest in activeQuests) {
      if (!quest.isCompleted && quest.targetAction == actionType) {
        quest.currentCount += amount;
        if (quest.currentCount >= quest.targetCount) {
          quest.currentCount = quest.targetCount;
          quest.isCompleted = true;
          // มอบรางวัล
          playerGold += quest.rewardGold;
          addExp(quest.rewardExp);
          print("🎉 เควสต์สำเร็จ: ${quest.title} ได้รับ ${quest.rewardGold} G และ ${quest.rewardExp} EXP");
        }
        updated = true;
      }
    }
    if (updated) {
      questUpdateNotifier.value++;
    }
  }

  // =====================================================================
  // ✅ Save / Load System
  // =====================================================================

  static Map<String, dynamic> toJson() {
    return {
      'playerGold': playerGold,
      'playerLevel': playerLevel,
      'currentExp': currentExp,
      'inventory': inventory,
      'unlockedSkills': unlockedSkills,
      'equippedItems': equippedItems,
      'equippedSkills': equippedSkills,
      'baseHp': baseHp,
      'baseStamina': baseStamina,
      'baseDefense': baseDefense,
      'baseAgility': baseAgility,
      'maxCombo': maxCombo,
      'subjectMastery': subjectMastery,
      'questionStats': questionStats,
      'knowledgeJournal': knowledgeJournal, 
      'activeQuests': activeQuests.map((q) => q.toJson()).toList(), // ✅ เซฟเควสต์
    };
  }

  static void fromJson(Map<String, dynamic> json) {
    playerGold = json['playerGold'] ?? 99999;
    playerLevel = json['playerLevel'] ?? 1;
    currentExp = json['currentExp'] ?? 0;
    
    inventory = List<String>.from(json['inventory'] ?? []);
    unlockedSkills = List<String>.from(json['unlockedSkills'] ?? []);
    equippedItems = List<String>.from(json['equippedItems'] ?? []);
    equippedSkills = List<String>.from(json['equippedSkills'] ?? []);
    
    baseHp = json['baseHp'] ?? 100;
    baseStamina = json['baseStamina'] ?? 100;
    baseDefense = json['baseDefense'] ?? 0;
    baseAgility = json['baseAgility'] ?? 20;
    
    maxCombo = json['maxCombo'] ?? 0;
    
    if (json['subjectMastery'] != null) {
      subjectMastery = Map<String, int>.from(json['subjectMastery']);
    }
    if (json['questionStats'] != null) {
      Map<String, dynamic> qs = json['questionStats'];
      questionStats = qs.map((k, v) => MapEntry(k, Map<String, int>.from(v)));
    }
    if (json['knowledgeJournal'] != null) {
      knowledgeJournal = List<Map<String, dynamic>>.from(json['knowledgeJournal']);
    }
    if (json['activeQuests'] != null) {
      activeQuests = (json['activeQuests'] as List).map((q) => Quest.fromJson(q)).toList();
      questUpdateNotifier.value++;
    }
  }

  // ✅ รีเซ็ตข้อมูลทั้งหมดกลับเป็นค่าเริ่มต้นเวลาเริ่มเกมใหม่
  static void reset() {
    playerGold = 1000; // เริ่มต้นมีเงิน 1000 G
    playerLevel = 1;
    currentExp = 0;
    
    inventory.clear();
    unlockedSkills.clear();
    equippedItems.clear();
    equippedSkills.clear();
    
    baseHp = 100;
    baseStamina = 100;
    baseDefense = 0;
    baseAgility = 20;
    
    maxCombo = 0;
    comboCount = 0;
    subjectMastery = {'ฟิสิกส์': 0, 'เคมี': 0, 'ชีววิทยา': 0, 'คณิตศาสตร์': 0};
    questionStats.clear();
    knowledgeJournal.clear();
    
    activeQuests = [
      Quest(id: "q1", title: "ปราบมอนสเตอร์", description: "เอาชนะศัตรู 3 ตัว", targetAction: "kill_monster", targetCount: 3, rewardGold: 500, rewardExp: 300),
      Quest(id: "q2", title: "นักปราชญ์", description: "ตอบคำถามให้ถูกต้อง 5 ข้อ", targetAction: "answer_correct", targetCount: 5, rewardGold: 1000, rewardExp: 500),
    ];
    questUpdateNotifier.value++;
  }
}