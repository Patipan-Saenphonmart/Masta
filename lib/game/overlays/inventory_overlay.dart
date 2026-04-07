import 'package:flutter/material.dart';
import '../../data/game_data.dart';
import '../main_game.dart';
import '../../models/book.dart'; // อย่าลืม import Book

class InventoryOverlay extends StatefulWidget {
  final RabbitGame game;
  const InventoryOverlay({super.key, required this.game});

  @override
  State<InventoryOverlay> createState() => _InventoryOverlayState();
}

class _InventoryOverlayState extends State<InventoryOverlay> {
  int _selectedTab = 0; // 0 = Items, 1 = Skills

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

  void _showItemActionDialog(String itemName) {
    bool isBook = GameData.isBook(itemName);
    String title = isBook ? "อ่านหนังสือ" : "สวมใส่ไอเทม";
    String question = isBook 
        ? "คุณต้องการอ่านหนังสือเล่มนี้หรือไม่?"
        : "คุณต้องการสวมใส่ไอเทมนี้หรือไม่?";
    String confirmText = isBook ? "อ่าน" : "สวมใส่";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF8D6E63), width: 3),
          ),
          elevation: 10,
          backgroundColor: const Color(0xFFFFF8E1),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFFF8E1),
                  const Color(0xFFF5F5DC).withOpacity(0.95),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8D6E63).withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF8D6E63), width: 2),
                  ),
                  child: Icon(
                    isBook ? Icons.menu_book : Icons.check_circle,
                    size: 50,
                    color: const Color(0xFF5D4037),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3E2723),
                    fontFamily: 'Comic Sans MS',
                    shadows: [
                      Shadow(
                        blurRadius: 2,
                        color: Colors.brown.withOpacity(0.3),
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Question
                Text(
                  question,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.brown.shade700,
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Cancel Button
                    SizedBox(
                      width: 100,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'ไม่',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    // Confirm Button
                    SizedBox(
                      width: 100,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (isBook) {
                            // ✅ ดึงข้อมูลหนังสือและเปิดแบบ Popup
                            Book? book = GameData.getBookByTitle(itemName);
                            book ??= Book.regular(
                                id: 'default_book',
                                title: itemName,
                                description: 'หนังสือธรรมดา',
                                content: 'นี่คือเนื้อหาของหนังสือ "$itemName"\n\n'
                                            'เนื้อหากำลังถูกพัฒนาเพิ่มเติม...\n\n'
                                            'คุณสามารถเพลิดเพลินกับการอ่านหนังสือเล่มนี้ได้',
                              );
                            
                            showDialog(
                              context: context,
                              barrierDismissible: true,
                              barrierColor: Colors.black87, // ดิมพื้นหลังตอนเปิดหนังสือ
                              builder: (context) => _BookPopupOverlay(book: book!),
                            );
                            
                          } else {
                            _toggleEquipItem(itemName);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
                      image: AssetImage(GameData.playerIdleAsset),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    )),
              ),
              const SizedBox(height: 12),
              Text(GameData.playerName,
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
                            fontSize: 12)),
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
          onTap: () => _showItemActionDialog(itemName),
          child: _buildItemCard(itemName, count, isEquipped, isSkill: false),
        );
      },
    );
  }

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
    bool isBook = GameData.isBook(name);

    if (isSkill) {
      if (name == 'fireball') {
        icon = Icons.whatshot;
        iconColor = Colors.orange;
      } else if (name == 'heal') {
        icon = Icons.favorite;
        iconColor = Colors.pink;
      } else if (name == 'dash') {
        icon = Icons.run_circle;
        iconColor = Colors.blue;
      } else if (name == 'ice_blast') {
        icon = Icons.ac_unit;
        iconColor = Colors.cyan;
      }
    } else {
      if (isBook) {
        icon = Icons.menu_book;
        iconColor = Colors.brown;
      } else if (name.contains("ยา")) {
        icon = Icons.local_drink;
        iconColor = Colors.red;
      } else if (name.contains("ดาบ")) {
        icon = Icons.flash_on;
        iconColor = Colors.amber;
      } else if (name.contains("เกราะ")) {
        icon = Icons.shield;
        iconColor = Colors.blue;
      }
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
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(height: 8),
                if (isBook)
                  Text(name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 10,
                          color: Colors.brown))
                else if (isSkill)
                  const Text("สกิล",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 11))
                else
                  const Text("ไอเทม",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 11)),
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

// =====================================================================
// ✅ WIDGET สำหรับแสดงหนังสือแบบป๊อปอัพ (ไม่ต้องสลับไปหน้าใหม่)
// =====================================================================
class _BookPopupOverlay extends StatefulWidget {
  final Book book;

  const _BookPopupOverlay({required this.book});

  @override
  State<_BookPopupOverlay> createState() => _BookPopupOverlayState();
}

class _BookPopupOverlayState extends State<_BookPopupOverlay> {
  int _currentSpread = 0;
  final int _maxSpreads = 2; // มี 2 คู่หน้า

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ส่วนหัว (ชื่อหนังสือและปุ่มปิด)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.book.title,
                    style: const TextStyle(
                      fontFamily: 'PixelArtFont',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFD54F),
                      shadows: [
                        Shadow(blurRadius: 1, color: Colors.black, offset: Offset(2, 2)),
                        Shadow(blurRadius: 1, color: Colors.black, offset: Offset(1, 1)),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.white, size: 36),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // เนื้อหาหนังสือ
            if (widget.book.isQuestLog)
              SizedBox(height: 450, child: _buildQuestLogContent())
            else
              _buildRegularBookContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildRegularBookContent() {
    return Column(
      children: [
        // กรอบหนังสือ
        Container(
          height: 350, 
          padding: const EdgeInsets.all(16), 
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/UI_TravelBook_BookCover01a.png'),
              fit: BoxFit.fill,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch, 
            children: [
              // === หน้าซ้าย ===
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 2),
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/UI_TravelBook_BookPageLeft01a.png'),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: _currentSpread == 0 ? _buildPage1() : _buildPage3(),
                  ),
                ),
              ),

              // === หน้าขวา ===
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 2),
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/UI_TravelBook_BookPageRight01a.png'),
                      fit: BoxFit.fill, 
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: _currentSpread == 0 ? _buildPage2() : _buildBlankLines(),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ปุ่มควบคุมหน้า
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.arrow_back_ios_rounded, 
                  color: _currentSpread > 0 ? Colors.white : Colors.white38, 
                  size: 24,
                ),
                onPressed: _currentSpread > 0 ? () {
                  setState(() {
                    _currentSpread--;
                  });
                } : null,
              ),
              
              const SizedBox(width: 20),
              
              Text(
                'หน้า ${_currentSpread * 2 + 1} - ${_currentSpread * 2 + 2}',
                style: const TextStyle(
                  fontFamily: 'PixelArtFont',
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),

              const SizedBox(width: 20),

              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.arrow_forward_ios_rounded, 
                  color: _currentSpread < _maxSpreads - 1 ? Colors.white : Colors.white38, 
                  size: 24,
                ),
                onPressed: _currentSpread < _maxSpreads - 1 ? () {
                  setState(() {
                    _currentSpread++;
                  });
                } : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- เนื้อหาแต่ละหน้า (ใช้เหมือนเดิมกับที่แก้ไขไปแล้ว) ---
  Widget _buildPage1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📖 คำจารึกจากผู้มาก่อน',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
            fontFamily: 'PixelArtFont',
          ),
        ),
        const Divider(color: Color(0xFFA1887F), thickness: 1, height: 12),
        _buildText(
          '"แด่ดวงจิตผู้มองเห็นความจริง... หากเจ้าอ่านอักขระเหล่านี้ออก แสดงว่าเจ้าคือผู้ถูกเลือกจาก MASTA\n\n'
          'โลกนี้กำลังป่วยหนัก สิ่งที่ประชากรดั้งเดิมหวาดกลัวและเทิดทูนว่าคือ \'เวทมนตร์\'... '
          'แท้จริงแล้วมันคือ \'สมการทางวิทยาศาสตร์\' ที่สูญเสียการควบคุมต่างหาก\n\n'
          'พวกมันใช้พลังงานโดยไม่เข้าใจหลักอุณหพลศาสตร์ บิดเบือนแรงโน้มถ่วงโดยไม่สนมวลของสสาร...\n\n'
          'จงใช้ความรู้ของเจ้า แก้ไขตัวแปรที่ผิดเพี้ยนเหล่านี้ และจงบันทึกความจริงลงในหน้ากระดาษที่เหลือ... ก่อนที่มิติแห่งนี้จะล่มสลาย"',
          italic: true,
        ),
      ],
    );
  }

  Widget _buildPage2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚔️ กฎแห่งการหักล้าง',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
            fontFamily: 'PixelArtFont',
          ),
        ),
        const Divider(color: Color(0xFFA1887F), thickness: 1, height: 12),
        
        Center(
          child: Container(
            padding: const EdgeInsets.all(4),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.brown.shade300, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department, color: Colors.red.shade400, size: 16),
                const Icon(Icons.arrow_right_alt, color: Colors.brown, size: 16),
                Icon(Icons.water_drop, color: Colors.blue.shade400, size: 16),
              ],
            ),
          ),
        ),
        
        _buildText('🔥 ธาตุไฟ (Ignis):', bold: true, color: Colors.red.shade900),
        _buildText('ปฏิกิริยาออกซิเดชันคายความร้อน\nจุดอ่อน: สารทำความเย็น (เคมี)'),
        const SizedBox(height: 6),
        
        _buildText('❄️ ธาตุน้ำ/น้ำแข็ง:', bold: true, color: Colors.blue.shade900),
        _buildText('พันธะไฮโดรเจนที่ผิดปกติ\nจุดอ่อน: เพิ่มพลังงานความร้อน (ฟิสิกส์)'),
        const SizedBox(height: 6),
        
        _buildText('💡 วิธีต่อสู้:', bold: true, color: Colors.brown.shade800),
        _buildText('วิเคราะห์โครงสร้างของศัตรูเพื่อหาจุดอ่อนที่แท้จริง!', bold: true),
      ],
    );
  }

  Widget _buildPage3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📝 หน้ากระดาษที่ว่างเปล่า',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
            fontFamily: 'PixelArtFont',
          ),
        ),
        const Divider(color: Color(0xFFA1887F), thickness: 1, height: 12),
        const SizedBox(height: 8),
        
        _buildText(
          '(หน้าอื่นว่างเปล่าหมดเลย...)\n\n'
          '"อ๋อ เข้าใจล่ะ MASTA ถึงเรียกฉันว่า \'ผู้บันทึก\' สินะ ฉันต้องเป็นคนเขียนข้อมูลของโลกนี้ลงไปเอง!"',
          italic: true,
          color: Colors.brown.shade600,
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.brown.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.brown.shade200, style: BorderStyle.solid),
          ),
          child: _buildText(
            '[ระบบ Pokedex: ข้อมูลของศัตรูและไอเทมใหม่ๆ จะถูกบันทึกที่นี่]',
            fontSize: 9,
            color: Colors.grey.shade700,
          ),
        )
      ],
    );
  }

  Widget _buildBlankLines() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < 15; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 1,
              width: double.infinity,
              color: const Color(0xFFA1887F).withOpacity(0.5),
            ),
          ),
      ],
    );
  }

  Widget _buildText(String text, {bool bold = false, bool italic = false, Color? color, double fontSize = 10}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        height: 1.4,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        color: color ?? const Color(0xFF3E2723),
        fontFamily: 'PixelArtFont',
      ),
    );
  }

  Widget _buildQuestLogContent() {
    final entries = GameData.questLogEntries;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5DC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8D6E63), width: 3),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: entries.isEmpty 
        ? const Center(
            child: Text("ยังไม่มีบันทึกโจทย์", style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold))
          )
        : ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.brown.shade200, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ExpansionTile(
                  iconColor: Colors.brown,
                  collapsedIconColor: Colors.brown,
                  title: Text(
                    "📝 ${entry['title']} - วิชา${entry['subject']}",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
                  ),
                  subtitle: Text(
                    entry['question'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.brown.shade50,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        )
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("📌 โจทย์:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                          const SizedBox(height: 4),
                          Text("${entry['question']}", style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 12),
                          const Text("💡 คำตอบที่ถูกต้อง:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          const SizedBox(height: 4),
                          Text("${entry['answer']}", style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
    );
  }
}