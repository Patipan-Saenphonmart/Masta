import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../main_game.dart';
import '../../data/game_data.dart';
import '../../models/book.dart';
import '../components/enemy.dart';
import 'package:flame/components.dart' as flame;
import '../../utils/audio_manager.dart'; // ✅ Import AudioManager

// =====================================================================
// Cutscene Overlay — 3 องก์: The Summoning Void → The Awakening → First Encounter
// =====================================================================

class CutsceneOverlay extends StatefulWidget {
  final RabbitGame game;
  const CutsceneOverlay({super.key, required this.game});

  @override
  State<CutsceneOverlay> createState() => _CutsceneOverlayState();
}

class _CutsceneOverlayState extends State<CutsceneOverlay>
    with TickerProviderStateMixin {
  // --- State ---
  int _currentAct = 1; // 1, 2, 3
  int _dialogIndex = 0;
  String _displayedText = '';
  bool _isTyping = false;
  Timer? _typeTimer;

  // --- Animation Controllers ---
  late AnimationController _glowController;
  late AnimationController _flashController;
  late AnimationController _fadeController;

  // --- องก์ 1: MASTA Dialogue ---
  final List<Map<String, String>> _act1Dialogues = [
    {
      'speaker': 'MASTA (ลึกลับ)',
      'text': 'สมการกำลังพังทลาย... กฎเกณฑ์ถูกบิดเบือน...'
    },
    {
      'speaker': 'MASTA',
      'text': 'พวกเขาใช้พลังโดยไม่เข้าใจแก่นแท้... โลกนี้กำลังจะแตกสลาย...'
    },
    {
      'speaker': 'MASTA',
      'text':
          'ดวงจิตจากต่างภพเอ๋ย... ผู้มองเห็นความจริงเบื้องหลังมายา... จงมาเป็นตาให้ข้า... จงมาเป็นผู้บันทึก...'
    },
  ];

  // --- องก์ 2: The Awakening Dialogue ---
  final List<Map<String, dynamic>> _act2Dialogues = [
    {
      'speaker': 'ผู้เล่น (คิดในใจ)',
      'text':
          '(อูย... ปวดหัวจัง... ที่นี่ที่ไหนเนี่ย? การสอบวิชาฟิสิกส์เมื่อกี้จบหรือยัง?)',
      'action': null,
    },
    {
      'speaker': '✦ SYSTEM',
      'text': '[ ตัวละครลุกขึ้นยืน ]',
      'action': 'wakeUp',
    },
    {
      'speaker': 'ผู้เล่น (ตกใจ)',
      'text':
          'เดี๋ยว!! ทำไมมือฉันเป็นสีเขียว... แล้วทำไมมันมีพังผืดด้วยเนี่ย!! ฉันกลายเป็นกบไปแล้วเรอะ!?',
      'action': null,
    },
    {
      'speaker': '✦ SYSTEM',
      'text': '[ มีหนังสือปกหนาตกอยู่ข้างๆ... มีออร่าเรืองแสง ]',
      'action': 'panToBook',
    },
    {
      'speaker': 'ผู้เล่น',
      'text':
          '(สมุดบันทึกงั้นเหรอ? หน้าปกเขียนว่า... The Scholar\'s Grimoire...)',
      'action': null,
    },
    {
      'speaker': '✦ SYSTEM',
      'text': '✦ ได้รับ: บันทึกแห่งจอมปราชญ์ (The Scholar\'s Grimoire) ✦',
      'action': 'pickUpBook',
    },
  ];

  // --- องก์ 3: First Encounter Dialogue ---
  final List<Map<String, dynamic>> _act3Dialogues = [
    {
      'speaker': '✦ SYSTEM',
      'text': '[ พุ่มไม้สั่นไหว... มีสิ่งมีชีวิตกำลังเคลื่อนเข้ามา!! ]',
      'action': 'spawnEnemy',
    },
    {
      'speaker': 'ผู้เล่น (ตกใจ)',
      'text': 'เวทมนตร์ไฟ!? ของจริงดิ!',
      'action': null,
    },
    {
      'speaker': 'ผู้เล่น (หรี่ตา)',
      'text':
          'เดี๋ยวนะ... อุณหภูมิการเผาไหม้นั้น... สีของเปลวไฟ... การขยายตัวของก๊าซ... นั่นมันไม่ใช่เวทมนตร์!',
      'action': null,
    },
    {
      'speaker': 'ผู้เล่น (ยิ้มกริ่ม)',
      'text':
          'มันคือปฏิกิริยาออกซิเดชัน (Oxidation Reaction) แบบคายความร้อนต่างหาก!! ถ้าฉันใช้สูตรนี้คำนวณโครงสร้างของมันล่ะก็...',
      'action': null,
    },
  ];

  // --- Flags ---
  bool _showWhiteFlash = false;
  bool _isTransitioning = false;
  bool _act2FadeDone = false;

  @override
  void initState() {
    super.initState();

    // Glow animation สำหรับสัญลักษณ์ MASTA
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // White flash animation
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Fade controller สำหรับ transition ระหว่างองก์
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // เริ่ม cutscene mode
    widget.game.isCutsceneMode = true;
    widget.game.rabbit.setSleeping();

    // ✅ เล่น BGM cutscene (จอดำ)
    AudioManager().playBgm(AudioManager.bgmCutscene);

    // เริ่มแสดง dialogue แรกขององก์ 1
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _startTyping(_act1Dialogues[0]['text']!);
    });
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _glowController.dispose();
    _flashController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // =====================================================================
  // Typewriter Effect
  // =====================================================================

  void _startTyping(String fullText) {
    _displayedText = '';
    _isTyping = true;
    int charIndex = 0;

    _typeTimer?.cancel();
    _typeTimer = Timer.periodic(const Duration(milliseconds: 45), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (charIndex < fullText.length) {
        setState(() {
          _displayedText = fullText.substring(0, charIndex + 1);
        });
        charIndex++;
      } else {
        timer.cancel();
        setState(() {
          _isTyping = false;
        });
      }
    });
  }

  // =====================================================================
  // Tap Handler
  // =====================================================================

  void _onTap() {
    if (_isTransitioning) return;

    // ถ้ายังพิมพ์ไม่เสร็จ → แสดงทั้งหมดทันที
    if (_isTyping) {
      _typeTimer?.cancel();
      setState(() {
        _isTyping = false;
        _displayedText = _getCurrentFullText();
      });
      return;
    }

    // ถ้าพิมพ์เสร็จแล้ว → ไปบทถัดไป
    _advanceDialogue();
  }

  String _getCurrentFullText() {
    switch (_currentAct) {
      case 1:
        return _act1Dialogues[_dialogIndex]['text']!;
      case 2:
        return _act2Dialogues[_dialogIndex]['text']!;
      case 3:
        return _act3Dialogues[_dialogIndex]['text']!;
      default:
        return '';
    }
  }

  String _getCurrentSpeaker() {
    switch (_currentAct) {
      case 1:
        return _act1Dialogues[_dialogIndex]['speaker']!;
      case 2:
        return _act2Dialogues[_dialogIndex]['speaker']! as String;
      case 3:
        return _act3Dialogues[_dialogIndex]['speaker']! as String;
      default:
        return '';
    }
  }

  void _advanceDialogue() {
    switch (_currentAct) {
      case 1:
        _advanceAct1();
        break;
      case 2:
        _advanceAct2();
        break;
      case 3:
        _advanceAct3();
        break;
    }
  }

  // =====================================================================
  // องก์ 1: The Summoning Void
  // =====================================================================

  void _advanceAct1() {
    if (_dialogIndex < _act1Dialogues.length - 1) {
      // ยังมีบทถัดไป
      setState(() {
        _dialogIndex++;
      });
      _startTyping(_act1Dialogues[_dialogIndex]['text']!);
    } else {
      // จบองก์ 1 → White Flash → เปลี่ยนไปองก์ 2
      _triggerWhiteFlash();
    }
  }

  void _triggerWhiteFlash() {
    _isTransitioning = true;
    AudioManager().playSfx(AudioManager.bgmWhiteFlash); // ✅ SFX Ving!

    setState(() {
      _showWhiteFlash = true;
    });

    _flashController.forward().then((_) {
      // Flash เต็มที่แล้ว → เปลี่ยนไปองก์ 2
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        setState(() {
          _currentAct = 2;
          _dialogIndex = 0;
          _showWhiteFlash = false;
        });
        _flashController.reset();
        _isTransitioning = false;

        // เริ่ม fade-in จากขาว → เผยฉากป่า
        _startAct2FadeIn();
      });
    });
  }

  // =====================================================================
  // องก์ 2: The Awakening
  // =====================================================================

  void _startAct2FadeIn() {
    // ซูมกล้องเข้าไปที่ตัวละคร
    widget.game.cameraComponent.viewfinder.zoom = 2.5;

    // Fade จากขาว
    setState(() {
      _act2FadeDone = false;
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      setState(() {
        _act2FadeDone = true;
      });
      // เริ่ม dialogue
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _startTyping(_act2Dialogues[0]['text']!);
        }
      });
    });
  }

  void _advanceAct2() {
    if (_dialogIndex < _act2Dialogues.length - 1) {
      setState(() {
        _dialogIndex++;
      });

      // เรียก action ถ้ามี
      final action = _act2Dialogues[_dialogIndex]['action'];
      _executeAction(action);

      _startTyping(_act2Dialogues[_dialogIndex]['text']!);
    } else {
      // จบองก์ 2 → เปลี่ยนไปองก์ 3
      _transitionToAct3();
    }
  }

  void _transitionToAct3() {
    _isTransitioning = true;

    // Flash สั้น ๆ ก่อนเข้าองก์ 3
    setState(() {
      _showWhiteFlash = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _showWhiteFlash = false;
        _currentAct = 3;
        _dialogIndex = 0;
      });
      _isTransitioning = false;

      // Execute action ของ dialogue แรก (spawn enemy)
      final action = _act3Dialogues[0]['action'];
      _executeAction(action);

      _startTyping(_act3Dialogues[0]['text']!);
    });
  }

  // =====================================================================
  // องก์ 3: The First Encounter
  // =====================================================================

  void _advanceAct3() {
    if (_dialogIndex < _act3Dialogues.length - 1) {
      setState(() {
        _dialogIndex++;
      });

      final action = _act3Dialogues[_dialogIndex]['action'];
      _executeAction(action);

      _startTyping(_act3Dialogues[_dialogIndex]['text']!);
    } else {
      // จบ Cutscene ทั้งหมด → เข้า Battle Tutorial!
      _endCutsceneAndStartBattle();
    }
  }

  void _endCutsceneAndStartBattle() {
    _isTransitioning = true;

    // Lens flare / flash effect
    AudioManager().playBgm(AudioManager.bgmBattle); // ✅ เปลี่ยน BGM เป็นเพลงบัตเทิล

    setState(() {
      _showWhiteFlash = true;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;

      // Mark cutscene as seen
      GameData.hasSeenIntroCutscene = true;
      // ✅ Mark tutorial as completed
      GameData.hasCompletedTutorial = true;

      // คืนกล้องให้ zoom ปกติ
      widget.game.cameraComponent.viewfinder.zoom = 1.8;

      // End cutscene mode
      widget.game.endCutsceneMode();

      // ลบ CutsceneOverlay
      widget.game.overlays.remove('CutsceneOverlay');

      // เข้า BattleOverlay เป็น Tutorial
      if (widget.game.enemy != null) {
        widget.game.inQuestion = true;
        widget.game.answered = false;
        widget.game.joystickDirection.setZero();
        widget.game.overlays.remove('BattleOverlay');
        widget.game.overlays.add('BattleOverlay');
      }
    });
  }

  // =====================================================================
  // Action Executor (สำหรับ cutscene events)
  // =====================================================================

  void _executeAction(String? action) {
    if (action == null) return;

    switch (action) {
      case 'wakeUp':
        // ตัวละครลุกขึ้นยืน
        widget.game.rabbit.wakeUp();
        debugPrint('🎭 Cutscene: Rabbit wakes up!');
        break;

      case 'panToBook':
        // เลื่อนกล้องไปที่หนังสือเล็กน้อย (offset จาก rabbit)
        // spawn WorldItem หนังสือ
        final bookPos = widget.game.rabbit.position + flame.Vector2(40, 20);
        final book = WorldItem(
          position: bookPos,
          size: flame.Vector2(20, 20),
          name: 'หนังสือจอมปราชญ์',
        )..priority = bookPos.y.toInt();
        widget.game.world.add(book);
        debugPrint('🎭 Cutscene: Book spawned at $bookPos');
        break;

      case 'pickUpBook':
        // เก็บหนังสือเข้า inventory
        final sageBook = Book.regular(
          id: 'sage_book',
          title: 'หนังสือจอมปราชญ์',
          description: 'บันทึกแห่งจอมปราชญ์',
          content: 'แด่ดวงจิตผู้มองเห็นความจริง... โลกนี้กำลังป่วยหนัก\nจงใช้ความรู้ของเจ้าแก้ไขมิตินี้',
        );
        GameData.addBook(sageBook);
        
        // ลบ WorldItem ออกจาก world
        for (final item in widget.game.world.children.whereType<WorldItem>().toList()) {
          if (item.name == 'บันทึกแห่งจอมปราชญ์' || item.name == 'หนังสือจอมปราชญ์') {
            item.removeFromParent();
          }
        }
        // คืนกล้องกลับมาที่ rabbit
        widget.game.cameraComponent.follow(widget.game.rabbit);
        debugPrint('🎭 Cutscene: Book picked up!');
        break;

      case 'spawnEnemy':
        // Spawn Ignis enemy ใกล้ๆ player
        final enemyPos = widget.game.rabbit.position + flame.Vector2(80, 0);
        final tutorialEnemy = Enemy(
          position: enemyPos,
          enemyName: 'Ignis ผู้โหดร้าย',
          element: 'ignis',
          strongSubject: 'ฟิสิกส์',
          weakSubject: 'เคมี',
        )
          ..size = flame.Vector2(48, 48)
          ..priority = enemyPos.y.toInt();
        tutorialEnemy.faceDirection(-1);
        widget.game.world.add(tutorialEnemy);
        widget.game.enemy = tutorialEnemy;

        // Freeze + Camera zoom ไปที่ศัตรู
        widget.game.freezeTimer = 999; // Freeze ค้างจนกว่า cutscene จะจบ
        widget.game.cameraComponent.viewfinder.zoom = 2.8;
        debugPrint('🎭 Cutscene: Tutorial enemy spawned!');
        break;
    }
  }

  // =====================================================================
  // Build UI
  // =====================================================================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // --- องก์ 1: พื้นหลังดำ + สัญลักษณ์ MASTA ---
          if (_currentAct == 1) _buildAct1Background(),

          // --- องก์ 2: Fade from white ---
          if (_currentAct == 2 && !_act2FadeDone) _buildAct2Fade(),

          // --- Dialogue Box (แสดงทุกองก์) ---
          if (_displayedText.isNotEmpty || !_isTransitioning)
            _buildDialogueBox(),

          // --- White Flash Effect ---
          if (_showWhiteFlash) _buildWhiteFlash(),

          // --- Tap indicator ---
          if (!_isTyping && _displayedText.isNotEmpty && !_isTransitioning)
            _buildTapIndicator(),
        ],
      ),
    );
  }

  // --- องก์ 1: จอดำ + MASTA symbol ---
  Widget _buildAct1Background() {
    return Container(
      color: Colors.black,
      child: Center(
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(200, 200),
              painter: _MastaSymbolPainter(
                glowIntensity: _glowController.value,
              ),
            );
          },
        ),
      ),
    );
  }

  // --- องก์ 2: Fade from white ---
  Widget _buildAct2Fade() {
    return AnimatedOpacity(
      opacity: _act2FadeDone ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 2000),
      child: Container(color: Colors.white),
    );
  }

  // --- White Flash ---
  Widget _buildWhiteFlash() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) {
        return Container(
          color: Colors.white.withOpacity(value),
        );
      },
    );
  }

  // --- Dialogue Box ---
  Widget _buildDialogueBox() {
    if (_displayedText.isEmpty && _isTransitioning) {
      return const SizedBox.shrink();
    }

    final speaker = _getCurrentSpeaker();
    final isSystem = speaker.contains('SYSTEM');
    final isMasta = speaker.contains('MASTA');

    // สีพื้นหลังตามผู้พูด
    Color bgColor;
    Color textColor;
    Color speakerColor;

    if (isMasta) {
      bgColor = Colors.black.withOpacity(0.85);
      textColor = const Color(0xFFE0B0FF); // สีม่วงอ่อนลึกลับ
      speakerColor = const Color(0xFFCE93D8);
    } else if (isSystem) {
      bgColor = const Color(0xFF1A237E).withOpacity(0.9);
      textColor = const Color(0xFFFFD54F); // สีทอง
      speakerColor = const Color(0xFFFFAB00);
    } else {
      bgColor = const Color(0xFF1B5E20).withOpacity(0.85);
      textColor = Colors.white;
      speakerColor = const Color(0xFF81C784);
    }

    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: speakerColor.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: speakerColor.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Speaker label
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: speakerColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: speakerColor.withOpacity(0.5)),
                ),
                child: Text(
                  speaker,
                  style: TextStyle(
                    color: speakerColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Text content
              Text(
                _displayedText,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.6,
                  letterSpacing: 0.3,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(1, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Tap indicator (กดเพื่อไปต่อ) ---
  Widget _buildTapIndicator() {
    return Positioned(
      bottom: 8,
      right: 32,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: 0.5 + (value * 0.5),
            child: Transform.translate(
              offset: Offset(0, sin(value * pi * 2) * 3),
              child: const Text(
                '▼ แตะเพื่อไปต่อ',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// =====================================================================
// CustomPainter: สัญลักษณ์ MASTA (ชามสปาเก็ตตี้ silhouette + glow)
// =====================================================================

class _MastaSymbolPainter extends CustomPainter {
  final double glowIntensity;

  _MastaSymbolPainter({required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Glow effect
    final glowPaint = Paint()
      ..color = Color.fromRGBO(
        180,
        130,
        255,
        0.15 + glowIntensity * 0.2,
      )
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30 + glowIntensity * 20);

    canvas.drawCircle(center, 70 + glowIntensity * 10, glowPaint);

    // ชาม (Bowl shape)
    final bowlPaint = Paint()
      ..color = Color.fromRGBO(180, 130, 255, 0.3 + glowIntensity * 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + glowIntensity * 3);

    // วาดรูปชาม
    final bowlPath = Path();
    bowlPath.moveTo(center.dx - 45, center.dy);
    bowlPath.quadraticBezierTo(
      center.dx - 50,
      center.dy + 40,
      center.dx,
      center.dy + 45,
    );
    bowlPath.quadraticBezierTo(
      center.dx + 50,
      center.dy + 40,
      center.dx + 45,
      center.dy,
    );
    canvas.drawPath(bowlPath, bowlPaint);

    // ขอบชามด้านบน
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx, center.dy), width: 90, height: 16),
      0,
      pi,
      false,
      bowlPaint,
    );

    // ฐานชาม
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 50),
        width: 30,
        height: 8,
      ),
      0,
      pi,
      false,
      bowlPaint,
    );

    // เส้นสปาเก็ตตี้ (เส้นหยัก ๆ ด้านบนชาม)
    final noodlePaint = Paint()
      ..color = Color.fromRGBO(255, 220, 150, 0.25 + glowIntensity * 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1 + glowIntensity * 2);

    for (int i = 0; i < 3; i++) {
      final noodlePath = Path();
      double startX = center.dx - 30 + i * 15;
      noodlePath.moveTo(startX, center.dy - 5);
      noodlePath.quadraticBezierTo(
        startX + 5,
        center.dy - 20 - i * 5,
        startX + 10,
        center.dy - 10,
      );
      noodlePath.quadraticBezierTo(
        startX + 15,
        center.dy - 30 - i * 3,
        startX + 20,
        center.dy - 15,
      );
      canvas.drawPath(noodlePath, noodlePaint);
    }

    // ไอน้ำ (steam)
    final steamPaint = Paint()
      ..color = Color.fromRGBO(200, 180, 255, 0.1 + glowIntensity * 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..maskFilter =
          MaskFilter.blur(BlurStyle.normal, 3 + glowIntensity * 4);

    for (int i = 0; i < 2; i++) {
      final steamPath = Path();
      double sx = center.dx - 15 + i * 30;
      steamPath.moveTo(sx, center.dy - 20);
      steamPath.quadraticBezierTo(
        sx - 5,
        center.dy - 40 - glowIntensity * 10,
        sx + 3,
        center.dy - 55 - glowIntensity * 10,
      );
      canvas.drawPath(steamPath, steamPaint);
    }

    // ข้อความ MASTA
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'MASTA',
        style: TextStyle(
          color: Color.fromRGBO(
            200,
            170,
            255,
            0.4 + glowIntensity * 0.2,
          ),
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 8,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy + 65,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _MastaSymbolPainter oldDelegate) {
    return oldDelegate.glowIntensity != glowIntensity;
  }
}
