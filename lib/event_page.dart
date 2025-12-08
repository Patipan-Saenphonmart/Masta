import 'package:flutter/material.dart';

class Event extends StatelessWidget {
  const Event({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // สีพื้นหลังสมมติ (สีเขียวป่า) - คุณสามารถเปลี่ยนเป็นรูปภาพ Background ได้ทีหลัง
      backgroundColor: const Color(0xFF2E7D32), 
      body: SafeArea(
        child: Column(
          children: [
            // --- ส่วนหัว (Header) ---
            _buildHeader(context),

            // --- พื้นที่เนื้อหาที่เลื่อนได้ (Scrollable) ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // 1. แบนเนอร์กิจกรรม (กล่องสมบัติ)
                    _buildBannerPlaceholder(),

                    const SizedBox(height: 20),

                    // 2. การ์ดภารกิจที่ 1: สำรวจป่า
                    _buildMissionCard(
                      title: "ภารกิจรายวัน: สำรวจป่า",
                      current: 0,
                      max: 3,
                      iconPlaceholder: Icons.handyman, // ไอคอนดาบ (สมมติ)
                    ),

                    const SizedBox(height: 15),

                    // 3. การ์ดภารกิจที่ 2: ท้าทายบอส
                    _buildMissionCard(
                      title: "ท้าทายบอส: พิทักษ์ป่า",
                      current: 0,
                      max: 1,
                      iconPlaceholder: Icons.security, // ไอคอนโล่ (สมมติ)
                    ),
                  ],
                ),
              ),
            ),

            // --- ปุ่มเช็คอินด้านล่าง ---
            _buildCheckInButton(),
          ],
        ),
      ),
    );
  }

  // Widget: ส่วนหัวด้านบน (ปุ่มย้อนกลับ + ชื่อหน้า)
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // ปุ่มย้อนกลับ (จำลองปุ่มไม้)
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: _woodDecoration(),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          // ชื่อหน้าจอ (ป้ายไม้)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: _woodDecoration(),
              child: const Center(
                child: Text(
                  "กิจกรรมพิเศษ",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(offset: Offset(1, 1), color: Colors.black)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget: แบนเนอร์กิจกรรม (ที่ใส่รูปหีบสมบัติ)
  Widget _buildBannerPlaceholder() {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFF81C784), // สีพื้นหลังสมมติของแบนเนอร์
        border: Border.all(color: const Color(0xFFFFD54F), width: 3), // ขอบสีทอง
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // TODO: ใส่รูปภาพ Banner ของคุณตรงนี้ (ใช้ Image.asset)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.image, size: 50, color: Colors.white),
                Text("พื้นที่วางรูปแบนเนอร์", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          // ข้อความบนแบนเนอร์
          Positioned(
            right: 20,
            top: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Text(
                  "ผจญภัยล่าสมบัติ!",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                Text(
                  "รับไอเทมหายาก",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Widget: การ์ดภารกิจ (ใช้ซ้ำได้)
  Widget _buildMissionCard({
    required String title,
    required int current,
    required int max,
    required IconData iconPlaceholder,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _woodDecoration(), // พื้นหลังไม้
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(offset: Offset(1, 1), color: Colors.black)],
                  ),
                ),
                const SizedBox(height: 8),
                // หลอด Progress Bar
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: current / max, // คำนวณความยาวหลอด
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          "$current/$max",
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // ปุ่มดูรายละเอียด
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA1887F), // สีปุ่มอ่อนกว่าพื้นหลัง
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF5D4037), width: 2),
                    ),
                    child: const Text(
                      "ดูรายละเอียด",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(width: 12),
          // กล่องไอเทมทางขวา
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF5D4037),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFA1887F), width: 2),
            ),
            child: Center(
              // TODO: เปลี่ยนเป็น Image.asset ของไอเทม (ดาบ/โล่)
              child: Icon(iconPlaceholder, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }

  // Widget: ปุ่มเช็คอินด้านล่าง
  Widget _buildCheckInButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      width: double.infinity,
      height: 60,
      decoration: _woodDecoration(),
      child: const Center(
        child: Text(
          "เช็คอิน: รับรางวัลฟรี",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(offset: Offset(1, 1), color: Colors.black)],
          ),
        ),
      ),
    );
  }

  // Helper: สไตล์พื้นหลังลายไม้ (ใช้ซ้ำ)
  BoxDecoration _woodDecoration() {
    return BoxDecoration(
      color: const Color(0xFF795548), // สีน้ำตาล (Brown)
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFF4E342E), // ขอบสีน้ำตาลเข้ม
        width: 3,
      ),
      boxShadow: const [
        BoxShadow(
          color: Colors.black26,
          offset: Offset(0, 4),
          blurRadius: 4,
        )
      ],
    );
  }
}