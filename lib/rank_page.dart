import 'package:flutter/material.dart';

class Rank extends StatelessWidget {
  const Rank({super.key});

  @override
  Widget build(BuildContext context) {
    // ข้อมูลตัวอย่าง (Mock Data) เลียนแบบในรูป
    final List<Map<String, dynamic>> rankingData = [
      {'rank': 1, 'name': 'เทพป่าไม้', 'score': 1200, 'color': Colors.green},
      {'rank': 2, 'name': 'นักล่าสมบัติ', 'score': 1150, 'color': Colors.brown},
      {'rank': 3, 'name': 'ผู้กล้าหาญ', 'score': 1100, 'color': Colors.grey},
      {'rank': 4, 'name': 'แองขี้รั้ว', 'score': 1050, 'color': Colors.purple},
      {'rank': 5, 'name': 'นักล่าสมบัติ', 'score': 950, 'color': Colors.blueGrey},
      {'rank': 6, 'name': 'ผู้เล่นใหม่', 'score': 800, 'color': Colors.orange},
    ];

    return Scaffold(
      body: Stack(
        children: [
          // -----------------------------------------------------------
          // 1. BACKGROUND LAYER (พื้นหลัง)
          // -----------------------------------------------------------
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF2E7D32), // สีเขียวป่า (Placeholder)
            // TODO: เปลี่ยนเป็นใส่รูป Background ตรงนี้
            // decoration: BoxDecoration(
            //   image: DecorationImage(
            //     image: AssetImage('assets/images/forest_bg.png'),
            //     fit: BoxFit.cover,
            //   ),
            // ),
          ),

          // -----------------------------------------------------------
          // 2. CONTENT LAYER (เนื้อหา)
          // -----------------------------------------------------------
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                
                // --- Header (ปุ่มย้อนกลับ + ป้ายชื่อ) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      // ปุ่มย้อนกลับ
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8D6E63), // สีไม้
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black54, width: 2),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // ป้ายชื่อหน้า (การแข่งขันจัดอันดับ)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6D4C41), // สีไม้เข้ม
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black54, width: 2),
                          ),
                          child: const Center(
                            child: Text(
                              "การแข่งขันจัดอันดับ",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // สีครีม
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- Main Board (กระดานคะแนน) ---
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1), // สีครีมพื้นหลังกระดาน
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF5D4037), width: 4),
                    ),
                    child: Column(
                      children: [
                        // ถ้วยรางวัลและอันดับของคุณ (Banner สีแดง)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC62828), // สีแดง
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFB71C1C), width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)
                            ],
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.emoji_events, size: 40, color: Colors.amber), // ไอคอนถ้วย
                              const SizedBox(height: 5),
                              const Text(
                                "อันดับของคุณ: 15 🏆",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // รายชื่อผู้เล่น (ListView)
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            itemCount: rankingData.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = rankingData[index];
                              return _buildRankItem(
                                rank: item['rank'],
                                name: item['name'],
                                score: item['score'],
                                avatarColor: item['color'],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- Bottom Button (ปุ่มเข้าร่วมแข่งขัน) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: InkWell(
                    onTap: () {
                      // Action เมื่อกดปุ่มเข้าร่วม
                      print("เข้าร่วมแข่งขัน");
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF795548), // สีไม้
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black54, width: 3),
                        boxShadow: [
                          BoxShadow(color: Colors.black38, offset: Offset(0, 4), blurRadius: 0) // เงาแบบ Pixel art แข็งๆ
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "เข้าร่วมแข่งขัน",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFECB3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget สร้างแถบรายการแต่ละคน
  Widget _buildRankItem({
    required int rank,
    required String name,
    required int score,
    required Color avatarColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF8D6E63), // สีพื้นหลังแถบไม้
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3E2723), width: 2),
      ),
      child: Row(
        children: [
          // รูป Avatar (Placeholder)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: avatarColor, // สีสมมติแทนรูป
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black45),
            ),
            // TODO: ใส่รูป Profile ตรงนี้ child: Image.asset(...)
            child: const Icon(Icons.person, color: Colors.white70),
          ),
          const SizedBox(width: 12),
          
          // ชื่อและคะแนน
          Expanded(
            child: Text(
              "$rank. $name - $score คะแนน",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFECB3), // สีครีมอ่อนๆ ตัดกับลายไม้
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}