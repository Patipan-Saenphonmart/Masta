import 'dart:math';
import 'package:flutter/material.dart';
import '../../supabase_config.dart'; // เรียกใช้ config จาก root
import '../rabbit_game.dart'; // เรียกใช้ตัวเกม

class QuestionOverlay extends StatefulWidget {
  final RabbitGame game;
  final String topic;
  const QuestionOverlay({super.key, required this.game, required this.topic});

  @override
  State<QuestionOverlay> createState() => _QuestionOverlayState();
}

class _QuestionOverlayState extends State<QuestionOverlay> {
  List<Map<String, dynamic>> questions = [];
  late Map<String, dynamic> current;
  bool loading = true;
  bool answered = false;
  String? selectedChoice;

  // สร้าง Random instance ไว้ใช้ซ้ำ
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    try {
      // ดึงคำถามจาก Supabase
      final data = await QuestionService.fetchQuestions(widget.topic);
      if (!mounted) return;

      if (data.isNotEmpty) {
        questions = data;
        // ✅ สุ่มคำถาม 1 ข้อจาก Database
        current = questions[_rng.nextInt(questions.length)];
      } else {
        // Fallback กรณีไม่มีข้อมูล
        _useFallbackQuestions();
      }
    } catch (e) {
      debugPrint("Error loading questions: $e");
      _useFallbackQuestions();
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void _useFallbackQuestions() {
    questions = [
      {
        'question_text': 'หากไม่มีข้อมูลจากเซิร์ฟเวอร์ คำถามนี้คือคำถามทดสอบ?',
        'choices': ["ตกลง", "ยกเลิก"],
        'answer': 'ตกลง'
      },
      {
        'question_text':
            'การเผาไหม้ถ่านในเตาเผาที่มีช่องระบายควัน ถือว่าเป็นสมดุลเคมีหรือไม่ อย่างไร',
        'choices': ["เป็นสมดุล", "ไม่เป็นสมดุล"],
        'answer': 'ไม่เป็นสมดุล'
      },
      {
        'question_text':
            'ปฏิกิริยา H₂(g) + I₂(g) ⇌ 2HI(g) เมื่อเพิ่มอุณหภูมิ สีของระบบจะเปลี่ยนอย่างไร',
        'choices': ["เข้มขึ้น", "จางลง", "ไม่เปลี่ยนแปลง"],
        'answer': 'เข้มขึ้น'
      }
    ];
    // ✅ แก้ไข: ให้สุ่มคำถามจากรายการ Fallback ด้วย (จากเดิม fix ที่ index 0)
    current = questions[_rng.nextInt(questions.length)];
  }

  void select(String choice) {
    if (answered) return;

    setState(() {
      answered = true;
      selectedChoice = choice;
    });

    final correct = choice == current['answer'];

    // ส่งผลลัพธ์กลับไปที่เกม
    widget.game.onAnswerSelected(correct);

    // รอสักครู่แล้วปิด Overlay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        widget.game.overlays.remove('QuestionOverlay');
        // Resume game logic if needed
        widget.game.resumeEngine();
      }
    });
  }

  // สร้าง Widget ปุ่มสไตล์ Pixel
  Widget _buildPixelButton(
      String text, VoidCallback? onPressed, Color bgColor, Color borderColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 4),
          left: BorderSide(color: borderColor, width: 4),
          right: BorderSide(
              color: borderColor.withOpacity(0.5), width: 4), // เงาด้านขวา
          bottom: BorderSide(
              color: borderColor.withOpacity(0.5),
              width: 6), // เงาด้านล่างหนาหน่อย
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          splashColor: Colors.white24,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E2723), // สีน้ำตาลเข้ม
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // สีธีม Pixel Art (Cream & Brown)
    const bgColor = Color(0xFFFFF8E1); // สีครีมกระดาษ
    const borderColor = Color(0xFF5D4037); // สีน้ำตาลเข้ม

    if (loading) {
      return Container(
        color: Colors.black54,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 6, // เส้นหนาๆ ให้ดู retro
          ),
        ),
      );
    }

    final choices = List<String>.from(current['choices'] ?? []);

    return Material(
      color: Colors.black54, // พื้นหลังมืดจางๆ
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(4), // Padding สำหรับขอบนอกสุด
            decoration: const BoxDecoration(
              color: borderColor, // ขอบสีน้ำตาลเข้ม
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: bgColor, // พื้นหลังสีครีม
                border: Border.symmetric(
                  vertical: BorderSide(
                      color: Color(0xFFD7CCC8), width: 4), // ลวดลายขอบใน
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Header / Question Icon ---
                  Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB74D), // สีส้ม
                      border: Border.all(color: borderColor, width: 4),
                    ),
                    child: const Icon(Icons.question_mark,
                        size: 40, color: borderColor),
                  ),

                  // --- Question Text ---
                  Text(
                    current['question_text'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: borderColor,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Choices ---
                  ...choices.map((choice) {
                    Color btnColor =
                        const Color(0xFFFFCC80); // สีส้มอ่อน (ปกติ)
                    Color btnBorder = borderColor;

                    if (answered) {
                      if (choice == current['answer']) {
                        btnColor = const Color(0xFF66BB6A); // เขียว (ถูก)
                      } else if (choice == selectedChoice) {
                        btnColor = const Color(0xFFEF5350); // แดง (ผิด)
                      } else {
                        btnColor = Colors.grey.shade300; // เทา (ไม่ได้เลือก)
                        btnBorder = Colors.grey.shade600;
                      }
                    }

                    return _buildPixelButton(
                      choice,
                      answered ? null : () => select(choice),
                      btnColor,
                      btnBorder,
                    );
                  }),

                  if (answered)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        selectedChoice == current['answer']
                            ? "ถูกต้อง! ไปลุยกันต่อ!"
                            : "ผิดพลาด! ระวังตัวด้วย!",
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: selectedChoice == current['answer']
                              ? Colors.green[800]
                              : Colors.red[800],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}