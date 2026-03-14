import 'package:flutter/material.dart';
import 'package:flame/widgets.dart'; 
import 'package:flame/components.dart';
import 'game_data.dart';
import 'game/rabbit_game.dart'; 

class CharacterPage extends StatefulWidget {
  const CharacterPage({super.key});

  @override
  State<CharacterPage> createState() => _CharacterPageState();
}

class _CharacterPageState extends State<CharacterPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2 Tabs: Items, Skills
  }

  // เช็คว่าใส่เกราะอยู่ไหม
  bool get _isArmorEquipped => GameData.isEquipped("เกราะวิเศษ (Magic Armor)");
  // เช็คว่าถือดาบอยู่ไหม (เพื่อคำนวณ ATK โชว์)
  bool get _isSwordEquipped => GameData.isEquipped("ดาบสายฟ้า (Thunder Sword)");

  void _toggleEquipItem(String itemName) {
    setState(() {
      if (GameData.isEquipped(itemName)) {
        GameData.unequipItem(itemName);
      } else {
        GameData.equipItem(itemName);
      }
    });
  }

  void _toggleEquipSkill(String skillName) {
    setState(() {
      if (GameData.isSkillEquipped(skillName)) {
        GameData.unequipSkill(skillName);
      } else {
        // ลองติดตั้ง ถ้าเต็มจะคืนค่า false
        bool success = GameData.equipSkill(skillName);
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("เลือกสกิลได้สูงสุด 4 สกิลเท่านั้น!")),
          );
        }
      }
    });
  }

  void _startAdventure() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RabbitGamePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/images/bg_quiz.png'),
          fit: BoxFit.cover)
          
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildCharacterProfile(),
            const SizedBox(height: 20),
            
            // --- ส่วนล่าง: Tab View ---
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -5))],
                ),
                child: Column(
                  children: [
                    // Tab Bar
                    TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF3E2723),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.amber,
                      tabs: const [
                        Tab(text: "อุปกรณ์ (Items)"),
                        Tab(text: "สกิล (Skills)"),
                      ],
                    ),
                    const SizedBox(height: 10),
                    
                    // Tab Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Inventory
                          _buildInventoryGrid(),
                          // Tab 2: Skills
                          _buildSkillsGrid(),
                        ],
                      ),
                    ),
                    
                    // ปุ่มเริ่มเกม — เพิ่ม bottom padding ตาม Navigation Bar
                    Padding(
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 20,
                        bottom: 20 + MediaQuery.of(context).padding.bottom,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed: _startAdventure,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 5,
                          ),
                          icon: const Icon(Icons.explore, size: 28, color: Colors.white),
                          label: const Text(
                            "ออกผจญภัย!",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterProfile() {
    final String spritePath = _isArmorEquipped ? 'rabbit_idle_armor.png' : 'rabbit_idle.png';
    
    // ✅ แก้ไข: ปรับขนาด Texture Size ให้ถูกต้องตามไฟล์ภาพ
    // ถ้าใส่เกราะ ใช้ขนาด 64.0 (เพราะภาพละเอียดกว่า), ถ้าไม่ใส่ใช้ 32.0
    final double textureSize = _isArmorEquipped ? 32.0 : 32.0;

    // ✅ คำนวณ ATK เพื่อโชว์ (30 คือ base, +20 ถ้ามีดาบ)
    int currentAtk = 30 + (_isSwordEquipped ? 20 : 0);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber, width: 4),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
              ),
            ),
            SizedBox(
              width: 120,
              height: 120,
              child: SpriteAnimationWidget.asset(
                path: spritePath,
                playing: true,
                data: SpriteAnimationData.sequenced(
                  amount: 4,          
                  stepTime: 0.2,      
                  textureSize: Vector2.all(textureSize), // ✅ ใช้ค่าที่ถูกต้องตามชุด
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  "Lv.${GameData.playerLevel}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 15),
        Text(
          _isArmorEquipped ? "Armored Hero" : "Hero Rabbit",
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // โชว์ค่า Status จริงจาก GameData
            _buildStatBadge("HP", "${GameData.maxHp}", Icons.favorite, Colors.redAccent),
            // ✅ โชว์ ATK
            _buildStatBadge("ATK", "$currentAtk", Icons.map, Colors.orange),
            _buildStatBadge("DEF", "${GameData.defense}", Icons.shield, Colors.blueAccent),
            _buildStatBadge("AGI", "${GameData.agility}", Icons.directions_run, Colors.greenAccent),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBadge(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 6),
        Text(
          "$label: $value",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  // --- Grid สำหรับไอเทม ---
  Widget _buildInventoryGrid() {
    if (GameData.inventory.isEmpty) {
      return const Center(child: Text("ไม่มีไอเทมในกระเป๋า", style: TextStyle(color: Colors.grey)));
    }

    final Map<String, int> inventoryCounts = {};
    for (var item in GameData.inventory) {
      inventoryCounts[item] = (inventoryCounts[item] ?? 0) + 1;
    }
    final uniqueItems = inventoryCounts.keys.toList();

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.8, 
      ),
      itemCount: uniqueItems.length,
      itemBuilder: (context, index) {
        final itemName = uniqueItems[index];
        final count = inventoryCounts[itemName] ?? 1;
        final isEquipped = GameData.isEquipped(itemName);
        
        return InkWell(
          onTap: () => _toggleEquipItem(itemName),
          child: _buildSelectableCard(itemName, count, isEquipped, isSkill: false),
        );
      },
    );
  }

  // --- Grid สำหรับสกิล ---
  Widget _buildSkillsGrid() {
    if (GameData.unlockedSkills.isEmpty) {
      return const Center(child: Text("ยังไม่ได้เรียนรู้สกิลใดๆ", style: TextStyle(color: Colors.grey)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.8, 
      ),
      itemCount: GameData.unlockedSkills.length,
      itemBuilder: (context, index) {
        final skillName = GameData.unlockedSkills[index];
        final isEquipped = GameData.isSkillEquipped(skillName);
        
        return InkWell(
          onTap: () => _toggleEquipSkill(skillName),
          child: _buildSelectableCard(skillName, 1, isEquipped, isSkill: true),
        );
      },
    );
  }

  // การ์ดแสดงผล (ใช้ร่วมกันทั้ง Item และ Skill)
  Widget _buildSelectableCard(String name, int count, bool isEquipped, {required bool isSkill}) {
    IconData icon = Icons.help_outline;
    Color iconColor = Colors.grey;
    String displayName = name;

    if (isSkill) {
      if (name == 'fireball') { icon = Icons.whatshot; iconColor = Colors.orange; displayName = "Fireball"; }
      else if (name == 'heal') { icon = Icons.favorite; iconColor = Colors.pink; displayName = "Heal"; }
      else if (name == 'dash') { icon = Icons.run_circle; iconColor = Colors.blue; displayName = "Dash"; }
      else if (name == 'ice_blast') { icon = Icons.ac_unit; iconColor = Colors.cyan; displayName = "Ice Blast"; }
    } else {
      if (name.contains("ยา")) { icon = Icons.local_drink; iconColor = Colors.red; }
      else if (name.contains("ดาบ")) { icon = Icons.flash_on; iconColor = Colors.amber; }
      else if (name.contains("เกราะ")) { icon = Icons.shield; iconColor = Colors.blue; }
      displayName = name.split(" ")[0];
    }

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: isEquipped ? (isSkill ? Colors.purple.shade100 : Colors.amber.shade100) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isEquipped ? (isSkill ? Colors.purple : Colors.amber) : const Color(0xFFA1887F), 
              width: isEquipped ? 3 : 2
            ),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: iconColor),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  displayName, 
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4E342E)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (count > 1)
          Positioned(
            bottom: 8, right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.brown,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white),
              ),
              child: Text("x$count", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        if (isEquipped)
          Positioned(
            top: 8, right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 16, color: Colors.white),
            ),
          ),
      ],
    );
  }
}