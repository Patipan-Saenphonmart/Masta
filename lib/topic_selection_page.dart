import 'package:flutter/material.dart';
import 'quiz_game_page.dart';

class TopicSelectionPage extends StatelessWidget {
  const TopicSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final topics = [
      {"title": "สมดุลเคมี", "icon": Icons.science, "color": Colors.orange},
      {"title": "อัตราการเกิดปฏิกิริยา", "icon": Icons.speed, "color": Colors.green},
    ];

    return Scaffold(
      extendBodyBehindAppBar: true, // ให้พื้นหลังยาวไปถึงด้านบนสุด
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF5D4037)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Stack(
          children: [
            // ขอบตัวหนังสือ (Stroke)
            Text(
              "เลือกภารกิจ", // ปรับคำให้ดูเป็นเกม (Quest Selection)
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 4
                  ..color = const Color(0xFF795548),
              ),
            ),
            // ตัวหนังสือด้านใน
            const Text(
              "เลือกภารกิจ",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        // พื้นหลังธีมทุ่งหญ้าเหมือนหน้า Home
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/images/bg_toppic.png'),
          fit: BoxFit.cover)
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView.separated(
              itemCount: topics.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final topic = topics[index];
                return _buildTopicCard(context, topic);
              },
            ),
          ),
        ),
      ),
    );
  }

  // Widget สร้างการ์ดบทเรียนสไตล์ป้ายไม้
  Widget _buildTopicCard(BuildContext context, Map<String, dynamic> topic) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8D6E63).withOpacity(0.4),
            offset: const Offset(0, 5),
            blurRadius: 0, // เงาแข็งสไตล์ Retro
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizPage(topic: topic["title"] as String),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              // ไล่สีไม้โทนอ่อน (Light Wood)
              image: DecorationImage(image: AssetImage('assets/images/botton_topic.png'),
              fit: BoxFit.cover),

              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color.fromARGB(255, 69, 48, 41), // ขอบสีน้ำตาล
                width: 3,
              ),
            ),
            child: Row(
              children: [
                // ส่วนไอคอน (ใช้สีตามบทเรียนเป็นพื้นหลังไอคอนแทน)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: topic["color"] as Color, 
                      width: 3
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (topic["color"] as Color).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  ),
                  child: Icon(
                    topic["icon"] as IconData,
                    color: topic["color"] as Color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                // ส่วนข้อความ
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic["title"] as String,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Color(0xFF5D4037),
                              offset: Offset(1.5, 1.5),
                              blurRadius: 1,
                            ),
                          ],
                          fontFamily: 'Courier', // ฟอนต์สไตล์พิมพ์ดีด/เกม
                        ),
                      ),
                      // เพิ่มลูกเล่นแถบความคืบหน้าหลอกๆ (Exp Bar)
                      const SizedBox(height: 6),
                      Container(
                        height: 6,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.3, // สมมติว่าเล่นไป 30%
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.lightGreenAccent.shade700,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                // ลูกศรขวา
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 20,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}