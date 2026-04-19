import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../main_game.dart';
import '../../data/game_data.dart';
import '../../models/book.dart';
import '../../models/cutscene_script.dart';
import '../components/enemy.dart';
import 'package:flame/components.dart' as flame;
import '../../utils/audio_manager.dart';
import '../components/world_item.dart';
import '../components/MSTA_logo.dart';
import '../components/cutscene_script/openning_script.dart';

class CutsceneOverlay extends StatefulWidget {
  final RabbitGame game;
  const CutsceneOverlay({super.key, required this.game});

  @override
  State<CutsceneOverlay> createState() => _CutsceneOverlayState();
}

class _CutsceneOverlayState extends State<CutsceneOverlay>
    with TickerProviderStateMixin {
  // --- State ---
  int _dialogIndex = 0;
  String _displayedText = '';
  bool _isTyping = false;
  Timer? _typeTimer;

  // --- Animation Controllers ---
  late AnimationController _glowController;
  late AnimationController _flashController;

  // --- UI Effect Flags (driven by uiEffect field) ---
  bool _showMastaBg = false;
  bool _showWhiteFlash = false;
  bool _showFadeFromWhite = false;
  bool _isTransitioning = false;

  /// Shortcut: current script lines from the game engine.
  List<CutsceneLine> get _lines => widget.game.currentScript!.lines;

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

    // เริ่ม cutscene mode
    widget.game.isCutsceneMode = true;
    if (widget.game.currentScript == getOpeningScript()) {
      print("✅✅✅กระต่ายหลับ");
      widget.game.rabbit.setSleeping();
    }

    // ✅ เล่น BGM cutscene (จอดำ)
    AudioManager().playBgm(AudioManager.bgmCutscene);

    // อ่าน uiEffect ของบรรทัดแรก แล้วตั้งค่าสถานะ UI
    _applyUiEffect(_lines[0].uiEffect);

    // เริ่มแสดง dialogue แรก
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _startTyping(_lines[0].text);
    });
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _glowController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  // =====================================================================
  // UI Effect Handler (uiEffect field → overlay visuals)
  // =====================================================================

  /// Applies a visual effect **before** the dialogue text starts typing.
  /// This is the ONLY place the overlay interprets uiEffect strings.
  void _applyUiEffect(String? effect) {
    if (effect == null) return;

    switch (effect) {
      case 'showMastaBg':
        setState(() => _showMastaBg = true);
        break;

      case 'whiteFlash':
        // จะทำ flash หลังจากกดจบข้อความบรรทัดนี้ (ใน _advanceDialogue)
        // ตอน apply ยังไม่ต้องทำอะไร — flash จะถูก trigger ตอน advance
        break;

      case 'fadeFromWhite':
        // ซ่อน MASTA background, เริ่ม fade จากขาว
        setState(() {
          _showMastaBg = false;
          _showFadeFromWhite = true;
        });
        // ซูมกล้องเข้าไปที่ตัวละคร
        widget.game.cameraComponent.viewfinder.zoom = 2.5;
        // Fade ออกหลัง 2 วินาที
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            setState(() => _showFadeFromWhite = false);
          }
        });
        break;

      case 'transitionFlash':
        // Flash สั้นๆ ระหว่างองก์ (จะ trigger ตอน advance เหมือน whiteFlash)
        break;
    }
  }

  // =====================================================================
  // Game Action Handler (gameAction field → Flame engine commands)
  // =====================================================================

  /// Passes a command to the Flame game engine.
  /// This is the ONLY place the overlay communicates back to the game world.
  void _executeGameAction(String? action) {
    if (action == null) return;

    // ✅ ส่งคำสั่งกลับไปให้ Flame engine จัดการ (SRP: overlay ไม่ยุ่งกับ game world)
    widget.game.executeCutsceneAction(action);

    switch (action) {
      case 'wakeUp':
        widget.game.rabbit.wakeUp();
        debugPrint('🎭 Cutscene: Rabbit wakes up!');
        break;

      case 'panToBook':
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
        final sageBook = Book.regular(
          id: 'sage_book',
          title: 'หนังสือจอมปราชญ์',
          description: 'บันทึกแห่งจอมปราชญ์',
          content:
              'แด่ดวงจิตผู้มองเห็นความจริง... โลกนี้กำลังป่วยหนัก\nจงใช้ความรู้ของเจ้าแก้ไขมิตินี้',
        );
        GameData.addBook(sageBook);

        for (final item
            in widget.game.world.children.whereType<WorldItem>().toList()) {
          if (item.name == 'บันทึกแห่งจอมปราชญ์' ||
              item.name == 'หนังสือจอมปราชญ์') {
            item.removeFromParent();
          }
        }
        widget.game.cameraComponent.follow(widget.game.rabbit);
        debugPrint('🎭 Cutscene: Book picked up!');
        break;

      case 'spawnEnemy':
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
        tutorialEnemy.lastDirection = flame.Vector2(-1, 0);
        tutorialEnemy.updateAnimationState();
        widget.game.world.add(tutorialEnemy);
        widget.game.enemy = tutorialEnemy;

        widget.game.freezeTimer = 999;
        widget.game.cameraComponent.viewfinder.zoom = 2.8;
        debugPrint('🎭 Cutscene: Tutorial enemy spawned!');
        break;
    }
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
        _displayedText = _lines[_dialogIndex].text;
      });
      return;
    }

    // ถ้าพิมพ์เสร็จแล้ว → ไปบทถัดไป
    _advanceDialogue();
  }

  // =====================================================================
  // Advance Dialogue (single unified method)
  // =====================================================================

  void _advanceDialogue() {
    final currentLine = _lines[_dialogIndex];

    // --- ตรวจสอบ uiEffect ที่ต้อง trigger "ตอนจบบรรทัด" ---
    if (currentLine.uiEffect == 'whiteFlash') {
      _triggerWhiteFlash();
      return;
    }
    if (currentLine.uiEffect == 'transitionFlash') {
      _triggerTransitionFlash();
      return;
    }

    // --- ไปบรรทัดถัดไปตามปกติ ---
    _goToNextLine();
  }

  void _goToNextLine() {
    if (_dialogIndex < _lines.length - 1) {
      setState(() {
        _dialogIndex++;
      });

      final nextLine = _lines[_dialogIndex];

      // Apply uiEffect ของบรรทัดใหม่ (ถ้ามี)
      _applyUiEffect(nextLine.uiEffect);

      // Execute gameAction ของบรรทัดใหม่ (ถ้ามี)
      _executeGameAction(nextLine.gameAction);

      // เริ่มพิมพ์ข้อความ
      // ถ้ามี fadeFromWhite ให้รอ fade เสร็จก่อน
      if (nextLine.uiEffect == 'fadeFromWhite') {
        Future.delayed(const Duration(milliseconds: 2800), () {
          if (mounted) _startTyping(nextLine.text);
        });
      } else {
        _startTyping(nextLine.text);
      }
    } else {
      // จบ Cutscene ทั้งหมด
      _endCutsceneAndStartBattle();
    }
  }

  // =====================================================================
  // Transition Effects
  // =====================================================================

  void _triggerWhiteFlash() {
    _isTransitioning = true;
    AudioManager().playSfx(AudioManager.bgmWhiteFlash);

    setState(() => _showWhiteFlash = true);

    _flashController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        setState(() => _showWhiteFlash = false);
        _flashController.reset();
        _isTransitioning = false;

        // ไปบรรทัดถัดไป (ซึ่งจะมี fadeFromWhite)
        _goToNextLine();
      });
    });
  }

  void _triggerTransitionFlash() {
    _isTransitioning = true;

    setState(() => _showWhiteFlash = true);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _showWhiteFlash = false);
      _isTransitioning = false;

      _goToNextLine();
    });
  }

  // =====================================================================
  // End Cutscene
  // =====================================================================

  void _endCutsceneAndStartBattle() {
    _isTransitioning = true;

    AudioManager().playBgm(AudioManager.bgmBattle);

    setState(() => _showWhiteFlash = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;

      GameData.hasSeenIntroCutscene = true;
      GameData.hasCompletedTutorial = true;

      widget.game.cameraComponent.viewfinder.zoom = 1.8;
      widget.game.currentScript = null; // ✅ ล้างสคริปต์หลังจบ
      widget.game.endCutsceneMode();
      widget.game.overlays.remove('CutsceneOverlay');
    });
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
          // --- พื้นหลังดำ + สัญลักษณ์ MASTA (driven by _showMastaBg) ---
          if (_showMastaBg) _buildMastaBg(),

          // --- Fade from white (driven by _showFadeFromWhite) ---
          if (_showFadeFromWhite) _buildFadeFromWhite(),

          // --- Dialogue Box ---
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

  // --- พื้นหลังดำ + MASTA symbol ---
  Widget _buildMastaBg() {
    return Container(
      color: Colors.black,
      child: Center(
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(200, 200),
              painter: MastaSymbolPainter(
                glowIntensity: _glowController.value,
              ),
            );
          },
        ),
      ),
    );
  }

  // --- Fade from white ---
  Widget _buildFadeFromWhite() {
    return AnimatedOpacity(
      opacity: _showFadeFromWhite ? 1.0 : 0.0,
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

    final speaker = _lines[_dialogIndex].speaker;
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
