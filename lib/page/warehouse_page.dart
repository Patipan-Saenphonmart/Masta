import 'package:flutter/material.dart';
import '../data/game_data.dart';
import '../dialog/book_reading_dialog.dart';

class WarehousePage extends StatefulWidget {
  const WarehousePage({super.key});

  @override
  State<WarehousePage> createState() => _WarehousePageState();
}

class _WarehousePageState extends State<WarehousePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2 Tabs: Items, Skills
  }

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
            const SnackBar(content: Text("เลือกสกิลได้สูงสุด 4 สกิลเท่านั้น!")),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "คลังเก็บสมบัติ (VAULT)",
          style: TextStyle(
            fontFamily: 'Comic Sans MS',
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFFEB3B),
            letterSpacing: 2,
            shadows: [Shadow(blurRadius: 4, color: Colors.black, offset: Offset(2, 2))],
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white, size: 30),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_toppic.png'), // ใช้ภาพพื้นหลังโทนเข้ม/ดันเจี้ยน
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black87, BlendMode.darken), // ทำให้ดูเหมือนดาร์คคลังอาวุธ
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- Header แจ้งยอดเงิน ---
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF4E342E).withOpacity(0.9), const Color(0xFF3E2723).withOpacity(0.9)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFB300), width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.inventory, color: Colors.white70),
                        SizedBox(width: 8),
                        Text("จัดการไอเทมของคุณ", style: TextStyle(color: Colors.white70, fontSize: 16)),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on, color: Color(0xFFFFB300), size: 26),
                        const SizedBox(width: 8),
                        Text("${GameData.playerGold} G", style: const TextStyle(color: Color(0xFFFFB300), fontWeight: FontWeight.bold, fontSize: 20)),
                      ],
                    ),
                  ],
                ),
              ),

              // --- Tab Bar ---
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF5D4037),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3E2723), width: 3),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFFBCAAA4),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: const Color(0xFF8D6E63),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Comic Sans MS'),
                  tabs: const [
                    Tab(icon: Icon(Icons.shield, size: 24), text: "อุปกรณ์"),
                    Tab(icon: Icon(Icons.auto_awesome, size: 24), text: "สกิล"),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- Grid Container ---
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEBE9).withOpacity(0.95), // สีกระดาษ
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF5D4037), width: 6),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 5))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInventoryGrid(),
                        _buildSkillsGrid(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Grid สำหรับไอเทม ---
  Widget _buildInventoryGrid() {
    if (GameData.inventory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.remove_shopping_cart, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text("คลังสินค้าว่างเปล่า", style: TextStyle(color: Colors.grey.shade600, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        )
      );
    }

    final Map<String, int> inventoryCounts = {};
    for (var item in GameData.inventory) {
      inventoryCounts[item] = (inventoryCounts[item] ?? 0) + 1;
    }
    final uniqueItems = inventoryCounts.keys.toList();

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8, 
      ),
      itemCount: uniqueItems.length,
      itemBuilder: (context, index) {
        final itemName = uniqueItems[index];
        final count = inventoryCounts[itemName] ?? 1;
        final isEquipped = GameData.isEquipped(itemName);
        final isBook = GameData.isBook(itemName);
        
        return GestureDetector(
          onTap: () => isBook ? BookReadingDialog.show(context, itemName) : _toggleEquipItem(itemName),
          onLongPress: () => _showItemDetailSheet(itemName, isSkill: false),
          child: _buildSelectableCard(itemName, count, isEquipped, isSkill: false, isBook: isBook),
        );
      },
    );
  }

  // --- Grid สำหรับสกิล ---
  Widget _buildSkillsGrid() {
    if (GameData.unlockedSkills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text("ยังไม่มีคัมภีร์เวทมนตร์", style: TextStyle(color: Colors.grey.shade600, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        )
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8, 
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
    bool isEquipped = isSkill ? GameData.isSkillEquipped(name) : GameData.isEquipped(name);
    bool isBook = GameData.isBook(name);

    if (isBook) {
      icon = Icons.menu_book;
      iconColor = Colors.brown;
      description = 'หนังสือที่สามารถอ่านเพื่อเพิ่มพัฒนาการ';
      effect = 'คลิกเพื่อเปิดอ่านหนังสือ';
    } else if (isSkill) {
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
        decoration: const BoxDecoration(
          color: Color(0xFFFFF8E1),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF5D4037), width: 6)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.brown.shade300, borderRadius: BorderRadius.circular(3))),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: iconColor, width: 2),
                  ),
                  child: Icon(icon, size: 40, color: iconColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF3E2723))),
                    const SizedBox(height: 4),
                    Text(isBook ? 'ประเภท: หนังสือ' : (isSkill ? 'ประเภท: สกิล' : 'ประเภท: อุปกรณ์'), style: TextStyle(fontSize: 14, color: Colors.brown.shade400)),
                  ]),
                ),
              ]),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFEFEBE9), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFD7CCC8))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("รายละเอียด:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown.shade700)),
                  const SizedBox(height: 4),
                  Text(description.isNotEmpty ? description : 'ไม่มีข้อมูลรายละเอียด', style: const TextStyle(fontSize: 16, color: Color(0xFF4E342E))),
                  if (effect.isNotEmpty) ...[
                    const Divider(height: 20),
                    Row(children: [
                      const Icon(Icons.auto_awesome, size: 20, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(effect, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber)),
                    ]),
                  ],
                ]),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isBook ? Colors.brown.shade600 : (isEquipped ? Colors.red.shade400 : const Color(0xFF5D4037)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: Icon(isBook ? Icons.menu_book : (isEquipped ? Icons.remove_circle : Icons.check_circle), color: Colors.white),
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (isBook) { 
                      BookReadingDialog.show(context, name); 
                    } else if (isSkill) { 
                      _toggleEquipSkill(name); 
                    } else { 
                      _toggleEquipItem(name); 
                    }
                  },
                  label: Text(
                    isBook ? 'อ่านหนังสือ' : (isSkill ? (isEquipped ? 'ถอดสกิล' : 'สวมใส่สกิล') : (isEquipped ? 'ปลดอุปกรณ์' : 'สวมใส่อุปกรณ์')),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectableCard(String name, int count, bool isEquipped, {required bool isSkill, bool isBook = false}) {
    IconData icon = Icons.help_outline;
    Color iconColor = Colors.grey;
    String displayName = name;
    String? imagePath;

    if (isSkill) {
      if (name == 'fireball') { icon = Icons.whatshot; iconColor = Colors.orange; displayName = "Fireball"; }
      else if (name == 'heal') { icon = Icons.favorite; iconColor = Colors.pink; displayName = "Heal"; }
      else if (name == 'dash') { icon = Icons.run_circle; iconColor = Colors.blue; displayName = "Dash"; }
      else if (name == 'ice_blast') { icon = Icons.ac_unit; iconColor = Colors.cyan; displayName = "Ice Blast"; }
    } else {
      if (isBook) { 
        iconColor = Colors.brown; 
        displayName = name.split(" ")[0];
        if (name.contains("หนังสือบันทึกโจทย์")) {
           imagePath = 'assets/images/book_questions.png';
        } else if (name.contains("บันทึกแห่งจอมปราชญ์")) {
           imagePath = 'assets/images/book_story.png';
        } else {
           imagePath = 'assets/images/book_questions.png'; 
        }
      }
      else if (name.contains("ยา")) { icon = Icons.local_drink; iconColor = Colors.red; }
      else if (name.contains("ดาบ")) { icon = Icons.flash_on; iconColor = Colors.amber; }
      else if (name.contains("เกราะ")) { icon = Icons.shield; iconColor = Colors.blue; }
      else { displayName = name.split(" ")[0]; }
    }

    return Container(
      decoration: BoxDecoration(
        color: isEquipped ? (isSkill ? Colors.purple.shade50 : Colors.amber.shade50) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEquipped ? (isSkill ? Colors.purple : Colors.amber) : const Color(0xFFBCAAA4), 
          width: isEquipped ? 4 : 2
        ),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    image: imagePath != null ? DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover) : null,
                  ),
                  child: imagePath == null ? Icon(icon, size: 30, color: iconColor) : null,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    displayName, 
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4E342E)),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.brown.shade800,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text("x$count", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          if (isBook)
            Positioned(
              top: 8, left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.brown, borderRadius: BorderRadius.circular(8)),
                child: const Text("อ่าน", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          if (isEquipped && !isBook)
            Positioned(
              top: 8, left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                child: const Text("สวมใส่แล้ว", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}
