import 'package:flutter/material.dart';
import '../../game_data.dart';
import '../rabbit_game.dart';

class InventoryOverlay extends StatefulWidget {
  final RabbitGame game;
  const InventoryOverlay({super.key, required this.game});

  @override
  State<InventoryOverlay> createState() => _InventoryOverlayState();
}

class _InventoryOverlayState extends State<InventoryOverlay> {
  int _selectedTab = 0; // 0 = Items, 1 = Skills

  bool get _isArmorEquipped => GameData.isEquipped("เกราะวิเศษ (Magic Armor)");
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
        bool success = GameData.equipSkill(skillName);
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("ติดตั้งสกิลได้สูงสุด 4 สกิล!")),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black87, // ดิมพื้นหลัง
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.9,
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1), // กระดาษครีมสวยงาม
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF5D4037), width: 6),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
            ),
            child: Column(
              children: [
                // --- Header ---
                _buildHeader(),

                // --- Body ---
                Expanded(
                  child: Row(
                    children: [
                      // ซ้าย: Status
                      _buildCharacterStatsPanel(),

                      // คั่นกลาง
                      Container(width: 4, color: const Color(0xFFD7CCC8)),

                      // ขวา: Inventory Grid
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildTabs(),
                            Expanded(
                              child: _selectedTab == 0
                                  ? _buildInventoryGrid()
                                  : _buildSkillsGrid(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF5D4037),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18), topRight: Radius.circular(18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.backpack_rounded, color: Color(0xFFFFEB3B), size: 28),
                const SizedBox(width: 8),
                const Expanded(
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "ช่องเก็บของ (INVENTORY)",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Comic Sans MS',
                          letterSpacing: 1.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // ปุ่มปิด ❌
          GestureDetector(
            onTap: () => widget.game.overlays.remove('InventoryOverlay'),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 24),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCharacterStatsPanel() {
    int currentAtk = 30 + (_isSwordEquipped ? 20 : 0);

    return Expanded(
      flex: 2,
      child: Container(
        color: const Color(0xFFEFEBE9),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // อวตาร (กลมๆ)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                    color: const Color(0xFF8D6E63),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFEB3B), width: 4),
                    image: DecorationImage(
                      image: AssetImage(_isArmorEquipped
                          ? 'assets/images/rabbit_idle_armor.png'
                          : 'assets/images/rabbit_idle.png'),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    )),
              ),
              const SizedBox(height: 12),
              Text(_isArmorEquipped ? "Armored Hero" : "Hero Rabbit",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4E342E))),
              Text("Lv.${GameData.playerLevel}",
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold)),

              const Divider(color: Color(0xFFBCAAA4), thickness: 2, height: 24),

              // Stats
              _buildStatRow(
                  "HP", "${GameData.maxHp}", Icons.favorite, Colors.redAccent),
              _buildStatRow("ATK", "$currentAtk", Icons.flash_on, Colors.orange),
              _buildStatRow(
                  "DEF", "${GameData.defense}", Icons.shield, Colors.blue),
              _buildStatRow("AGI", "${GameData.agility}", Icons.directions_run,
                  Colors.green),

              const SizedBox(height: 16),

              // Gold
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFF5D4037),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on, color: Color(0xFFFFEB3B)),
                    const SizedBox(width: 8),
                    Text("${GameData.playerGold} G",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                      fontSize: 16)),
            ],
          ),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        _buildTabButton("กระเป๋าไอเทม", 0),
        _buildTabButton("สมุดสกิลเวทย์", 1),
      ],
    );
  }

  Widget _buildTabButton(String text, int index) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color:
                isSelected ? const Color(0xFFFFF8E1) : const Color(0xFFD7CCC8),
            border: Border(
                bottom: BorderSide(
                    color: isSelected
                        ? const Color(0xFF8D6E63)
                        : Colors.transparent,
                    width: 4)),
          ),
          child: Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? const Color(0xFF5D4037)
                      : Colors.grey.shade700)),
        ),
      ),
    );
  }

  // --- Grid สำหรับไอเทม ---
  Widget _buildInventoryGrid() {
    if (GameData.inventory.isEmpty) {
      return const Center(
          child: Text("ว่างเปล่า...",
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 18,
                  fontStyle: FontStyle.italic)));
    }

    final Map<String, int> inventoryCounts = {};
    for (var item in GameData.inventory) {
      inventoryCounts[item] = (inventoryCounts[item] ?? 0) + 1;
    }
    final uniqueItems = inventoryCounts.keys.toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: uniqueItems.length,
      itemBuilder: (context, index) {
        final itemName = uniqueItems[index];
        final count = inventoryCounts[itemName] ?? 1;
        final isEquipped = GameData.isEquipped(itemName);

        return GestureDetector(
          onTap: () => _toggleEquipItem(itemName),
          child: _buildItemCard(itemName, count, isEquipped, isSkill: false),
        );
      },
    );
  }

  // --- Grid สำหรับสกิล ---
  Widget _buildSkillsGrid() {
    if (GameData.unlockedSkills.isEmpty) {
      return const Center(
          child: Text("ยังไม่ได้เรียนรู้เวทมนตร์...",
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 18,
                  fontStyle: FontStyle.italic)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: GameData.unlockedSkills.length,
      itemBuilder: (context, index) {
        final skillName = GameData.unlockedSkills[index];
        final isEquipped = GameData.isSkillEquipped(skillName);

        return GestureDetector(
          onTap: () => _toggleEquipSkill(skillName),
          child: _buildItemCard(skillName, 1, isEquipped, isSkill: true),
        );
      },
    );
  }

  Widget _buildItemCard(String name, int count, bool isEquipped,
      {required bool isSkill}) {
    IconData icon = Icons.help_outline;
    Color iconColor = Colors.grey;
    String displayName = name;

    if (isSkill) {
      if (name == 'fireball') {
        icon = Icons.whatshot;
        iconColor = Colors.orange;
        displayName = "Fireball";
      } else if (name == 'heal') {
        icon = Icons.favorite;
        iconColor = Colors.pink;
        displayName = "Heal";
      } else if (name == 'dash') {
        icon = Icons.run_circle;
        iconColor = Colors.blue;
        displayName = "Dash";
      } else if (name == 'ice_blast') {
        icon = Icons.ac_unit;
        iconColor = Colors.cyan;
        displayName = "Ice Blast";
      }
    } else {
      if (name.contains("ยา")) {
        icon = Icons.local_drink;
        iconColor = Colors.red;
      } else if (name.contains("ดาบ")) {
        icon = Icons.flash_on;
        iconColor = Colors.amber;
      } else if (name.contains("เกราะ")) {
        icon = Icons.shield;
        iconColor = Colors.blue;
      }
      displayName = name.split(" ")[0];
    }

    return Container(
      decoration: BoxDecoration(
        color: isEquipped
            ? (isSkill ? Colors.purple.shade50 : Colors.orange.shade50)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isEquipped
                ? (isSkill ? Colors.purple : Colors.orange)
                : const Color(0xFFD7CCC8),
            width: isEquipped ? 3 : 2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: iconColor),
                const SizedBox(height: 8),
                Text(displayName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                Text(isEquipped ? "(สวมใส่แล้ว)" : "(กดสวมใส่)",
                    style: TextStyle(
                        fontSize: 10,
                        color: isEquipped ? Colors.green : Colors.grey)),
              ],
            ),
          ),
          if (count > 1)
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFF5D4037),
                    borderRadius: BorderRadius.circular(8)),
                child: Text("x$count",
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }
}
