class GameData {
  static int playerGold = 99999;
  static int playerLevel = 1;
  
  static List<String> inventory = []; 
  static List<String> unlockedSkills = [];
  
  static List<String> equippedItems = []; 
  // ✅ เพิ่ม: สกิลที่ติดตั้งอยู่ (จำกัดจำนวนได้ในอนาคต)
  static List<String> equippedSkills = []; 

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

  static void levelUp() {
    playerLevel++;
  }
}