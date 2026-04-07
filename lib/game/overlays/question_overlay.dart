import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/supabase_config.dart';
import '../main_game.dart';

class QuestionOverlay extends StatefulWidget {
  final RabbitGame game;
  final String topic;
  const QuestionOverlay({super.key, required this.game, required this.topic});

  @override
  State<QuestionOverlay> createState() => _QuestionOverlayState();
}

class _QuestionOverlayState extends State<QuestionOverlay>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> questions = [];
  late Map<String, dynamic> current;
  bool loading = true;
  bool answered = false;
  String? selectedChoice;

  // Timer system
  static const int maxSeconds = 15;
  int remainingSeconds = maxSeconds;
  Timer? _timer;

  // Animations
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _resultController;
  late Animation<double> _resultScale;

  final Random _rng = Random();

  @override
  void initState() {
    super.initState();

    // Shake animation (for wrong answer)
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Result scale animation
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _resultScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.elasticOut),
    );

    loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  void _startTimer() {
    remainingSeconds = maxSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        remainingSeconds--;
      });
      if (remainingSeconds <= 0) {
        timer.cancel();
        // หมดเวลา = ตอบผิด
        if (!answered) {
          _onTimeUp();
        }
      }
    });
  }

  void _onTimeUp() {
    setState(() {
      answered = true;
      selectedChoice = null; // ไม่ได้เลือกข้อไหน
    });
    _shakeController.forward(from: 0);
    _resultController.forward(from: 0);
    widget.game.onAnswerSelected(false);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        widget.game.overlays.remove('QuestionOverlay');
        widget.game.resumeEngine();
      }
    });
  }

  Future<void> loadQuestions() async {
    try {
      final data = await QuestionService.fetchQuestions(widget.topic);
      if (!mounted) return;

      if (data.isNotEmpty) {
        questions = data;
        current = questions[_rng.nextInt(questions.length)];
      } else {
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
        _startTimer(); // ✅ เริ่ม Timer หลังโหลดเสร็จ
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
    current = questions[_rng.nextInt(questions.length)];
  }

  void select(String choice) {
    if (answered) return;

    _timer?.cancel();
    final correct = choice == current['answer'];

    setState(() {
      answered = true;
      selectedChoice = choice;
    });

    if (correct) {
      _resultController.forward(from: 0);
    } else {
      _shakeController.forward(from: 0);
      _resultController.forward(from: 0);
    }

    widget.game.onAnswerSelected(correct);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        widget.game.overlays.remove('QuestionOverlay');
        widget.game.resumeEngine();
      }
    });
  }

  // Timer Color
  Color _timerColor() {
    if (remainingSeconds > 10) return const Color(0xFF66BB6A);
    if (remainingSeconds > 5) return const Color(0xFFFFB74D);
    return const Color(0xFFEF5350);
  }

  // ปุ่ม Choice สไตล์ Pixel
  Widget _buildPixelButton(
      String text, VoidCallback? onPressed, Color bgColor, Color borderColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          top: BorderSide(color: borderColor, width: 3),
          left: BorderSide(color: borderColor, width: 3),
          right: BorderSide(color: borderColor.withOpacity(0.5), width: 3),
          bottom: BorderSide(color: borderColor.withOpacity(0.5), width: 5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          splashColor: Colors.white24,
          borderRadius: BorderRadius.circular(8),
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
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E2723),
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
    const bgColor = Color(0xFFFFF8E1);
    const borderColor = Color(0xFF5D4037);

    if (loading) {
      return Container(
        color: Colors.black54,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 6,
          ),
        ),
      );
    }

    final choices = List<String>.from(current['choices'] ?? []);
    final isCorrect = selectedChoice == current['answer'];

    return Material(
      color: Colors.black54,
      child: Center(
        child: AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final shakeOffset =
                answered && !isCorrect
                    ? sin(_shakeController.value * pi * 4) *
                        _shakeAnimation.value
                    : 0.0;
            return Transform.translate(
              offset: Offset(shakeOffset, 0),
              child: child,
            );
          },
          child: SingleChildScrollView(
            child: Container(
              width: 360,
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  border: Border.symmetric(
                    vertical: BorderSide(color: Color(0xFFD7CCC8), width: 4),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Timer Bar ---
                    Container(
                      width: double.infinity,
                      height: 28,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: Stack(
                        children: [
                          AnimatedFractionallySizedBox(
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeInOut,
                            widthFactor: (remainingSeconds / maxSeconds)
                                .clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _timerColor(),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer,
                                    size: 16,
                                    color: remainingSeconds <= 5
                                        ? Colors.red.shade900
                                        : borderColor),
                                const SizedBox(width: 4),
                                Text(
                                  "$remainingSeconds วินาที",
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: remainingSeconds <= 5
                                        ? Colors.red.shade900
                                        : borderColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- Question Icon ---
                    Container(
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB74D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 3),
                      ),
                      child: const Icon(Icons.question_mark,
                          size: 32, color: borderColor),
                    ),

                    // --- Question Text ---
                    Text(
                      current['question_text'] ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: borderColor,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Choices ---
                    ...choices.map((choice) {
                      Color btnColor = const Color(0xFFFFCC80);
                      Color btnBorder = borderColor;

                      if (answered) {
                        if (choice == current['answer']) {
                          btnColor = const Color(0xFF66BB6A);
                        } else if (choice == selectedChoice) {
                          btnColor = const Color(0xFFEF5350);
                        } else {
                          btnColor = Colors.grey.shade300;
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

                    // --- Result Animation ---
                    if (answered)
                      ScaleTransition(
                        scale: _resultScale,
                        child: Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCorrect
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCorrect
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: isCorrect
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isCorrect
                                    ? "ถูกต้อง! ไปลุยต่อ!"
                                    : selectedChoice == null
                                        ? "หมดเวลา!"
                                        : "ผิดพลาด! ระวังตัว!",
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isCorrect
                                      ? Colors.green[800]
                                      : Colors.red[800],
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
          ),
        ),
      ),
    );
  }
}