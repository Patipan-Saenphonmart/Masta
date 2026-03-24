import 'package:flutter/material.dart';

class Friends extends StatelessWidget {
  const Friends({super.key});

  @override
  Widget build(BuildContext context) {
    // กำหนด Palette สี
    const Color panelColor = Color(0xFFFFF6D8); // สีครีมกระดาษ
    const Color woodColor = Color(0xFF8B5A2B); // สีไม้
    const Color darkText = Color(0xFF4A3225); // สีน้ำตาลเข้ม

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_quiz.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
            
            Column(
              children: [
                // -----------------------------
                // 1. ส่วนหัว (Header): ปุ่มย้อนกลับ และ ชื่อหน้า
                // -----------------------------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      // ปุ่มย้อนกลับ
                      GestureDetector(
                        onTap: () => Navigator.pop(context), // กลับไปหน้าเดิม
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: woodColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // ป้ายชื่อหน้า "เชิญและเพิ่มเพื่อน"
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: woodColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: const Center(
                            child: Text(
                              "เชิญและเพิ่มเพื่อน",
                              style: TextStyle(
                                fontSize: 22,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                // fontFamily: 'PixelFont', // อย่าลืมใส่ฟอนต์ Pixel
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // -----------------------------
                // 2. เนื้อหาหลัก (Scrollable)
                // -----------------------------
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        
                        // --- Section 1: เชิญเพื่อน ---
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: panelColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: woodColor, width: 4),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "เชิญเพื่อนของคุณมาร่วมผจญภัย!",
                                style: TextStyle(
                                  color: darkText,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              // ปุ่มคัดลอกลิงก์
                              _buildWoodButton("คัดลอกลิงก์เชิญ", Icons.link, woodColor),
                              const SizedBox(height: 10),
                              // ปุ่มแชร์
                              _buildWoodButton("แชร์ผ่านโซเชียล", Icons.share, woodColor),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // --- Section 2: เพิ่มเพื่อนด้วยรหัส ---
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: panelColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: woodColor, width: 4),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "เพิ่มเพื่อนด้วยรหัส",
                                style: TextStyle(
                                  color: darkText,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  // ช่องกรอกรหัส
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4A3225), // สีพื้นหลังช่องกรอก
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: TextField(
                                          style: TextStyle(color: Colors.white),
                                          decoration: InputDecoration(
                                            hintText: "ใส่รหัสเพื่อน",
                                            hintStyle: TextStyle(color: Colors.white54),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // ปุ่มเพิ่มเพื่อน
                                  Expanded(
                                    flex: 1,
                                    child: _buildWoodButton("เพิ่มเพื่อน", null, woodColor, isSmall: true),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // --- Section 3: เพื่อนที่อาจรู้จัก ---
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: panelColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: woodColor, width: 4),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "เพื่อนที่อาจรู้จัก",
                                style: TextStyle(
                                  color: darkText,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // รายการเพื่อน (List)
                              ListView.builder(
                                shrinkWrap: true, // เพื่อให้ list อยู่ใน scroll view หลักได้
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: 3, // จำนวนเพื่อนสมมติ
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8B5A2B), // กรอบรายการเพื่อน
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.black54, width: 1),
                                    ),
                                    child: Row(
                                      children: [
                                        // รูป Profile (Placeholder)
                                        Container(
                                          width: 40,
                                          height: 40,
                                          color: Colors.grey, // ใส่รูปจริงตรงนี้ Image.asset(...)
                                          child: const Icon(Icons.person),
                                        ),
                                        const SizedBox(width: 10),
                                        // ชื่อเพื่อน
                                        const Expanded(
                                          child: Text(
                                            "สันเกย", // ชื่อสมมติ
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        // ปุ่มเพิ่ม
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF5D4037),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.black, width: 1),
                                          ),
                                          child: const Text(
                                            "เพิ่ม",
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        // พื้นที่ว่างด้านล่างเผื่อติดขอบจอ
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  // Widget ช่วยสร้างปุ่มไม้
  Widget _buildWoodButton(String text, IconData? icon, Color color, {bool isSmall = false}) {
    return Container(
      height: isSmall ? 50 : 60,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 4),
            blurRadius: 0, // Pixel art usually has hard shadows
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: isSmall ? 16 : 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}