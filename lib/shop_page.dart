import 'package:flutter/material.dart';
import 'game_data.dart';
import 'character_page.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // ✅ อัปเดตชื่อสินค้าให้ตรงกับ GameData เพื่อให้ Stats ทำงานถูกต้อง
  final List<Map<String, dynamic>> items = [
    {
      "name": "ยาเพิ่มเลือด (Potion)", 
      "price": 50,
      "image": "assets/images/potion.png",
      "icon": Icons.local_drink,
      "color": Colors.redAccent,
      "description": "ฟื้นฟู HP 50 หน่วยทันที เหมาะสำหรับนักผจญภัยมือใหม่"
    },
    {
      "name": "ดาบสายฟ้า (Thunder Sword)", 
      "price": 300,
      "image": "assets/images/thunder_sword.png",
      "icon": Icons.flash_on,
      "color": Colors.yellowAccent,
      "description": "ดาบที่ตีขึ้นจากสายฟ้า เพิ่มพลังโจมตีและ Agility เล็กน้อย"
    },
    {
      "name": "เกราะวิเศษ (Magic Armor)", 
      "price": 500,
      "image": "assets/images/armor.png",
      "icon": Icons.shield,
      "color": Colors.grey,
      "description": "เกราะหนักป้องกันสูง เพิ่ม Defense และ HP แต่ลด Agility"
    },
  ];

  final List<Map<String, dynamic>> skills = [
    {
      "name": "Fireball",
      "price": 200,
      "image": "assets/images/skill_fireball.png",
      "icon": Icons.whatshot,
      "color": Colors.orange,
      "id": "fireball",
      "levelReq": 1,
      "description": "ยิงลูกไฟใส่ศัตรู สร้างความเสียหายวงกว้าง"
    },
    {
      "name": "Dash",
      "price": 100,
      "image": "assets/images/skill_dash.png",
      "icon": Icons.run_circle,
      "color": Colors.blueGrey,
      "id": "dash",
      "levelReq": 2,
      "description": "พุ่งตัวไปข้างหน้าอย่างรวดเร็ว หลบการโจมตีได้"
    },
    {
      "name": "Heal",
      "price": 150,
      "image": null,
      "icon": Icons.favorite,
      "color": Colors.pinkAccent,
      "id": "heal",
      "levelReq": 3,
      "description": "ร่ายเวทย์รักษาบาดแผล ฟื้นฟู HP ต่อเนื่อง"
    },
    {
      "name": "Ice Blast",
      "price": 400,
      "image": null,
      "icon": Icons.ac_unit,
      "color": Colors.cyanAccent,
      "id": "ice_blast",
      "levelReq": 5,
      "description": "แช่แข็งศัตรูรอบตัว ทำให้ขยับไม่ได้ชั่วขณะ"
    },
  ];

  void handleBuyItem(String name, int price) {
    setState(() {
      bool success = GameData.buyItem(name, price);
      
      if (success) {
        // ✅ Auto-Equip: ถ้าเป็นอุปกรณ์สวมใส่ ให้ติดตั้งทันทีที่ซื้อ
        if (name.contains("เกราะ") || name.contains("ดาบ")) {
           GameData.equipItem(name);
           print("Auto-equipped: $name");
        }

        _showResult(true, "ซื้อ $name สำเร็จ!");
      } else {
        _showResult(false, "เงินไม่พอ!");
      }
    });
  }

  void handleBuySkill(String name, int price, int levelReq) {
    if (GameData.playerLevel < levelReq) {
      _showResult(false, "เลเวลไม่ถึง! ต้องการ Lv.$levelReq");
      return;
    }
    setState(() {
      bool success = GameData.buySkill(name, price, levelReq);
      _showResult(success, success ? "เรียนรู้สกิล $name สำเร็จ!" : "เงินไม่พอ!");
    });
  }

  void _showResult(bool success, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildItemImage(Map<String, dynamic> item, {double size = 50}) {
    if (item['image'] != null) {
      return Image.asset(
        item['image'],
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(item['icon'], size: size, color: item['color']);
        },
      );
    } else {
      return Icon(item['icon'], size: size, color: item['color'] ?? Colors.white);
    }
  }

  void showItemDetail(Map<String, dynamic> item, bool isSkill) {
    // ✅ อัปเดตการเช็คสถานะการซื้อ (Items ใช้ hasItem, Skills ใช้ hasSkill)
    final bool isOwned = isSkill 
        ? GameData.hasSkill(item['name']) 
        : (item['name'].contains("ยา") ? false : GameData.hasItem(item['name'])); 
        // หมายเหตุ: ยา (Potion) ให้ซื้อซ้ำได้เสมอ แต่ดาบ/เกราะ ซื้อแล้วจะขึ้น "มีแล้ว"

    final int levelReq = isSkill ? (item['levelReq'] ?? 1) : 1;
    final bool levelEnough = GameData.playerLevel >= levelReq;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3E2723),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFFFD700), width: 4)),
          title: Row(
            children: [
              _buildItemImage(item, size: 30),
              const SizedBox(width: 10),
              Flexible(
                  child: Text(item['name'],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.brown.shade400, width: 2),
                ),
                child: Center(child: _buildItemImage(item, size: 80)),
              ),
              const SizedBox(height: 20),
              Text(item['description'] ?? "ไม่มีคำอธิบาย",
                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 15),
              const Divider(color: Colors.white24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                      const SizedBox(width: 5),
                      Text("${item['price']}",
                          style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                    ],
                  ),
                  if (isSkill)
                    Text("REQ: Lv.$levelReq",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: levelEnough
                                ? Colors.greenAccent
                                : Colors.redAccent)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ยกเลิก", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isOwned
                    ? Colors.grey
                    : (!levelEnough && isSkill
                        ? Colors.red.shade900
                        : const Color(0xFF4CAF50)),
                foregroundColor: Colors.white,
              ),
              onPressed: isOwned
                  ? null
                  : () {
                      if (isSkill) {
                        handleBuySkill(item['name'], item['price'], levelReq);
                      } else {
                        handleBuyItem(item['name'], item['price']);
                      }
                      Navigator.pop(context);
                    },
              child: Text(isOwned ? "มีแล้ว" : "ซื้อเลย"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "ร้านค้า",
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(offset: Offset(2, 2), blurRadius: 0, color: Colors.black),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CharacterPage()),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: Colors.black45, shape: BoxShape.circle),
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                GameData.levelUp();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Level Up!"), duration: Duration(milliseconds: 500))
                );
              });
            },
            icon: const Icon(Icons.arrow_circle_up, color: Colors.greenAccent),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/bg_quiz.png",
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    ),
                  ),
                );
              },
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(right: 20, bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D4037),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFD700), width: 2),
                      boxShadow: const [BoxShadow(color: Colors.black38, offset: Offset(2, 2), blurRadius: 2)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          "${GameData.playerGold}",
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 18,
                            shadows: [Shadow(color: Colors.black, offset: Offset(1,1))],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    labelColor: Colors.brown.shade900,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    tabs: const [
                      Tab(text: "ไอเทม"),
                      Tab(text: "สกิล"),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGridList(items, isSkill: false),
                      _buildGridList(skills, isSkill: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridList(List<Map<String, dynamic>> dataList, {required bool isSkill}) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 15,
        mainAxisSpacing: 20,
      ),
      itemCount: dataList.length,
      itemBuilder: (context, index) {
        final item = dataList[index];
        
        // ✅ อัปเดตการแสดงผลปุ่ม "ซื้อ/มีแล้ว"
        final bool isOwned = isSkill 
            ? GameData.hasSkill(item['name']) 
            : (item['name'].contains("ยา") ? false : GameData.hasItem(item['name']));

        return GestureDetector(
          onTap: () => showItemDetail(item, isSkill),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E2723),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFC107),
                      width: 4,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, offset: Offset(0, 6), blurRadius: 4),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: Container(
                            child: _buildItemImage(item, size: 60), 
                          ),
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          item['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14, // ลดขนาดลงนิดนึงเผื่อชื่อยาว
                            shadows: [Shadow(color: Colors.black, offset: Offset(1,1))],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2, // ให้ขึ้นบรรทัดใหม่ได้
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      const SizedBox(height: 5),

                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "${item['price']}",
                              style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: 120,
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: isOwned 
                        ? Colors.grey 
                        : const Color(0xFF8D6E63),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFF5D4037), width: 3),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () => showItemDetail(item, isSkill),
                  child: Text(
                    isOwned ? "มีแล้ว" : "ซื้อ",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      shadows: [Shadow(color: Colors.black, offset: Offset(1, 1))],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}