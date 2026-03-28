import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game_data.dart';
import '../../utils/save_manager.dart'; // ✅ Import SaveManager
import '../../data/question_bank.dart';
import '../rabbit_game.dart';
import '../battle/battle_engine.dart';
import '../battle/battle_models.dart';
import '../components/enemy.dart';

/// ====================================================================
/// Battle Overlay — สไตล์ Pokémon
/// Layout: ศัตรู (บนขวา) vs ผู้เล่น (ล่างซ้าย)
/// ล่างสุด: Action Panel (คำถาม / เลือกวิชา / เลือกโจทย์)
/// ====================================================================
class BattleOverlay extends StatefulWidget {
  final RabbitGame game;
  final Enemy enemy;
  const BattleOverlay({super.key, required this.game, required this.enemy});

  @override
  State<BattleOverlay> createState() => _BattleOverlayState();
}

class _BattleOverlayState extends State<BattleOverlay>
    with TickerProviderStateMixin {
  late BattleEngine engine;

  // --- State Machine ---
  // idle → enemyAsks → showResult → pickSubject → pickQuestion → aiAnswers → showResult → ...
  String phase =
      'intro'; // intro, enemyAsks, showResult, pickSubject, pickQuestion, aiThinking, aiResult

  // --- Question Data ---
  Map<String, dynamic>? currentQuestion;
  List<String> choices = [];
  bool loading = false;

  // --- Answer ---
  bool answered = false;
  String? selectedChoice;
  BattleResult? lastResult;

  // --- Timer ---
  static const int maxSeconds = 15;
  int remainingSeconds = maxSeconds;
  Timer? _timer;
  Stopwatch? _stopwatch;

  // --- Phase 2: เลือกโจทย์ ---
  String? pickedSubject;
  List<Map<String, dynamic>> questionOptions = [];

  // --- Animation ---
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _resultCtrl;
  late Animation<double> _resultScale;
  late AnimationController _slideCtrl;
  late AnimationController _spriteAnimCtrl;

  // --- Sprite ---
  ui.Image? _enemySpriteImage;
  ui.Image? _playerSpriteImage;
  bool _spritesLoaded = false;

  // --- Message log ---
  String battleMessage = '';
  bool showActionMenu = false;

  @override
  void initState() {
    super.initState();
    engine = BattleEngine(enemy: widget.enemy);

    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );

    _resultCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _resultScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _resultCtrl, curve: Curves.elasticOut),
    );

    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    _spriteAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();

    _loadSpriteImages();
    _startIntro();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeCtrl.dispose();
    _resultCtrl.dispose();
    _slideCtrl.dispose();
    _spriteAnimCtrl.dispose();
    super.dispose();
  }

  // =====================================================================
  // INTRO
  // =====================================================================
  void _startIntro() {
    final profile = engine.enemyProfile;
    setState(() {
      phase = 'intro';
      battleMessage = '${profile.elementEmoji} ${profile.name} ปรากฏตัว!';
    });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      _startEnemyAsks();
    });
  }

  // =====================================================================
  // PHASE 1: ศัตรูถาม → ผู้เล่นตอบ
  // =====================================================================
  Future<void> _startEnemyAsks() async {
    setState(() {
      phase = 'enemyAsks';
      loading = true;
      answered = false;
      selectedChoice = null;
      lastResult = null;
      battleMessage =
          '${engine.enemyProfile.name} โยนคำถาม${engine.enemyProfile.strongSubject}!';
    });

    final q = await QuestionBank.getRandomQuestion(widget.enemy.strongSubject);
    if (!mounted) return;

    setState(() {
      currentQuestion = q;
      choices = List<String>.from(q['choices'] ?? []);
      loading = false;
    });
    _startTimer();
  }

  void _startTimer() {
    remainingSeconds = maxSeconds;
    _stopwatch = Stopwatch()..start();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => remainingSeconds--);
      if (remainingSeconds <= 0) {
        t.cancel();
        if (!answered) _onTimeout();
      }
    });
  }

  void _onTimeout() {
    _stopwatch?.stop();
    setState(() {
      answered = true;
      selectedChoice = null;
    });
    lastResult = engine.processPlayerAnswer(
        correct: false, timeUsed: maxSeconds.toDouble());
    if (currentQuestion != null) {
      GameData.recordQuestion(
          currentQuestion!, widget.enemy.strongSubject, false);
    }
    _showPhase1Result(false);
  }

  void _selectAnswer(String choice) {
    if (answered) return;
    _timer?.cancel();
    _stopwatch?.stop();

    final correct = choice == currentQuestion!['answer'];
    final timeUsed = (_stopwatch?.elapsed.inMilliseconds ?? 15000) / 1000.0;

    setState(() {
      answered = true;
      selectedChoice = choice;
    });

    lastResult =
        engine.processPlayerAnswer(correct: correct, timeUsed: timeUsed);
    if (currentQuestion != null) {
      GameData.recordQuestion(
          currentQuestion!, widget.enemy.strongSubject, correct);
    }
    _showPhase1Result(correct);
  }

  void _showPhase1Result(bool correct) {
    if (correct) {
      String msg = 'ถูกต้อง! โจมตี -${lastResult!.finalDamage} HP';
      if (lastResult!.isCounter) {
        msg = '⚡ Counter Attack! -${lastResult!.finalDamage} HP!';
      }
      setState(() {
        battleMessage = msg;
        phase = 'showResult';
      });
      _resultCtrl.forward(from: 0);
    } else {
      setState(() {
        battleMessage = selectedChoice == null
            ? '⏰ หมดเวลา!'
            : '❌ ผิด! โดนโจมตี -${lastResult!.finalDamage} HP';
        phase = 'showResult';
      });
      _shakeCtrl.forward(from: 0);
      _resultCtrl.forward(from: 0);

      widget.game.damagePlayer(lastResult!.finalDamage);
      widget.game.rabbit.playHit();
    }

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      if (engine.battleEnded) {
        _endBattle();
        return;
      }
      if (widget.game.playerHP <= 0) {
        engine.battleEnded = true;
        engine.winner = 'enemy';
        _endBattle();
        return;
      }
      engine.nextTurn();
      _startPlayerChoice();
    });
  }

  // =====================================================================
  // PHASE 2: ผู้เล่นเลือกว่าจะสู้ต่อหรือหนี
  // =====================================================================
  void _startPlayerChoice() {
    setState(() {
      phase = 'playerChoice';
      battleMessage = 'จะสู้ต่อหรือหลบหนีดี?';
    });
  }

  void _onContinueFighting() {
    _startEnemyAsks();
  }

  void _onFlee() {
    setState(() {
      phase = 'defeat';
      battleMessage = '🏃 คุณหลบหนีจากการต่อสู้...';
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) widget.game.onBattleLost();
    });
  }

  // =====================================================================
  // END BATTLE
  // =====================================================================
  void _endBattle() {
    if (engine.winner == 'player') {
      final rewards = engine.calculateRewards();
      GameData.playerGold += rewards['gold'] ?? 0;

      // ✅ คำนวณ EXP และเช็คเลเวลอัพ
      int expGained = widget.enemy.maxHp * 2;
      int oldLevel = GameData.playerLevel;
      GameData.addExp(expGained);
      bool leveledUp = GameData.playerLevel > oldLevel;

      if (leveledUp) {
        widget.game.playerHP = widget.game.maxHP; // เติมเลือดเต็มเมื่อเวลอัพ
      }

      // ✅ เควสต์ปราบมอนสเตอร์
      GameData.updateQuestProgress('kill_monster', 1);

      // ✅ Auto-save เมื่อต่อสู้ชนะ
      SaveManager.saveGame();

      setState(() {
        phase = 'victory';
        battleMessage =
            '🏆 ชนะ!\nได้รับ ${rewards['gold']} Gold และ $expGained EXP!${leveledUp ? '\n🌟 เลเวลอัปเป็น ${GameData.playerLevel}!' : ''}';
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) widget.game.onBattleWon();
      });
    } else {
      setState(() {
        phase = 'defeat';
        battleMessage = '💀 แพ้...';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) widget.game.onBattleLost();
      });
    }
  }

  // =====================================================================
  // SPRITE LOADING
  // =====================================================================
  Future<void> _loadSpriteImages() async {
    try {
      _enemySpriteImage =
          await _loadImage(_enemySpriteAsset(widget.enemy.element));

      // ✅ เช็คว่าใส่เกราะไหม เพื่อโหลดรูปให้ตรงกับสถานะ
      bool hasArmor = GameData.isEquipped("เกราะวิเศษ (Magic Armor)");
      String suffix = hasArmor ? "_armor" : "";

      _playerSpriteImage =
          await _loadImage('assets/images/rabbit_idle$suffix.png');

      if (mounted) setState(() => _spritesLoaded = true);
    } catch (e) {
      debugPrint('Sprite load error: $e');
    }
  }

  Future<ui.Image> _loadImage(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  String _enemySpriteAsset(String element) {
    // ให้ทุกธาตุใช้รูป enemy_idle.png ชั่วคราวไปก่อน หรือตามที่ผู้ใช้แก้รูปไว้
    return 'assets/images/enemy_idle.png';
  }

  // =====================================================================
  // COLORS / HELPERS
  // =====================================================================
  Color _elementColor(String e) {
    switch (e) {
      case 'ignis':
        return const Color(0xFFFF7043);
      case 'arcana':
        return const Color(0xFFAB47BC);
      case 'vita':
        return const Color(0xFF66BB6A);
      case 'nexus':
        return const Color(0xFF42A5F5);
      default:
        return const Color(0xFF78909C);
    }
  }

  Color _timerColor() {
    if (remainingSeconds > 10) return const Color(0xFF4CAF50);
    if (remainingSeconds > 5) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  // =====================================================================
  // BUILD — Pokémon Layout
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    final profile = engine.enemyProfile;
    final playerHp = widget.game.playerHP;
    final playerMaxHp = widget.game.maxHP;
    final enemyHp = widget.enemy.hp;
    final enemyMaxHp = widget.enemy.maxHp;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // =================== BACKGROUND (Sprite) ==================
          Positioned.fill(
            child: Image.asset(
              'assets/images/back_attrack.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
            ),
          ),

          // =================== ENEMY INFO (บนขวา) ===================
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            left: MediaQuery.of(context).size.width * 0.5 + 8,
            child: _buildInfoBox(
              name: profile.name,
              emoji: profile.elementEmoji,
              level: 'Lv.${GameData.playerLevel + engine.turnCount}',
              hp: enemyHp,
              maxHp: enemyMaxHp,
              color: _elementColor(profile.element),
              isEnemy: true,
            ),
          ),

          // =================== ENEMY SPRITE (บนโขดหินล่างขวา) ===================
          Positioned(
            top: MediaQuery.of(context).size.height *
                0.40, // ย้ายลงมาใกล้ player
            right: MediaQuery.of(context).size.width * 0.05, // ชิดขวาขึ้น
            child: AnimatedBuilder(
              animation: _shakeAnim,
              builder: (ctx, child) {
                final offset = (phase == 'showResult' &&
                        lastResult != null &&
                        lastResult!.correct &&
                        engine.currentTurn == BattleTurn.enemyAsks)
                    ? sin(_shakeCtrl.value * pi * 4) * _shakeAnim.value
                    : 0.0;
                return Transform.translate(
                    offset: Offset(offset, 0), child: child);
              },
              child: _spritesLoaded && _enemySpriteImage != null
                  ? SizedBox(
                      width: 120, // ปรับให้ใหญ่ขึ้นให้มีขนาดใกล้เคียง Player
                      height: 120,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(
                            pi), // หันหน้าไปหา player (ทางซ้าย)
                        child: AnimatedBuilder(
                          animation: _spriteAnimCtrl,
                          builder: (ctx, _) => CustomPaint(
                            painter: _BattleSpritePainter(
                              image: _enemySpriteImage!,
                              animationValue: _spriteAnimCtrl.value,
                              frameWidth: 32, // enemy_idle มีเฟรมละ 32 pixels
                              frameHeight: 32,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: _elementColor(profile.element).withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                          child: Text(profile.elementEmoji,
                              style: const TextStyle(fontSize: 40))),
                    ),
            ),
          ),

          // =================== PLAYER INFO (บนซ้าย) ===================
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: MediaQuery.of(context).size.width * 0.5 + 8,
            child: _buildInfoBox(
              name: 'ผู้เล่น',
              emoji: '⚔️',
              level: 'Lv.${GameData.playerLevel}',
              hp: playerHp,
              maxHp: playerMaxHp,
              color: const Color(0xFF4CAF50),
              isEnemy: false,
            ),
          ),

          // =================== PLAYER SPRITE (ซ้ายล่าง — บน platform ดิน) ===================
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            left: MediaQuery.of(context).size.width * 0.05,
            child: AnimatedBuilder(
              animation: _shakeAnim,
              builder: (ctx, child) {
                final offset = (phase == 'aiResult' &&
                        lastResult != null &&
                        lastResult!.correct)
                    ? sin(_shakeCtrl.value * pi * 4) * _shakeAnim.value
                    : 0.0;
                return Transform.translate(
                    offset: Offset(offset, 0), child: child);
              },
              child: _spritesLoaded && _playerSpriteImage != null
                  ? SizedBox(
                      width: 120,
                      height: 120,
                      child: AnimatedBuilder(
                        animation: _spriteAnimCtrl,
                        builder: (ctx, _) => CustomPaint(
                          painter: _BattleSpritePainter(
                            image: _playerSpriteImage!,
                            animationValue: _spriteAnimCtrl.value,
                            frameWidth:
                                32, // ปรับขนาด frame ตาม sprite sheet ของกระต่าย (ปกติคือ 32x32)
                            frameHeight: 32,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                          child: Text('🐰', style: TextStyle(fontSize: 56))),
                    ),
            ),
          ),

          // =================== COMBO BADGE (ถ้ามี combo) ===================
          if (GameData.comboCount >= 2)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFF6F00), Color(0xFFFFA000)]),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  '🔥 COMBO ×${GameData.comboCount}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12),
                ),
              ),
            ),

          // =================== BOTTOM PANEL (สไตล์โปเกมอน) ===================
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(profile),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // INFO BOX (HP Bar สไตล์โปเกมอน)
  // =====================================================================
  Widget _buildInfoBox({
    required String name,
    required String emoji,
    required String level,
    required int hp,
    required int maxHp,
    required Color color,
    required bool isEnemy,
  }) {
    final hpPercent = (hp / maxHp).clamp(0.0, 1.0);
    final hpColor = hpPercent > 0.5
        ? const Color(0xFF4CAF50)
        : hpPercent > 0.2
            ? const Color(0xFFFF9800)
            : const Color(0xFFF44336);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5DC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5D4037), width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(0, 3), blurRadius: 0)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + Level
          Row(
            children: [
              Text('$emoji ', style: const TextStyle(fontSize: 16)),
              Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Color(0xFF3E2723)),
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF5D4037),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(level,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // HP Label + Bar
          Row(
            children: [
              const Text('HP ',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: Color(0xFF5D4037))),
              Expanded(
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF424242),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: hpPercent,
                    child: Container(
                      decoration: BoxDecoration(
                          color: hpColor,
                          borderRadius: BorderRadius.circular(5)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // HP Numbers
          Align(
            alignment: Alignment.centerRight,
            child: Text('$hp / $maxHp',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037))),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // BOTTOM PANEL (เมนูสไตล์โปเกมอน)
  // =====================================================================
  Widget _buildBottomPanel(EnemyBattleProfile profile) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5DC),
        border: Border(top: BorderSide(color: Color(0xFF5D4037), width: 4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // MESSAGE BOX
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Color(0xFFBCAAA4), width: 2)),
            ),
            child: Text(
              battleMessage,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF3E2723),
                height: 1.3,
              ),
            ),
          ),

          // ACTION AREA
          _buildActionArea(profile),
        ],
      ),
    );
  }

  // =====================================================================
  // ACTION AREA (เนื้อหาเปลี่ยนตาม phase)
  // =====================================================================
  Widget _buildActionArea(EnemyBattleProfile profile) {
    switch (phase) {
      case 'intro':
      case 'showResult':
      case 'victory':
      case 'defeat':
        return _buildWaitingPanel();
      case 'enemyAsks':
        return loading ? _buildLoadingPanel() : _buildQuestionPanel();
      case 'playerChoice':
        return _buildPlayerChoicePanel();
      default:
        return _buildWaitingPanel();
    }
  }

  // --- Waiting / Loading ---
  Widget _buildWaitingPanel() {
    final showVictory = phase == 'victory';
    final showDefeat = phase == 'defeat';
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showVictory) ...[
            const Text('🏆', style: TextStyle(fontSize: 32)),
          ] else if (showDefeat) ...[
            const Text('💀', style: TextStyle(fontSize: 32)),
          ] else ...[
            const Text('▶',
                style: TextStyle(fontSize: 18, color: Color(0xFF5D4037))),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingPanel() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(
          child: CircularProgressIndicator(
              strokeWidth: 3, color: Color(0xFF5D4037))),
    );
  }

  // --- QUESTION PANEL (Phase 1: ศัตรูถาม) ---
  Widget _buildQuestionPanel() {
    if (currentQuestion == null) return _buildWaitingPanel();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timer
          if (!answered) _buildTimer(),

          // Question
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF5D4037), width: 2),
            ),
            child: Text(
              currentQuestion!['question_text'] ?? '',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF3E2723),
                  height: 1.3),
            ),
          ),

          // Choices (2x2 grid สไตล์โปเกมอน)
          _buildChoicesGrid(),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.timer, size: 16, color: _timerColor()),
          const SizedBox(width: 4),
          Text('$remainingSeconds',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: _timerColor())),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF424242),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (remainingSeconds / maxSeconds).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                      color: _timerColor(),
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoicesGrid() {
    // สร้าง grid 2 columns สไตล์ Pokémon moves
    List<Widget> rows = [];
    for (int i = 0; i < choices.length; i += 2) {
      List<Widget> rowChildren = [];
      for (int j = i; j < i + 2 && j < choices.length; j++) {
        final choice = choices[j];
        rowChildren.add(Expanded(child: _buildChoiceButton(choice)));
        if (j < i + 1 && j + 1 < choices.length) {
          rowChildren.add(const SizedBox(width: 8));
        }
      }
      rows.add(Padding(
        padding: EdgeInsets.only(bottom: i + 2 < choices.length ? 8 : 0),
        child: Row(children: rowChildren),
      ));
    }
    return Column(children: rows);
  }

  Widget _buildChoiceButton(String choice) {
    Color bgColor = const Color(0xFFFFCC80);
    Color borderColor = const Color(0xFF5D4037);
    Color textColor = const Color(0xFF3E2723);

    if (answered) {
      if (choice == currentQuestion!['answer']) {
        bgColor = const Color(0xFF81C784);
        borderColor = const Color(0xFF2E7D32);
        textColor = const Color(0xFF1B5E20);
      } else if (choice == selectedChoice) {
        bgColor = const Color(0xFFE57373);
        borderColor = const Color(0xFFC62828);
        textColor = const Color(0xFFB71C1C);
      } else {
        bgColor = const Color(0xFFE0E0E0);
        borderColor = const Color(0xFF9E9E9E);
        textColor = const Color(0xFF757575);
      }
    }

    return GestureDetector(
      onTap: answered ? null : () => _selectAnswer(choice),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
                color: borderColor.withOpacity(0.3),
                offset: const Offset(0, 3),
                blurRadius: 0)
          ],
        ),
        child: Text(
          choice,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // --- PLAYER CHOICE ---
  Widget _buildPlayerChoicePanel() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _onContinueFighting,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF9A9A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFC62828), width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), offset: Offset(0, 3), blurRadius: 0)
                  ],
                ),
                child: const Text(
                  '⚔️ โจมตีต่อ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFFB71C1C)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _onFlee,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF90CAF9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1565C0), width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), offset: Offset(0, 3), blurRadius: 0)
                  ],
                ),
                child: const Text(
                  '🏃 หลบหนี',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF0D47A1)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================================
// CustomPainters สำหรับ Sprite Animation
// =======================================================================

/// วาด sprite sheet animation — เลือก frame ตาม animationValue
class _BattleSpritePainter extends CustomPainter {
  final ui.Image image;
  final double animationValue;
  final int frameWidth;
  final int frameHeight;

  _BattleSpritePainter({
    required this.image,
    required this.animationValue,
    required this.frameWidth,
    required this.frameHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // คำนวณจำนวน frames จากความกว้างรูป
    final totalFrames = (image.width / frameWidth).floor();
    if (totalFrames <= 0) return;

    final frameIndex =
        (animationValue * totalFrames).floor().clamp(0, totalFrames - 1);

    final src = Rect.fromLTWH(
      frameIndex * frameWidth.toDouble(),
      0,
      frameWidth.toDouble(),
      frameHeight.toDouble(),
    );
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(_BattleSpritePainter old) =>
      old.animationValue != animationValue;
}
