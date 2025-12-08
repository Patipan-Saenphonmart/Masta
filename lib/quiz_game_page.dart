import 'package:flutter/material.dart';
import 'supabase_config.dart';

class QuizPage extends StatefulWidget {
  final String topic;
  const QuizPage({super.key, required this.topic});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Map<String, dynamic>> questions = [];
  int currentIndex = 0;
  bool loading = true;

  int playerHP = 100;
  final int maxHP = 100;

  // state สำหรับการตอบ
  String? selectedAnswer;
  bool answered = false;

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    try {
      final data = await QuestionService.fetchQuestions(widget.topic);
      if (!mounted) return;
      setState(() {
        questions = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        questions = [];
        loading = false;
      });
    }
  }

  void checkAnswer(String choice) {
    if (answered) return; // ❌ ไม่ให้ตอบซ้ำ

    final q = questions[currentIndex];
    final correct = choice == q['answer'];

    setState(() {
      selectedAnswer = choice;
      answered = true;
    });

    if (correct) {
      // เสียง Effect หรือ Animation ตรงนี้ได้
    } else {
      setState(() {
        playerHP = (playerHP - 10).clamp(0, maxHP);
      });
      if (playerHP == 0) {
        // Game Over logic here
      }
    }
  }

  void goToNextQuestion() {
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedAnswer = null;
        answered = false;
      });
    } else {
      Navigator.pop(context); // จบเกมกลับหน้าหลัก
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 ภารกิจสำเร็จ! คุณผ่านทุกด่านแล้ว!')),
      );
    }
  }

  void showReasonDialog(String explanation) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1), // สีงาช้าง/กระดาษเก่า
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF795548), width: 4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('บันทึกความรู้', 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))
              ),
              const SizedBox(height: 10),
              Text(
                explanation.isNotEmpty ? explanation : 'ไม่มีคำอธิบายสำหรับข้อนี้',
                style: const TextStyle(fontSize: 16, color: Color(0xFF4E342E)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF795548)),
                onPressed: () => Navigator.pop(context),
                child: const Text('ปิด', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget สร้างปุ่มตัวเลือก (Choice)
  Widget _buildChoiceButton(String choice, bool isCorrectAnswer, bool isSelected) {
    // กำหนดสีปุ่มตามสถานะ
    List<Color> gradientColors = [const Color(0xFFD7CCC8), const Color(0xFFA1887F)]; // สีไม้ปกติ
    Color borderColor = const Color(0xFF795548);
    Color textColor = const Color(0xFF3E2723);
    IconData? statusIcon;

    if (answered) {
      if (choice == isCorrectAnswer.toString() || (answered && choice == questions[currentIndex]['answer'])) {
        // เฉลยถูก (สีเขียว)
        gradientColors = [const Color(0xFFA5D6A7), const Color(0xFF66BB6A)];
        borderColor = const Color(0xFF2E7D32);
        textColor = const Color(0xFF1B5E20);
        statusIcon = Icons.check_circle;
      } else if (isSelected && choice != questions[currentIndex]['answer']) {
        // ตอบผิด (สีแดง)
        gradientColors = [const Color(0xFFEF9A9A), const Color(0xFFEF5350)];
        borderColor = const Color(0xFFC62828);
        textColor = const Color(0xFFB71C1C);
        statusIcon = Icons.cancel;
      } else {
        // ข้อที่ไม่ได้เลือก (สีเทาจางลง)
        gradientColors = [Colors.grey.shade300, Colors.grey.shade400];
        borderColor = Colors.grey;
        textColor = Colors.grey.shade700;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 0,
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: answered ? null : () => checkAnswer(choice),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    choice,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
                if (statusIcon != null)
                  Icon(statusIcon, color: textColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.topic)),
        body: const Center(child: Text('ไม่มีคำถามในบทนี้')),
      );
    }

    final q = questions[currentIndex];
    final choices = List<String>.from(q['choices'] ?? []);
    final explanation = q['explanation'] ?? '';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF5D4037)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          widget.topic,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..color = const Color(0xFF5D4037),
          ),
        ),
      ),
      body: Container(
        // พื้นหลังธีมทุ่งหญ้า
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/images/bg_quiz.png'),
          fit: BoxFit.cover)
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- Status Bar (HP) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.redAccent, size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Stack(
                          children: [
                            FractionallySizedBox(
                              widthFactor: playerHP / maxHP,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFEF5350), Color(0xFFC62828)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: Text(
                                "$playerHP / $maxHP",
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 12,
                                  shadows: [Shadow(offset: Offset(0,1), color: Colors.black)]
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- Question Card ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9), // การ์ดสีขาว
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8D6E63).withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // หัวข้อ Quest
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Q ${currentIndex + 1}/${questions.length}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          if (answered)
                            IconButton(
                              onPressed: () => showReasonDialog(explanation),
                              icon: const Icon(Icons.help_outline, color: Colors.orange),
                              tooltip: "ดูคำอธิบาย",
                            )
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 10),
                      
                      // โจทย์คำถาม
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            q['question_text'] ?? '',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF37474F),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),

                      // ตัวเลือก
                      ...choices.map((c) => _buildChoiceButton(
                            c,
                            c == q['answer'], // เช็คว่าเป็นข้อถูกไหม
                            c == selectedAnswer, // เช็คว่าเป็นข้อที่เลือกไหม
                          )),
                      
                      const SizedBox(height: 20),

                      // ปุ่มถัดไป (แสดงเฉพาะเมื่อตอบแล้ว)
                      if (answered)
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: goToNextQuestion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFB74D), // สีส้มทอง
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Color(0xFFEF6C00), width: 2),
                              ),
                              elevation: 5,
                            ),
                            child: const Text(
                              'ไปต่อ >>',
                              style: TextStyle(
                                fontSize: 20, 
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [Shadow(color: Colors.black26, offset: Offset(1,1))]
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
      ),
    );
  }
}