import 'package:flutter/material.dart';
import 'package:flame/widgets.dart'; 
import 'package:flame/components.dart';
import '../data/game_data.dart';
import '../game/main_game.dart'; 
import '../utils/audio_manager.dart'; // ✅ Import AudioManager

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
    AudioManager().playBgm(AudioManager.bgmMenuPages); // ✅ BGM หน้า Character
  }

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
    AudioManager().playSfx(AudioManager.sfxUiClick); // ✅ SFX
    AudioManager().stopBgm(); // ✅ หยุด BGM ก่อนเข้าเกม
    final bool showCutscene = !GameData.hasSeenIntroCutscene;
    
    // ✅ Close the overlay dialog first before navigating
    Navigator.pop(context); 
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RabbitGamePage(showIntroCutscene: showCutscene),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.90, // Taller for vertical UI
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Very dark retro background
          border: Border.all(color: Colors.grey.shade500, width: 4), // Sharp border
          borderRadius: BorderRadius.circular(8), // Small radius for retro feel
        ),
        child: Column(
          children: [
            // --- 1. Header (Close Button) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () {
                    AudioManager().playSfx(AudioManager.sfxUiClick);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            
            // --- 2. Vertical Character Display ---
            _buildVerticalCharacterProfile(),
            const SizedBox(height: 12),
            
            // --- 3. Inventory & Skills Area ---
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C), // Slightly lighter panel
                  border: const Border(top: BorderSide(color: Colors.black, width: 4)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Tab Bar (Retro Style)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        border: Border.all(color: Colors.grey.shade600, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey.shade500,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        tabs: const [
                          Tab(icon: Icon(Icons.backpack, size: 18), text: "อุปกรณ์"),
                          Tab(icon: Icon(Icons.auto_awesome, size: 18), text: "สกิล"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Tab Content (Grids)
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildInventoryGrid(),
                          _buildSkillsGrid(),
                        ],
                      ),
                    ),
                    
                    // --- 4. Start Button ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.black, width: 4)),
                        color: Color(0xFF1E1E1E),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: _startAdventure,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade800,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), // Sharp retro button
                            side: const BorderSide(color: Colors.lightGreen, width: 2), // Outline
                          ),
                          icon: const Icon(Icons.play_arrow, size: 28, color: Colors.white),
                          label: const Text(
                            "ออกผจญภัย!",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
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

  // ✅ New Vertical Profile Layout (ใช้ GameData sprite config)
  Widget _buildVerticalCharacterProfile() {
    int currentAtk = 30 + (_isSwordEquipped ? 20 : 0);
    final double frameSize = GameData.spriteFrameSize;

    return Column(
      children: [
        // Character Name (จาก GameData)
        Text(
          GameData.playerName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),
        
        // Sprite on a "Pedestal"
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Dark shadow/pedestal base
            Container(
              width: 90,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(100), // Ellipse shadow
              ),
            ),
            SizedBox(
              width: 120,
              height: 120,
              child: SpriteAnimationWidget.asset(
                path: GameData.playerIdleSprite,
                playing: true,
                data: SpriteAnimationData.sequenced(
                  amount: GameData.idleFrameCount,
                  stepTime: GameData.idleStepTime,
                  textureSize: Vector2.all(frameSize),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // Compact Stats Board (2x2 Grid style)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black54,
            border: Border.all(color: Colors.grey.shade700, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCompactStat("Lv", "${GameData.playerLevel}", Colors.amber),
                  _buildCompactStat("HP", "${GameData.maxHp}", Colors.redAccent),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCompactStat("ATK", "$currentAtk", Colors.orange),
                  _buildCompactStat("DEF", "${GameData.defense}", Colors.blueAccent),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ Smaller, text-based stat builder for the vertical board
  Widget _buildCompactStat(String label, String value, Color color) {
    return SizedBox(
      width: 100,
      child: Row(
        children: [
          Text("$label: ", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

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
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 items per row for a more compact vertical list
        crossAxisSpacing: 8, 
        mainAxisSpacing: 8, 
        childAspectRatio: 1.0, // Square boxes
      ),
      itemCount: uniqueItems.length,
      itemBuilder: (context, index) {
        final itemName = uniqueItems[index];
        final count = inventoryCounts[itemName] ?? 1;
        final isEquipped = GameData.isEquipped(itemName);
        
        return GestureDetector(
          onTap: () => _toggleEquipItem(itemName),
          onLongPress: () => _showItemDetailSheet(itemName, isSkill: false),
          child: _buildSelectableCard(itemName, count, isEquipped, isSkill: false),
        );
      },
    );
  }

  Widget _buildSkillsGrid() {
    if (GameData.unlockedSkills.isEmpty) {
      return const Center(child: Text("ยังไม่ได้เรียนรู้สกิลใดๆ", style: TextStyle(color: Colors.grey)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 skills per row
        crossAxisSpacing: 8, 
        mainAxisSpacing: 8, 
        childAspectRatio: 1.0, 
      ),
      itemCount: GameData.unlockedSkills.length,
      itemBuilder: (context, index) {
        final skillName = GameData.unlockedSkills[index];
        final isEquipped = GameData.isSkillEquipped(skillName);
        
        return GestureDetector(
          onTap: () => _toggleEquipSkill(skillName),
          onLongPress: () => _showItemDetailSheet(skillName, isSkill: true),
          child: _buildSelectableCard(skillName, 1, isEquipped, isSkill: true),
        );
      },
    );
  }

  void _showItemDetailSheet(String name, {required bool isSkill}) {
    String description = '';
    String effect = '';
    IconData icon = Icons.help_outline;
    Color iconColor = Colors.grey;

    if (isSkill) {
      switch (name) {
        case 'fireball': icon = Icons.whatshot; iconColor = Colors.orange; description = 'ยิงลูกไฟใส่ศัตรู'; effect = 'สร้างความเสียหายสูง'; break;
        case 'heal': icon = Icons.favorite; iconColor = Colors.pink; description = 'ร่ายเวทย์รักษาบาดแผล'; effect = 'ฟื้นฟู HP 30%'; break;
        case 'dash': icon = Icons.run_circle; iconColor = Colors.blue; description = 'พุ่งตัวไปข้างหน้าอย่างรวดเร็ว'; effect = 'เพิ่มความเร็ว x2.5'; break;
        case 'ice_blast': icon = Icons.ac_unit; iconColor = Colors.cyan; description = 'แช่แข็งศัตรูรอบตัว'; effect = 'หยุด 3 วินาที'; break;
      }
    } else {
      if (name.contains('ยา')) { icon = Icons.local_drink; iconColor = Colors.red; description = 'ยาเพิ่มเลือด'; effect = 'ฟื้นฟู HP 50 หน่วย'; }
      else if (name.contains('ดาบ')) { icon = Icons.flash_on; iconColor = Colors.amber; description = 'ดาบสายฟ้า'; effect = 'ATK +20, AGI +2'; }
      else if (name.contains('เกราะ')) { icon = Icons.shield; iconColor = Colors.blue; description = 'เกราะวิเศษ'; effect = 'HP +50, DEF +10, AGI -5'; }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Dark match
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          border: Border(top: BorderSide(color: Colors.grey.shade500, width: 4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: iconColor, width: 2),
                ),
                child: Icon(icon, size: 36, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(isSkill ? 'สกิล' : 'อุปกรณ์', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(description.isNotEmpty ? description : 'ไม่มีคำอธิบาย',
                  style: const TextStyle(fontSize: 15, color: Colors.white)),
                if (effect.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.auto_awesome, size: 16, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text(effect, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber)),
                  ]),
                ],
              ]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), // Sharp retro button
                  side: BorderSide(color: Colors.grey.shade600, width: 2),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  if (isSkill) {
                    _toggleEquipSkill(name);
                  } else {
                    _toggleEquipItem(name);
                  }
                },
                child: Text(
                  isSkill
                    ? (GameData.isSkillEquipped(name) ? 'ถอดสกิล' : 'ติดตั้งสกิล')
                    : (GameData.isEquipped(name) ? 'ถอดอุปกรณ์' : 'สวมใส่'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ New Square, Retro Card Design
  Widget _buildSelectableCard(String name, int count, bool isEquipped, {required bool isSkill}) {
    IconData icon = Icons.help_outline;
    Color iconColor = Colors.grey;

    if (isSkill) {
      if (name == 'fireball') { icon = Icons.whatshot; iconColor = Colors.orange; }
      else if (name == 'heal') { icon = Icons.favorite; iconColor = Colors.pink; }
      else if (name == 'dash') { icon = Icons.run_circle; iconColor = Colors.blue; }
      else if (name == 'ice_blast') { icon = Icons.ac_unit; iconColor = Colors.cyan; }
    } else {
      if (name.contains("ยา")) { icon = Icons.local_drink; iconColor = Colors.red; }
      else if (name.contains("ดาบ")) { icon = Icons.flash_on; iconColor = Colors.amber; }
      else if (name.contains("เกราะ")) { icon = Icons.shield; iconColor = Colors.blue; }
    }

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: isEquipped ? Colors.grey.shade800 : Colors.black54,
            borderRadius: BorderRadius.circular(4), // Sharp corners
            border: Border.all(
              color: isEquipped ? (isSkill ? Colors.purple : Colors.amber) : Colors.grey.shade700, 
              width: isEquipped ? 3 : 2
            ),
          ),
          child: Center(
            child: Icon(icon, size: 36, color: iconColor),
          ),
        ),
        if (count > 1)
          Positioned(
            bottom: 4, right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(2)),
              child: Text("x$count", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
          ),
        if (isEquipped)
          Positioned(
            top: 4, right: 4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(2)),
              child: const Icon(Icons.check, size: 12, color: Colors.white),
            ),
          ),
      ],
    );
  }
}