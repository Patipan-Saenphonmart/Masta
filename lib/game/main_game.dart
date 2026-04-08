import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flame_tiled/flame_tiled.dart' hide Text;
import 'package:flame/collisions.dart';
import '../data/game_data.dart';
import 'components/player.dart';
import 'components/enemy.dart';
import 'components/tree.dart';
import 'utils/astar.dart';
import 'overlays/question_overlay.dart';
import 'overlays/skill_overlay.dart';
import 'overlays/battle_overlay.dart';
import 'overlays/game_over_overlay.dart';
import 'overlays/quest_overlay.dart'; // ✅ Import QuestOverlay
import 'overlays/inventory_overlay.dart'; // ✅ Import InventoryOverlay
import 'overlays/cutscene_overlay.dart'; // ✅ Import CutsceneOverlay
import 'overlays/minimap_overlay.dart'; // ✅ Import MiniMap
import 'overlays/game_ending_overlay.dart'; // ✅ Import GameEndingOverlay
import '../utils/save_manager.dart'; // ✅ Import SaveManager
import '../utils/audio_manager.dart'; // ✅ Import AudioManager
import '../page/home_page.dart'; // ✅ Import Home Page

// =====================================================================
// 1. WIDGET: Game Page & UI Overlays
// =====================================================================

class RabbitGamePage extends StatelessWidget {
  final bool showIntroCutscene; // ✅ เพิ่ม parameter สำหรับ cutscene
  const RabbitGamePage({super.key, this.showIntroCutscene = false});


  @override
  Widget build(BuildContext context) {
    final game = RabbitGame()
      ..isCutsceneMode = showIntroCutscene; // ✅ set cutscene mode flag

    return Scaffold(
      body: GameWidget<RabbitGame>(
        game: game,
        overlayBuilderMap: {
          'QuestionOverlay': (ctx, g) => QuestionOverlay(game: g, topic: ''),
          'SkillOverlay': (ctx, g) => SkillOverlay(game: g),
          'DialogOverlay': (ctx, g) => _buildDialogOverlay(ctx, g),
          'ActionOverlay': (ctx, g) => _buildActionOverlay(ctx, g),
          'BagOverlay': (ctx, g) => _buildBagOverlay(context, g),
          // ✅ Battle Overlay ใหม่
          'BattleOverlay': (ctx, g) => BattleOverlay(
                game: g,
                enemy: g.enemy ?? Enemy(),
              ),
          'GameOverOverlay': (ctx, g) => GameOverOverlay(game: g),
          'QuestOverlay': (ctx, g) =>
              QuestOverlay(game: g), // ✅ เพิ่ม Quest Overlay
          'OptionMenuOverlay': (ctx, g) => _buildOptionMenuOverlay(ctx, g),
          'InventoryOverlay': (ctx, g) => InventoryOverlay(game: g),
          // ✅ Cutscene Overlay
          'CutsceneOverlay': (ctx, g) => CutsceneOverlay(game: g),
          // ✅ MiniMap Overlay
          'MiniMapOverlay': (ctx, g) => MiniMapOverlay(game: g),
          // ✅ Game Ending Overlay
          'GameEndingOverlay': (ctx, g) => GameEndingOverlay(game: g),
        },
        initialActiveOverlays: showIntroCutscene
            ? const ['CutsceneOverlay'] // ✅ เริ่มด้วย cutscene ไม่มี UI อื่น
            : const [
                'SkillOverlay',
                'BagOverlay',
                'QuestOverlay'
              ], // ✅ เพิ่มเควสต์ในตอนเริ่มเกม
      ),
    );
  }

  // ✅ ปุ่ม Action ที่เปลี่ยนไอคอน/label ได้ (NPC / Portal / Item)
  // ย้ายมาแสดงตรงกลาง-ล่าง เพื่อไม่ซ้อนกับปุ่ม Skill ทางขวา
  Widget _buildActionOverlay(BuildContext context, RabbitGame game) {
    IconData icon = Icons.touch_app;
    Color bgColor = Colors.amber;
    String label = "กด";

    if (game.activeNpc != null) {
      icon = Icons.chat_bubble;
      bgColor = Colors.blueAccent;
      label = "คุย";
    } else if (game.activePortal != null) {
      icon = Icons.meeting_room_rounded;
      bgColor = Colors.amber;
      label = "เข้า";
    } else if (game.activeItem != null) {
      icon = Icons.back_hand;
      bgColor = Colors.green;
      label = "เก็บ";
    }

    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => game.onActionPressed(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: bgColor.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black45,
                        blurRadius: 6,
                        offset: Offset(0, 4))
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                              color: Colors.black45,
                              offset: Offset(1, 1),
                              blurRadius: 2)
                        ],
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

  // ✅ ปุ่มเซฟ & ปุ่มเปิดกระเป๋า (มุมขวาบน) — สไตล์ Pixel/Fantasy
  Widget _buildBagOverlay(BuildContext context, RabbitGame game) {
    return Positioned(
      top: 16,
      right: 16,
      child: Row(
        children: [
          // ⚙️ ปุ่ม ตั้งค่า (เปิด Option Menu)
          GestureDetector(
            onTap: () {
              game.overlays.add('OptionMenuOverlay');
            },
            child: Container(
              width: 52,
              height: 52,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF4E342E), width: 3),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, offset: Offset(0, 4))
                ],
              ),
              child: const Icon(Icons.settings,
                  color: Color(0xFFFFECB3), size: 28),
            ),
          ),

          // 🎒 ปุ่ม กระเป๋า (เปิด Inventory Overlay)
          GestureDetector(
            onTap: () {
              game.overlays.add('InventoryOverlay');
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF4E342E), width: 3),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, offset: Offset(0, 4))
                ],
              ),
              child: const Icon(Icons.backpack,
                  color: Color(0xFFFFECB3), size: 28),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Dialog สไตล์ Wood Frame — Fantasy theme
  Widget _buildDialogOverlay(BuildContext context, RabbitGame game) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF4E342E), // ขอบไม้เข้ม
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Colors.black54, blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1), // พื้นกระดาษครีม
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD7CCC8), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NPC label
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF795548),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text("NPC",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              Text(
                game.currentDialogMessage,
                style: const TextStyle(
                  color: Color(0xFF3E2723),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.bottomRight,
                child: GestureDetector(
                  onTap: () => game.closeDialog(),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8D6E63),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: const Color(0xFF5D4037), width: 2),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 3),
                            blurRadius: 0),
                      ],
                    ),
                    child: const Text(
                      "ปิด ▶",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ✅ เมนูตั้งค่า (Option Menu)
  Widget _buildOptionMenuOverlay(BuildContext context, RabbitGame game) {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1), // พื้นกระดาษครีม
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF8D6E63), width: 4),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black54, blurRadius: 10, offset: Offset(0, 5))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("การตั้งค่า (OPTIONS)",
                  style: TextStyle(
                    color: Color(0xFF4E342E),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Comic Sans MS',
                  )),
              const Divider(color: Color(0xFFD7CCC8), thickness: 2, height: 30),

              // 🎵 ปิด/เปิดเสียง
              _optionButton(
                  icon: Icons.music_note_rounded,
                  label: AudioManager().isMuted ? "เปิดเสียง" : "ปิดเสียง",
                  color: const Color(0xFF1976D2),
                  onTap: () {
                    AudioManager().toggleMute();
                    AudioManager().playSfx(AudioManager.sfxUiClick);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            AudioManager().isMuted
                                ? 'ปิดเสียงแล้ว 🔇'
                                : 'เปิดเสียงแล้ว 🔊',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold))));
                  }),
              const SizedBox(height: 12),

              // 🚪 ออกจากเกมกลับหน้าหลัก (✅ Auto Save + ไป Home แทน TitleScreen)
              _optionButton(
                  icon: Icons.door_back_door_rounded,
                  label: "กลับหน้าหลัก (Quit)",
                  color: const Color(0xFFD32F2F),
                  onTap: () async {
                    await SaveManager.savePlayerPosition(
                        game.rabbit.position.x, game.rabbit.position.y);
                    await SaveManager.saveGame(); // ✅ Auto-save ก่อนออก
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'บันทึกข้อมูลอัตโนมัติเรียบร้อยแล้ว! 💾',
                              style: TextStyle(fontWeight: FontWeight.bold))));
                      Navigator.pushAndRemoveUntil(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation,
                                  secondaryAnimation) =>
                              const LearningGameHome(), // ✅ ไป Home แทน TitleScreen
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                                opacity: animation, child: child);
                          },
                        ),
                        (route) => false,
                      );
                    }
                  }),
              const SizedBox(height: 12),

              // 🗑️ ลบข้อมูลเซฟ (Clear Save)
              _optionButton(
                  icon: Icons.delete_forever_rounded,
                  label: "ลบข้อมูลเซฟ (Reset)",
                  color: Colors.orange.shade800,
                  onTap: () async {
                    // ล้างข้อมูลทั้งหมด
                    await SaveManager.clearSave();
                    GameData.reset();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('ลบข้อมูลเซฟเรียบร้อยแล้ว! 🗑️',
                              style: TextStyle(fontWeight: FontWeight.bold))));
                      Navigator.pushAndRemoveUntil(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const LearningGameHome(), // กลับไปหน้า Home
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                                opacity: animation, child: child);
                          },
                        ),
                        (route) => false,
                      );
                    }
                  }),

              const SizedBox(height: 24),
              // ❌ กลับเข้าเกม
              GestureDetector(
                onTap: () => game.overlays.remove('OptionMenuOverlay'),
                child: const Text("▶ กลับสู่การผจญภัย",
                    style: TextStyle(
                        color: Color(0xFF795548),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Comic Sans MS')),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionButton(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black38, offset: Offset(0, 3), blurRadius: 2)
            ]),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 14),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Comic Sans MS')),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// 2. FLAME GAME LOGIC
// =====================================================================

class RabbitGame extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents {
  // --- Components ---
  late Rabbit rabbit;
  Enemy? enemy;
  @override
  late World world;
  late CameraComponent cameraComponent;
  late TiledComponent map;

  // --- Configuration ---
  int get maxHP => GameData.maxHp;
  double enemySpeed = 80;
  double enemyChaseRange = 250;

  // --- Game State ---
  int playerHP = 100;
  bool isGameOver = false; // ✅ Added Game Over flag
  bool inQuestion = false;
  bool answered = false;
  bool isWorldFrozen = false; // ✅ "The World" freeze flag
  bool isScanActive = false; // ✅ Scan ("The World") visual active

  // --- Cutscene State ---
  bool isCutsceneMode = false; // ✅ Cutscene mode flag

  // --- Interaction State ---
  String currentDialogMessage = "";
  bool isDialogActive = false;
  @override
  bool isLoading = false;
  double collisionCooldown = 0.0;

  // ✅ เพิ่มตัวแปรเก็บสิ่งที่กำลังเจอ
  Portal? activePortal;
  Npc? activeNpc;
  Npc? talkingNpc; // ✅ เก็บ NPC ที่กำลังคุยอยู่ เพื่อเปลี่ยนท่าทาง
  WorldItem? activeItem; // ✅ เก็บ Item ที่ยืนทับอยู่

  // ✅ Skill States
  bool isDashing = false;
  double dashTimer = 0.0;
  double freezeTimer = 0.0;
  Vector2 _dashAttackVelocity = Vector2.zero(); // สำหรับการพุ่งโจมตี

  // ✅ Track enemies hit during current attack to avoid multi-hit
  final Set<Enemy> hitEnemiesThisAttack = {};

  // --- Input ---
  final Random rand = Random();
  Vector2 joystickDirection = Vector2.zero();
  Vector2 lastDirection = Vector2(1, 0);

  // --- Walk Step SFX ---
  double _walkStepTimer = 0.0;
  static const double _walkStepInterval =
      0.35; // เล่นเสียงก้าวเดินทุก 0.35 วินาที
  bool _isEnemyChasingPlayer = false;

  // --- Auto save player position ---
  double _positionSaveTimer = 0.0;
  static const double _positionSaveInterval = 2.0;

  // --- Respawn & Loot ---
  final List<_RespawnData> _respawnWaitList = [];

  // --- Transition ---
  bool _isTransitioning = false;
  double _transitionAlpha = 0.0;

  // -------------------------------------------------------------------
  // Lifecycle Methods
  // -------------------------------------------------------------------

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    playerHP = maxHP;
    final savedPos = await SaveManager.loadPlayerPosition();
    final spawnPos = savedPos != null
        ? Vector2(savedPos['x']!, savedPos['y']!)
        : Vector2(3678, 2464); // ********************** จุดกระต่ายเกิดใหม่ตั้งแต่เริ่มเกมครั้งแรก **********************

    world = World();
    add(world);

    cameraComponent = CameraComponent(world: world)
      ..viewfinder.anchor = Anchor.center
      ..viewfinder.zoom = 1.8;
    add(cameraComponent);

    // ✅ ลบ HpBar (Flame component) ออก — ใช้ HP Bar จาก SkillOverlay แทน เพื่อไม่ให้ซ้ำซ้อน
    // hpBar ถูกแทนที่ด้วย HP bar ใน skill_overlay.dart

    rabbit = Rabbit()
      ..priority = 100
      ..position = spawnPos.clone();
    world.add(rabbit);
    cameraComponent.follow(rabbit);

    await loadLevel('new.tmx', spawnPos);

    // ✅ เล่น BGM overworld (ถ้าไม่ใช่ cutscene mode)
    if (!isCutsceneMode) {
      AudioManager().playBgm(AudioManager.bgmOverworld);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // ✅ ค่อยๆ จางหน้าจอออกหลังเปลี่ยนฉาก
    if (_isTransitioning && !isLoading) {
      _transitionAlpha -= dt * 2.0; // จางออกใน 0.5 วินาที
      if (_transitionAlpha <= 0) {
        _transitionAlpha = 0;
        _isTransitioning = false;
      }
    }

    // ✅ อัปเดต Camera Zoom (ต้องทำแม้โลกจะ freeze)
    _updateCameraZoom(dt);

    if (isLoading) return;

    // ✅ Cutscene mode: หยุดทุก gameplay รอ cutscene overlay ควบคุม
    if (isCutsceneMode) return;

    // ✅ "The World" freeze: หยุดทุกอย่างยกเว้น player
    if (isWorldFrozen) return;

    // ✅ ป้องกันไม่ให้ทำอย่างอื่นถ้า Game Over แล้ว
    if (isGameOver) return;

    if (playerHP <= 0 && !isGameOver) {
      isGameOver = true;
      rabbit.playDeath();
      joystickDirection.setZero();

      // ✅ ทำของตกหมดตัว (เทไอเทมลงพื้น)
      _dropAllItems();

      overlays.remove('SkillOverlay');
      overlays.remove('BagOverlay');
      overlays.remove('ActionOverlay');
      overlays.remove('BattleOverlay');
      overlays.remove('QuestOverlay'); // ✅ ซ่อนหน้าต่างเควสต์
      overlays.add('GameOverOverlay');
      return;
    }

    if (collisionCooldown > 0) collisionCooldown -= dt;

    // ✅ Player Continuous Attack Hitbox Check (ติดหน้าผู้เล่นตลอดอนิเมชัน)
    if (rabbit.isAttacking) {
      const double attackReach = 40.0;
      const double attackWidth = 60.0;
      // ใช้ lastDirection จาก RabbitGame แทน rabbit.lastDirection
      Vector2 attackCenter = rabbit.position + (lastDirection * attackReach);
      Rect attackRect = Rect.fromCenter(
        center: Offset(attackCenter.x, attackCenter.y),
        width: attackWidth,
        height: attackWidth,
      );

      // ✅ แสดง Hitbox สีแดงของผู้เล่นเพื่อทดสอบ (วาดตลอดที่ตี)
      world.add(DebugHitbox(
        position: attackCenter,
        size: Vector2(attackWidth, attackWidth),
        lifetime: 0.1,
      ));

      for (final e in world.children.whereType<Enemy>()) {
        if (e.alive && !hitEnemiesThisAttack.contains(e)) {
          if (attackRect.overlaps(e.toRect())) {
            hitEnemiesThisAttack.add(e);
            if (e.hasShield) {
              showDialog("ศัตรูมีเกราะป้องกัน! ต้องใช้สแกนเพื่อทำลายเกราะก่อน");
            } else {
              int damage = 10;
              if (GameData.isEquipped("ดาบสายฟ้า (Thunder Sword)")) {
                damage += 5;
              }
              e.takeDamage(damage);
              AudioManager().playSfx(AudioManager.sfxGetHit);
            }
          }
        }
      }
    }

    if (isDashing) {
      dashTimer -= dt;
      if (dashTimer <= 0) isDashing = false;
    }

    if (freezeTimer > 0) {
      freezeTimer -= dt;
    }

    // ✅ ตรวจสอบการ Respawn มอนสเตอร์
    _updateRespawns(dt);

    world.children.whereType<PositionComponent>().forEach((component) {
      if (component is Rabbit ||
          component is Enemy ||
          component is Npc ||
          component is Decoration ||
          component is WorldItem ||
          component is Tree) {
        double bottomY = component.position.y;
        if (component.anchor == Anchor.center) {
          bottomY += component.size.y / 2;
        }
        component.priority = bottomY.toInt();
      }
    });

    if (!inQuestion && !isDialogActive) {
      _updatePlayer(dt);
      _checkInteractions();
      _updateEnemies(dt);
    }

    _positionSaveTimer += dt;
    if (_positionSaveTimer >= _positionSaveInterval) {
      _positionSaveTimer = 0.0;
      SaveManager.savePlayerPosition(rabbit.position.x, rabbit.position.y);
      _updateExploration(); // ✅ อัปเดต Fog of War สำรวจแผนที่
    }
  }

  // ✅ ระบบเปิดแผนที่ (Fog of War)
  void _updateExploration() {
    const double chunkSize = 150.0; // ขนาดพื้นที่ 1 ช่องที่จะเปิด
    int chunkX = (rabbit.position.x / chunkSize).floor();
    int chunkY = (rabbit.position.y / chunkSize).floor();

    bool newlyDiscovered = false;
    // เปิดรอบตัวกระต่าย (ระยะการมองเห็น: รัศมี 1 chunk)
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        String key = "${chunkX + dx},${chunkY + dy}";
        if (!GameData.exploredChunks.contains(key)) {
          GameData.exploredChunks.add(key);
          newlyDiscovered = true;
        }
      }
    }

    // เซฟการค้นพบใหม่
    if (newlyDiscovered) {
      SaveManager.saveGame();
    }
  }

  // -------------------------------------------------------------------
  // Update Logic Helpers
  // -------------------------------------------------------------------

  @override
  void render(Canvas canvas) {
    // ✅ Scan B&W effect: วาดผ่าน ColorFilter grayscale
    if (isScanActive) {
      canvas.saveLayer(
        size.toRect(),
        Paint()
          ..colorFilter = const ui.ColorFilter.matrix(<double>[
            0.2126, 0.7152, 0.0722, 0, 0, // R
            0.2126, 0.7152, 0.0722, 0, 0, // G
            0.2126, 0.7152, 0.0722, 0, 0, // B
            0,      0,      0,      1, 0, // A
          ]),
      );
      super.render(canvas);
      canvas.restore();

      // ✅ Dark overlay tint เพื่อเพิ่มอารมณ์ "The World"
      canvas.drawRect(
        size.toRect(),
        Paint()..color = Colors.deepPurple.withOpacity(0.15),
      );
    } else {
      super.render(canvas);
    }

    // ✅ วาด Transition (หน้าจอดำ)
    if (_isTransitioning) {
      canvas.drawRect(
        size.toRect(),
        Paint()..color = Colors.black.withOpacity(_transitionAlpha),
      );
    }
  }

  // ✅ อัปเดตการเคลื่อนที่ของกระต่าย (4 ทิศทาง)
  void _updatePlayer(double dt) {
    if (rabbit.isHitPlaying) return;

    Vector2 currentMoveDir = Vector2.zero();
    double currentSpeed = 100.0 + (GameData.agility * 1.5);

    // ✅ ถ้ากำลังโจมตี ให้เพิกเฉยต่อจอยสติ๊ก และล็อกทิศทาง/การเคลื่อนไหว
    if (rabbit.isAttacking) {
      if (_dashAttackVelocity.length > 0) {
        currentMoveDir = _dashAttackVelocity.normalized();
        currentSpeed = _dashAttackVelocity.length;
      } else {
        return; // โจมตีอยู่กับที่
      }
    } else {
      if (joystickDirection.length > 0.01) {
        currentMoveDir = joystickDirection.normalized();
        if (isDashing) currentSpeed *= 2.5;

        // ✅ กำหนดทิศทางแอนิเมชัน โดยเช็คแกนที่มีค่ามากกว่า
        if (joystickDirection.x.abs() >= joystickDirection.y.abs()) {
          // แนวนอนเด่นกว่า → ซ้าย/ขวา
          if (joystickDirection.x > 0) {
            rabbit.setState(RabbitState.runRight);
          } else {
            rabbit.setState(RabbitState.runLeft);
          }
        } else {
          // แนวตั้งเด่นกว่า → ขึ้น/ลง
          if (joystickDirection.y > 0) {
            rabbit.setState(RabbitState.runDown);
          } else {
            rabbit.setState(RabbitState.runUp);
          }
        }

        lastDirection = joystickDirection.normalized();

        // ✅ Walking step SFX (เล่นทุก interval)
        _walkStepTimer += dt;
        if (_walkStepTimer >= _walkStepInterval) {
          _walkStepTimer = 0.0;
          AudioManager().playWalkStep();
        }
      } else {
        // ✅ Idle: เปลี่ยนเป็น idle ตามทิศทางสุดท้าย
        if (lastDirection.x.abs() >= lastDirection.y.abs()) {
          if (lastDirection.x > 0) {
            rabbit.setState(RabbitState.idleRight);
          } else {
            rabbit.setState(RabbitState.idleLeft);
          }
        } else {
          if (lastDirection.y > 0) {
            rabbit.setState(RabbitState.idleDown);
          } else {
            rabbit.setState(RabbitState.idleUp);
          }
        }
        _walkStepTimer = 0.0; // ✅ Reset walk timer when idle
        return; // ไม่ต้องอัปเดต collision ถ้าไม่ได้เดิน
      }
    }

    // --- Player Sliding Collision ---
    final velocity = currentMoveDir * currentSpeed * dt;
    final double hitW = 30.0;
    final double hitH = 14.0;
    final double offsetY = 18.0;

    final nextX = rabbit.position.x + velocity.x;
    final rectX = Rect.fromCenter(
        center: Offset(nextX, rabbit.position.y + offsetY),
        width: hitW,
        height: hitH);
    bool hitWallX = false;
    for (final obstacle in world.children.whereType<Obstacle>()) {
      if (rectX.overlaps(obstacle.toRect())) {
        hitWallX = true;
        break;
      }
    }
    if (!hitWallX) rabbit.position.x = nextX;

    final nextY = rabbit.position.y + velocity.y;
    final rectY = Rect.fromCenter(
        center: Offset(rabbit.position.x, nextY + offsetY),
        width: hitW,
        height: hitH);
    bool hitWallY = false;
    for (final obstacle in world.children.whereType<Obstacle>()) {
      if (rectY.overlaps(obstacle.toRect())) {
        hitWallY = true;
        break;
      }
    }
    if (!hitWallY) rabbit.position.y = nextY;
  }

  // ✅ ฟังก์ชันเช็ค NPC, Portal และ Item
  void _checkInteractions() {
    if (collisionCooldown > 0) return;

    bool foundSomething = false;

    // 1. เช็ค NPC
    for (final npc in world.children.whereType<Npc>()) {
      if (rabbit.toRect().inflate(10).overlaps(npc.toRect())) {
        foundSomething = true;
        if (activeNpc != npc) {
          activeNpc = npc;
          activePortal = null;
          activeItem = null;
          overlays.add('ActionOverlay');
          overlays.remove('ActionOverlay');
          overlays.add('ActionOverlay');
        }
        break;
      }
    }

    // 2. เช็ค Portal
    if (!foundSomething) {
      for (final portal in world.children.whereType<Portal>()) {
        if (rabbit.toRect().inflate(5).overlaps(portal.toRect())) {
          foundSomething = true;
          if (activePortal != portal) {
            activePortal = portal;
            activeNpc = null;
            activeItem = null;
            overlays.add('ActionOverlay');
            overlays.remove('ActionOverlay');
            overlays.add('ActionOverlay');
          }
          break;
        }
      }
    }

    // ✅ 3. เช็ค Item (เก็บของ)
    if (!foundSomething) {
      for (final item in world.children.whereType<WorldItem>()) {
        if (rabbit.toRect().inflate(5).overlaps(item.toRect())) {
          foundSomething = true;
          if (activeItem != item) {
            activeItem = item;
            activePortal = null;
            activeNpc = null;
            overlays.add('ActionOverlay');
            overlays.remove('ActionOverlay');
            overlays.add('ActionOverlay');
          }
          break;
        }
      }
    }

    // ถ้าไม่เจออะไรเลย ให้เอาปุ่มออก
    if (!foundSomething) {
      if (activePortal != null || activeNpc != null || activeItem != null) {
        activePortal = null;
        activeNpc = null;
        activeItem = null;
        overlays.remove('ActionOverlay');
      }
    }
  }
  // -------------------------------------------------------------------
  // Pathfinding (A*)
  // -------------------------------------------------------------------

  // แปลงพิกัดเกมให้กลายเป็นตาราง (Grid) สำหรับการค้นหาเส้นทาง
  List<Vector2> findPathToPlayer(Vector2 enemyPos) {
    if (map.tileMap.map.width == 0) return []; // แกะแผนที่ไม่ได้

    // ตั้งค่าขนาดช่องเซลล์ (Grid Size) ยิ่งเล็กยิ่งละเอียดแต่กินสเปค
    const int gridSize = 32;

    double mapWidth =
        map.tileMap.map.width * map.tileMap.map.tileWidth.toDouble();
    double mapHeight =
        map.tileMap.map.height * map.tileMap.map.tileHeight.toDouble();

    int gw = (mapWidth / gridSize).ceil();
    int gh = (mapHeight / gridSize).ceil();

    int startX = (enemyPos.x / gridSize).floor();
    int startY = (enemyPos.y / gridSize).floor();

    int targetX = (rabbit.position.x / gridSize).floor();
    int targetY = (rabbit.position.y / gridSize).floor();

    // ป้องกันการหาเส้นทางถ้านอกขอบตาราง
    if (startX < 0 ||
        startX >= gw ||
        startY < 0 ||
        startY >= gh ||
        targetX < 0 ||
        targetX >= gw ||
        targetY < 0 ||
        targetY >= gh) {
      return [];
    }

    // --- Optimization: Cache obstacles so we aren't iterating over all components repeatedly ---
    final obstaclesToRects =
        world.children.whereType<Obstacle>().map((o) => o.toRect()).toList();
    final Map<String, bool> walkableCache = {};

    // ฟังก์ชันเช็คว่าช่องนี้กำแพงหรือไม่ โดยนำกรอบสี่เหลี่ยมพิกัดกล่องชน (Rect) ไปเทียบกับ Obstacle
    bool isWalkable(int x, int y) {
      final cacheKey = '$x,$y';
      if (walkableCache.containsKey(cacheKey)) {
        return walkableCache[cacheKey]!;
      }

      // หดขนาดเช็คลงมา 2px ป้องกันเหลี่ยมกำแพงติดกันจนมองว่าเดินไม่ได้
      Rect cellRect = Rect.fromLTWH(
          x * gridSize.toDouble() + 2,
          y * gridSize.toDouble() + 2,
          gridSize.toDouble() - 4,
          gridSize.toDouble() - 4);

      for (int i = 0; i < obstaclesToRects.length; i++) {
        if (cellRect.overlaps(obstaclesToRects[i])) {
          walkableCache[cacheKey] = false;
          return false;
        }
      }

      walkableCache[cacheKey] = true;
      return true;
    }

    final pathCells = AStar.findPath(
      startX: startX,
      startY: startY,
      targetX: targetX,
      targetY: targetY,
      gridWidth: gw,
      gridHeight: gh,
      isWalkable: isWalkable,
    );

    // แปลงกลับเป็นพิกัดจริงบนหน้าจอ
    return pathCells
        .map((p) => Vector2(p.x * gridSize.toDouble() + (gridSize / 2),
            p.y * gridSize.toDouble() + (gridSize / 2)))
        .toList();
  }

  void _updateEnemies(double dt) {
    bool hasChasingEnemy = false;
    for (final e in world.children.whereType<Enemy>()) {
      if (e.isMounted && e.alive) {
        if (freezeTimer > 0) continue;

        final distance = rabbit.position.distanceTo(e.position);
        Vector2 moveDir = Vector2.zero();

        e.pathRecalculateTimer -= dt;

        e.pathRecalculateTimer -= dt;

        // ✅ ถ้าศัตรูกำลังโจมตีอยู่ ให้บอทยืนนิ่งฟัน
        if (e.isAttacking) {
          moveDir = Vector2.zero();
        }
        else if (distance < enemyChaseRange) {
          hasChasingEnemy = true;
          // รีแคลคิวเลท Path ทุกๆ 0.5 วินาทีเพื่อไม่ให้หน่วงเครื่อง
          if (e.pathRecalculateTimer <= 0) {
            e.currentPath = findPathToPlayer(e.position);
            e.pathRecalculateTimer = 0.5;
          }

          if (e.currentPath.isNotEmpty) {
            // เล็งเป้าที่ waypoint ปัจจุบัน
            final waypoint = e.currentPath.first;
            if (e.position.distanceTo(waypoint) < 5.0) {
              e.currentPath.removeAt(0);
              if (e.currentPath.isNotEmpty) {
                moveDir = (e.currentPath.first - e.position).normalized();
              }
            } else {
              moveDir = (waypoint - e.position).normalized();
            }
          } else {
            // ถ้าไม่เจอทางเดิน (ถูกขัง) เข้าถึงไม่ได้ ลองเดินตรงไปมั่วๆ
            moveDir = (rabbit.position - e.position).normalized();
          }
        } else {
          e.currentPath.clear();
        }

        e.velocity = moveDir * enemySpeed;

        // --- Enemy Sliding Collision (เช็คกำแพงเฉพาะเท้าแบบ 2D Top-Down) ---
        final double enemyHitW = 20.0;
        final double enemyHitH = 10.0;
        final double enemyOffsetY = 10.0; // ขยับจุดเช็คชนลงมาที่เท้า

        final double moveX = e.velocity.x * dt;
        final double moveY = e.velocity.y * dt;

        final nextEx = e.position.x + moveX;
        final rectEx = Rect.fromCenter(
            center: Offset(nextEx, e.position.y + enemyOffsetY),
            width: enemyHitW,
            height: enemyHitH);
        bool hitWallEx = false;
        for (final obstacle in world.children.whereType<Obstacle>()) {
          if (rectEx.overlaps(obstacle.toRect())) {
            hitWallEx = true;
            break;
          }
        }
        if (!hitWallEx) e.position.x = nextEx;

        final nextEy = e.position.y + moveY;
        final rectEy = Rect.fromCenter(
            center: Offset(e.position.x, nextEy + enemyOffsetY),
            width: enemyHitW,
            height: enemyHitH);
        bool hitWallEy = false;
        for (final obstacle in world.children.whereType<Obstacle>()) {
          if (rectEy.overlaps(obstacle.toRect())) {
            hitWallEy = true;
            break;
          }
        }
        if (!hitWallEy) e.position.y = nextEy;

        // 1. ระยะที่ศัตรูจะ "เริ่มง้างตี"
        double attackTriggerRange = 40.0; 
        double distanceToPlayer = rabbit.position.distanceTo(e.position);

        // ถ้าผู้เล่นอยู่ในระยะ และศัตรูไม่ได้กำลังโจมตีอยู่ ให้เริ่มการโจมตี (และหมดคูลดาวน์แล้ว)
        if (distanceToPlayer <= attackTriggerRange && !e.isAttacking && e.attackCooldownTimer <= 0) {
          Vector2 dirToPlayer = (rabbit.position - e.position).normalized();
          e.attackTargetDir = dirToPlayer;
          
          // เล่นแอนิเมชันโจมตีและตั้งค่าคูลดาวน์
          e.playAttack();
          e.hasDealtDamageThisAttack = false; // เซ็ตสถานะว่ายังไม่ได้ทำดาเมจในรอบการโจมตีนี้
          e.attackCooldownTimer = 2.0; // ✅ ตั้งคูลดาวน์การโจมตีครั้งต่อไป (เช่น 2 วินาที)
        }

        // 2. เช็คการทำดาเมจ "ระหว่าง" อนิเมชัน (ตรวจจับตลอดช่วงการโจมตี ไม่เช็คแค่ช่วง 95%)
        if (e.isAttacking && !e.hasDealtDamageThisAttack) {
          // ไม่ต้องรอให้ถึง 95% ให้เริ่มเช็คหลังจากเริ่มโจมตีสัก 30% ของอนิเมชันขึ้นไป เพื่อให้เกิดความสมจริง
          double hitTimeStart = (e.attackFrames * e.attackStepTime) * 0.3;

          if (e.attackElapsed >= hitTimeStart) {
            // สร้างกล่องโจมตีของศัตรู (ยื่นไปด้านหน้าตามทิศทางที่หันล่าสุด)
            Vector2 forwardDir = moveDir.length > 0.01 ? moveDir : e.attackTargetDir;
            Vector2 enemyAttackCenter = e.position + (forwardDir * 30.0);
            Rect enemyAttackRect = Rect.fromCenter(
              center: Offset(enemyAttackCenter.x, enemyAttackCenter.y),
              width: 45.0,
              height: 45.0,
            );

            // ✅ แสดง Hitbox สีแดงของศัตรูเพื่อทดสอบ (วาดชั่วคราว)
            world.add(DebugHitbox(
              position: enemyAttackCenter,
              size: Vector2(45.0, 45.0),
              lifetime: 0.1,
            ));

            // เช็คว่ากระต่ายยังอยู่ในกล่องไหม และผู้เล่นไม่ติดคูลดาวน์อมตะ
            if (collisionCooldown <= 0 && enemyAttackRect.overlaps(rabbit.toRect())) {
              // โดนตีเต็มๆ! ทำครั้งเดียวในหนึ่งการโจมตี
              e.hasDealtDamageThisAttack = true; 
              enemy = e;
              int damage = 10; 
              damagePlayer(damage);
              rabbit.playHit();
              
              // ✅ ยกเลิกการผลักออกก่อนหลังถูกโจมตี (ไม่มี knockback)
              collisionCooldown = 1.5; // คูลดาวน์อมตะให้ผู้เล่นรอดพ้นจากการโดนรุมตีชั่วคราว
            } 
          }
        }
      }
    }

    if (!inQuestion) {
      if (hasChasingEnemy && !_isEnemyChasingPlayer) {
        _isEnemyChasingPlayer = true;
        AudioManager().playBgm(AudioManager.bgmBattle);
      } else if (!hasChasingEnemy && _isEnemyChasingPlayer) {
        _isEnemyChasingPlayer = false;
        AudioManager().playBgm(AudioManager.bgmOverworld);
      }
    }
  }

  // -------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------

  void onActionPressed() {
    // คุยกับ NPC
    if (activeNpc != null) {
      showDialog(activeNpc!.message);
      joystickDirection.setZero();
    }
    // เข้าประตู
    else if (activePortal != null) {
      Vector2 targetPos = Vector2(100, 100);
      if (activePortal!.targetMap == 'house_interior.tmx') {
        targetPos = Vector2(239, 141);
      } else if (activePortal!.targetMap == 'new.tmx') {
        targetPos = Vector2(650, 530);
      }
      loadLevel(activePortal!.targetMap, targetPos);
      collisionCooldown = 2.0;
    }
    // ✅ เก็บไอเทม
    else if (activeItem != null) {
      // 1. เพิ่มของเข้า GameData
      // สมมติว่า activeItem.name เป็นชื่อสกิลด้วย ถ้าเป็น "Scroll: Fireball"
      // หรือเป็นชื่อไอเทม "Potion"

      String itemName = activeItem!.name;

      AudioManager().playSfx(AudioManager.sfxPickUp); // ✅ SFX เก็บของ

      // ตรวจสอบว่าเป็นสกิลไหม (เช็คจากชื่อ หรือ custom property ก็ได้)
      // ตัวอย่างง่ายๆ: ถ้าชื่อเริ่มด้วย Skill: ให้ปลดล็อคสกิล
      if (itemName.startsWith("Skill:")) {
        String skillId = itemName
            .split(":")[1]
            .trim(); // เช่น "Skill: fireball" -> "fireball"
        // เพิ่มเข้า unlockedSkills (ต้องแก้ GameData ให้มี method นี้ หรือ access list ตรงๆ)
        if (!GameData.unlockedSkills.contains(skillId)) {
          GameData.unlockedSkills.add(skillId);
          showDialog("ได้รับสกิลใหม่: $skillId !");
        } else {
          showDialog("คุณมีสกิลนี้อยู่แล้ว!");
        }
      } else if (itemName.startsWith("Gold")) {
        // Extract random gold
        final regex = RegExp(r'\d+');
        final match = regex.firstMatch(itemName);
        if (match != null) {
          int amount = int.tryParse(match.group(0) ?? '0') ?? 0;
          GameData.playerGold += amount;
          showDialog("ได้รับเงิน: $amount G !");
        } else {
          GameData.inventory.add(itemName);
          showDialog("เก็บได้: $itemName !");
        }
      } else {
        // ไอเทมทั่วไป
        GameData.inventory.add(itemName);
        showDialog("เก็บได้: $itemName !");
      }

      // 2. ลบออกจากฉาก
      activeItem!.removeFromParent();
      activeItem = null;
      overlays.remove('ActionOverlay');
    }
  }

  void activateSkill(String skillId) {
    // ... (Skill Logic เดิม) ...
    switch (skillId) {
      case 'heal':
        int healAmount = (maxHP * 0.3).toInt();
        playerHP = (playerHP + healAmount).clamp(0, maxHP);
        break;
      case 'dash':
        isDashing = true;
        dashTimer = 0.3;
        break;
      case 'ice_blast':
        freezeTimer = 3.0;
        break;
      case 'fireball':
        AudioManager().playSfx(AudioManager.sfxFireAttack); // ✅ SFX ยิงไฟ
        final fireball = Fireball(
          position: rabbit.position.clone(),
          direction:
              joystickDirection.length > 0 ? joystickDirection : lastDirection,
        );
        world.add(fireball);
        break;
    }
  }

  // ✅ ฟังก์ชันเริ่มเกมใหม่
  void resetGame() {
    isGameOver = false;
    inQuestion = false; // ปลดล็อกไม่ให้ค้างในโหมด battle
    isDialogActive = false;
    playerHP = maxHP;
    rabbit.reset(); // รีเซ็ตสถานะแอนิเมชันของกระต่าย

    // ถ้ารอกระต่ายตายเกิน 2 วิ มันจะโดน removeFromParent ไปแล้ว ต้องเอากลับมาใส่ World
    if (rabbit.parent == null) {
      world.add(rabbit);
    }

    // ✅ ย้ายตัวละครกลับไปจุดเริ่มต้น โดยไม่ลบโลก (จะได้ไม่ลบไอเทมที่เพิ่งดรอปทิ้งไว้)
    rabbit.position = Vector2(600, 540);

    // แสดงปุ่ม Skill และกระเป๋ากลับมา
    overlays.remove('GameOverOverlay');
    overlays.add('SkillOverlay');
    overlays.add('BagOverlay');
    overlays.add('QuestOverlay'); // ✅ กลับมาแสดงเควสต์
  }

  // ✅ Cutscene: จบ cutscene แล้วกลับเข้าสู่เกมปกติ
  void endCutsceneMode() {
    isCutsceneMode = false;
    freezeTimer = 0; // ปลดล็อค freeze

    // ✅ เล่น BGM overworld หลังจบ cutscene
    AudioManager().playBgm(AudioManager.bgmOverworld);

    // แสดง UI ปกติ
    overlays.add('SkillOverlay');
    overlays.add('BagOverlay');
    overlays.add('QuestOverlay');
  }

  // -------------------------------------------------------------------
  // Map & Level Loading
  // -------------------------------------------------------------------

  Future<void> loadLevel(String mapName, Vector2 targetSpawnPosition) async {
    if (isLoading) return;
    _isTransitioning = true;
    _transitionAlpha = 1.0;
    isLoading = true;

    activePortal = null;
    activeNpc = null;
    activeItem = null;
    overlays.remove('ActionOverlay');

    try {
      Vector2 tileSize = Vector2(16, 16);
      if (mapName == 'new.tmx') {
        tileSize = Vector2(64, 64);
      }
      final newMap = await TiledComponent.load(mapName, tileSize);
      newMap.priority = 0;

      // ลบของเก่าทั้งหมด
      world.children
          .whereType<TiledComponent>()
          .forEach((m) => m.removeFromParent());
      world.children.whereType<Npc>().forEach((n) => n.removeFromParent());
      world.children.whereType<Portal>().forEach((p) => p.removeFromParent());
      world.children.whereType<Enemy>().forEach((e) => e.removeFromParent());
      world.children.whereType<Obstacle>().forEach((o) => o.removeFromParent());
      world.children
          .whereType<Decoration>()
          .forEach((d) => d.removeFromParent());
      world.children.whereType<Fireball>().forEach((f) => f.removeFromParent());
      world.children
          .whereType<WorldItem>()
          .forEach((i) => i.removeFromParent());

      // ✅ เพิ่ม: ลบ Tree ของเก่าออกด้วย
      world.children.whereType<Tree>().forEach((t) => t.removeFromParent());

      map = newMap;
      world.add(map);

      rabbit.position = targetSpawnPosition;

      // ... (Code ส่วนโหลด GameObjects / Collisions เหมือนเดิม ข้ามไปส่วน Decorations เลย) ...

      final objLayer = map.tileMap.getLayer<ObjectGroup>('GameObjects');
      if (objLayer != null) {
        // ... (วางโค้ดส่วน GameObjects เดิมของคุณที่นี่) ...
        for (final obj in objLayer.objects) {
          final type = obj.type.isNotEmpty ? obj.type : obj.class_;
          switch (type) {
            case 'NPC':
              world.add(Npc(
                position: Vector2(obj.x, obj.y),
                size: Vector2(obj.width, obj.height),
                message:
                    obj.properties.getValue<String>('message') ?? 'สวัสดี!',
              )..priority = 5);
              break;
            case 'Enemy':
              // ✅ อ่านข้อมูล element/ธาตุ จาก Tiled properties
              final enemyElement =
                  obj.properties.getValue<String>('element') ?? 'ignis';
              final enemyName =
                  obj.properties.getValue<String>('enemyName') ?? 'ศัตรู';
              final strongSubj =
                  obj.properties.getValue<String>('strongSubject') ?? 'ฟิสิกส์';
              final weakSubj =
                  obj.properties.getValue<String>('weakSubject') ?? 'เคมี';
              world.add(Enemy(
                position: Vector2(obj.x, obj.y),
                enemyName: enemyName,
                element: enemyElement,
                strongSubject: strongSubj,
                weakSubject: weakSubj,
              )
                ..size = Vector2(obj.width, obj.height)
                ..priority = 5);
              break;
            case 'Portal':
              world.add(Portal(
                position: Vector2(obj.x, obj.y),
                size: Vector2(obj.width, obj.height),
                targetMap: obj.properties.getValue<String>('targetMap') ??
                    'house_interior.tmx',
              )..priority = 5);
              break;
            case 'Item':
              // ✅ ตรวจสอบว่า Item นี้มีรูปภาพ (gid) ใน Tiled หรือไม่
              Sprite? itemSprite;
              if (obj.gid != null) {
                itemSprite = await _getSpriteFromGid(obj.gid!, map);
              }

              world.add(WorldItem(
                position: Vector2(obj.x, obj.y),
                size: Vector2(obj.width, obj.height),
                name: obj.name.isNotEmpty ? obj.name : 'Unknown Item',
                mapSprite: itemSprite, // ✅ ส่งรูปที่ดึงมาจาก Tiled เข้าไป
              )..priority = 5);
              break;
          }
        }
      }

      final destTileSize = map.tileMap.destTileSize;

      // ==========================================
      // METHOD 1: Read Custom Properties (isSolid)
      // ==========================================
      for (final layer in map.tileMap.map.layers) {
        if (layer is TileLayer) {
          final tileData = layer.tileData;
          if (tileData == null) continue;

          for (int y = 0; y < layer.height; y++) {
            for (int x = 0; x < layer.width; x++) {
              final gid = tileData[y][x].tile;

              if (gid != 0) {
                final tile = map.tileMap.map.tileByGid(gid);

                if (tile != null) {
                  final isSolid =
                      tile.properties.getValue<bool>('isSolid') ?? false;

                  if (isSolid) {
                    world.add(Obstacle(
                      position: Vector2(x * destTileSize.x, y * destTileSize.y),
                      size: destTileSize,
                    ));
                  }
                }
              }
            }
          }
        }
      }

      // ==========================================
      // METHOD 2: Read Object Layer ('Collisions')
      // ==========================================
      final colLayer = map.tileMap.getLayer<ObjectGroup>('Collisions');
      if (colLayer != null) {
        for (final obj in colLayer.objects) {
          world.add(Obstacle(
            // Notice we do NOT multiply by destTileSize here.
            // Object layers already use exact pixel coordinates!
            position: Vector2(obj.x, obj.y),
            size: Vector2(obj.width, obj.height),
          ));
        }
      }

      // ✅ จุดแก้ไขหลัก: ตรวจสอบ Type ใน Decorations Layer
      final decoLayer = map.tileMap.getLayer<ObjectGroup>('Decorations');
      if (decoLayer != null) {
        for (final obj in decoLayer.objects) {
          if (obj.gid != null) {
            final sprite = await _getSpriteFromGid(obj.gid!, map);
            if (sprite != null) {
              // ✅ เช็คว่าเป็น Tree หรือไม่ (รองรับทั้ง Type และ Class สำหรับ Tiled เวอร์ชันใหม่/เก่า)
              final type = obj.type.isNotEmpty ? obj.type : obj.class_;

              if (type == 'Tree') {
                // สร้าง Tree Component (แบบมองทะลุได้)
                world.add(Tree(
                  position: Vector2(obj.x, obj.y),
                  size: Vector2(obj.width, obj.height),
                  sprite: sprite,
                ));
              } else {
                // สร้าง Decoration ธรรมดา
                world.add(Decoration(
                  position: Vector2(obj.x, obj.y),
                  size: Vector2(obj.width, obj.height),
                  sprite: sprite,
                ));
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Error loading map: $e");
    } finally {
      // ✅ จบการเปลี่ยนฉาก: ค่อยๆ จางสีดำออก
      await Future.delayed(const Duration(milliseconds: 500));
      _isTransitioning = false;
      isLoading = false;
    }
  }

  // ✅ ฟังชั่นสปอนมอนสเตอร์พร้อมเก็บข้อมูลจุดเกิดเพื่อ Respawn
  void spawnEnemy(Enemy enemy) {
    world.add(enemy);
  }

  void handleEnemyDeath(Enemy enemy) {
    // 1. สปอนของรางวัล (Loot)
    _spawnLoot(enemy.position.clone(), enemy.element);

    // 2. เก็บเข้าคิวเกิดใหม่ (30 วินาที)
    _respawnWaitList.add(_RespawnData(
      position: enemy.position.clone(),
      name: enemy.enemyName,
      element: enemy.element,
      strongSubject: enemy.strongSubject,
      weakSubject: enemy.weakSubject,
      proficiency: Map.from(enemy.proficiency),
      timer: 30.0,
    ));
  }

  void _updateRespawns(double dt) {
    for (int i = _respawnWaitList.length - 1; i >= 0; i--) {
      _respawnWaitList[i].timer -= dt;
      if (_respawnWaitList[i].timer <= 0) {
        final data = _respawnWaitList.removeAt(i);
        spawnEnemy(Enemy(
          position: data.position,
          enemyName: data.name,
          element: data.element,
          strongSubject: data.strongSubject,
          weakSubject: data.weakSubject,
          proficiency: data.proficiency,
        ));
      }
    }
  }

  void _spawnLoot(Vector2 position, String element) {
    final rand = Random().nextDouble();
    // 70% chance spawn gold, 20% potion, 10% rare book
    if (rand < 0.7) {
      int randomGold = 10 + Random().nextInt(41); // 10 to 50
      world.add(WorldItem(
        position: position + Vector2(0, 10),
        size: Vector2(16, 16),
        name: 'Gold ($randomGold)',
      ));
    } else if (rand < 0.9) {
      world.add(WorldItem(
        position: position + Vector2(10, 0),
        size: Vector2(16, 16),
        name: 'HP Potion (S)',
      ));
    } else {
      // Rare case: drop a random subject book
      world.add(WorldItem(
        position: position + Vector2(-10, -10),
        size: Vector2(24, 24),
        name: 'story: จดหมายลับแห่งธาตุ$element',
      ));
    }
  }

  Future<Sprite?> _getSpriteFromGid(int gid, TiledComponent map) async {
    final tileset = map.tileMap.map.tilesets.lastWhere(
      (ts) => ts.firstGid != null && gid >= ts.firstGid!,
      orElse: () => map.tileMap.map.tilesets.first,
    );

    final localId = gid - tileset.firstGid!;

    try {
      if (tileset.image != null) {
        final source = tileset.image!.source;
        if (source == null) return null;

        String cleanPath = source.replaceAll('\\', '/');
        final fileName = cleanPath.contains('images/')
            ? cleanPath.split('images/').last
            : cleanPath.split('/').last;

        final image = await images.load(fileName);
        final tileWidth = tileset.tileWidth ?? 16;
        final tileHeight = tileset.tileHeight ?? 16;
        final columns = tileset.columns ?? 1;
        final spacing = tileset.spacing;
        final margin = tileset.margin;
        final row = localId ~/ columns;
        final col = localId % columns;
        final x = margin + (col * (tileWidth + spacing));
        final y = margin + (row * (tileHeight + spacing));

        return Sprite(
          image,
          srcPosition: Vector2(x.toDouble(), y.toDouble()),
          srcSize: Vector2(tileWidth.toDouble(), tileHeight.toDouble()),
        );
      } else {
        // Support for Image Collection tilesets
        final tileData = tileset.tiles.firstWhere((t) => t.localId == localId);
        if (tileData.image != null) {
          final source = tileData.image?.source;
          if (source != null) {
            String cleanPath = source.replaceAll('\\', '/');
            final fileName = cleanPath.contains('images/')
                ? cleanPath.split('images/').last
                : cleanPath.split('/').last;

            final image = await images.load(fileName);
            return Sprite(image);
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading sprite from gid $gid: $e");
    }
    return null;
  }

  // -------------------------------------------------------------------
  // UI & Input Callbacks
  // -------------------------------------------------------------------

  void setJoystickDirection(double x, double y) {
    joystickDirection.setValues(x, y);
  }

  void showDialog(String message) {
    currentDialogMessage = message;
    isDialogActive = true;

    // ✅ เปลี่ยนท่าทาง NPC เป็นตื่น (Idle)
    if (activeNpc != null) {
      talkingNpc = activeNpc;
      talkingNpc?.setState(NpcState.idle);
    }

    overlays.add('DialogOverlay');
    overlays.remove('SkillOverlay');
    overlays.remove('ActionOverlay');
  }

  void closeDialog() {
    isDialogActive = false;

    // ✅ กลับไปนอน (Sleeping)
    talkingNpc?.setState(NpcState.sleeping);
    talkingNpc = null;

    overlays.remove('DialogOverlay');
    overlays.add('SkillOverlay');
  }

  void onAnswerSelected(bool correct) {
    if (answered) return;
    answered = true;
    overlays.remove('QuestionOverlay');
    overlays.add('SkillOverlay');

    if (correct) {
      if (enemy != null) {
        enemy!.playHit();
        enemy!.die();
      }
      inQuestion = false;
    } else {
      int damage = 20 - GameData.defense;
      if (damage < 5) damage = 5;
      damagePlayer(damage);
      rabbit.playHit();
      if (enemy != null) {
        Vector2 knockbackDir = (rabbit.position - enemy!.position).normalized();
        if (knockbackDir.length == 0) knockbackDir = Vector2(1, 0);
        rabbit.position += knockbackDir * 60;
      }
      collisionCooldown = 2.0;
      inQuestion = false;
    }
  }

  void damagePlayer(int dmg) {
    playerHP = (playerHP - dmg).clamp(0, maxHP);
    AudioManager().playSfx(AudioManager.sfxGetHit); // ✅ SFX โดนตี
  }

  void healPlayer() {
    playerHP = maxHP;
  }

  // ✅ Quiz Battle: callbacks หลังจบ Battle
  void onBattleWon() {
    if (enemy != null) {
      enemy!.hasShield = false; // โล่แตกแล้ว ให้สามารถโดนโจมตีปกติได้
      showDialog("เกราะของ ${enemy!.enemyName} ถูกทำลายแล้ว! โจมตีได้เลย!");

      // ✅ Game Ending Condition: ชนะบอสใหญ่
      if (enemy!.enemyName.toLowerCase().contains('บอส') ||
          enemy!.enemyName.toLowerCase().contains('boss')) {
        overlays.remove('BattleOverlay');
        overlays.add('GameEndingOverlay');
        return; // ไม่ต้องรันโค้ดต่อ
      }
    }
    inQuestion = false;
    _isEnemyChasingPlayer = false;
    collisionCooldown = 2.0;
    unfreezeWorld(); // ✅ คืนเวลา
    isScanActive = false; // ✅ ปิดหน้าจอขาวดำ
    overlays.remove('BattleOverlay');
    overlays.add('SkillOverlay');
    overlays.add('QuestOverlay'); // ✅ กลับมาแสดงเควสต์
    AudioManager().playBgm(AudioManager.bgmOverworld); // ✅ กลับไปเพลง overworld
  }

  void onBattleLost() {
    // โดนตีแตก: knockback + ลด HP
    if (enemy != null) {
      Vector2 knockbackDir = (rabbit.position - enemy!.position).normalized();
      if (knockbackDir.length == 0) knockbackDir = Vector2(1, 0);
      rabbit.position += knockbackDir * 60;
    }
    rabbit.playHit();
    inQuestion = false;
    _isEnemyChasingPlayer = false;
    collisionCooldown = 2.0;
    unfreezeWorld(); // ✅ คืนเวลา
    isScanActive = false; // ✅ ปิดหน้าจอขาวดำ
    overlays.remove('BattleOverlay');
    overlays.add('SkillOverlay');
    overlays.add('QuestOverlay'); // ✅ กลับมาแสดงเควสต์
    AudioManager().playBgm(AudioManager.bgmOverworld); // ✅ กลับไปเพลง overworld
  }

  // ✅ ฟังก์ชันทิ้งของบนพื้น
  void _dropAllItems() {
    // 1. ทิ้งของใน inventory
    for (int i = 0; i < GameData.inventory.length; i++) {
      String itemName = GameData.inventory[i];
      _spawnWorldItem(itemName);
    }
    GameData.inventory.clear();

    // 2. ทิ้งของสวมใส่ด้วย (เกราะ ดาบ ฯลฯ)
    for (int i = 0; i < GameData.equippedItems.length; i++) {
      String itemName = GameData.equippedItems[i];
      _spawnWorldItem(itemName);
    }
    GameData.equippedItems.clear();
  }

  // สร้าง WorldItem ให้ร่วงรอบๆ ตัวละครแบบสุ่ม
  void _spawnWorldItem(String itemName) {
    if (itemName.isEmpty) return;

    // สุ่มตำแหน่งระหว่าง -40 ถึง +40 รอบๆ กระต่าย
    final double randomX = (rand.nextDouble() - 0.5) * 80;
    final double randomY = (rand.nextDouble() - 0.5) * 80;
    final Vector2 dropPos =
        Vector2(rabbit.position.x + randomX, rabbit.position.y + randomY);

    final droppedItem = WorldItem(
      position: dropPos,
      size: Vector2(24, 24),
      name: itemName,
    )..priority = dropPos.y.toInt();

    world.add(droppedItem);
  }

  @override
  void onRemove() {
    SaveManager.savePlayerPosition(rabbit.position.x, rabbit.position.y);
    AudioManager().stopWalkStep();
    super.onRemove();
  }

  // -------------------------------------------------------------------
  // ✅ Camera Zoom (สำหรับ "The World" effect)
  // -------------------------------------------------------------------
  double _defaultZoom = 1.8;
  double _targetZoom = 1.8;
  bool _isZooming = false;
  double _zoomSpeed = 2.0;

  void zoomCamera(double targetZoom, {double speed = 2.0}) {
    _targetZoom = targetZoom;
    _zoomSpeed = speed;
    _isZooming = true;
  }

  void resetCameraZoom({double speed = 2.0}) {
    _targetZoom = _defaultZoom;
    _zoomSpeed = speed;
    _isZooming = true;
  }

  void _updateCameraZoom(double dt) {
    if (!_isZooming) return;
    final currentZoom = cameraComponent.viewfinder.zoom;
    final diff = _targetZoom - currentZoom;
    if (diff.abs() < 0.01) {
      cameraComponent.viewfinder.zoom = _targetZoom;
      _isZooming = false;
    } else {
      cameraComponent.viewfinder.zoom += diff * _zoomSpeed * dt;
    }
  }

  // -------------------------------------------------------------------
  // ✅ World Freeze — "The World" (หยุดเวลาทั้งโลก)
  // -------------------------------------------------------------------
  void freezeWorld() {
    isWorldFrozen = true;
    // หยุดมอนสเตอร์ทั้งหมด
    for (final e in world.children.whereType<Enemy>()) {
      e.velocity = Vector2.zero();
    }
  }

  void unfreezeWorld() {
    isWorldFrozen = false;
  }

  // -------------------------------------------------------------------
  // ✅ Overworld Attack — โจมตีศัตรูรอบตัวในโลก real-time
  // -------------------------------------------------------------------
  void attackNearbyEnemy() {
    final bool isRunning = joystickDirection.length > 0.01;
    rabbit.playAttack(isRunning: isRunning);

    if (isRunning) {
      double dashSpeed = (100.0 + (GameData.agility * 1.5)) * 1.2; // พุ่งตีด้วยสปีด x1.2
      _dashAttackVelocity = lastDirection * dashSpeed;
    } else {
      _dashAttackVelocity = Vector2.zero();
    }

    // เคลียร์ศัตรูที่เคยโดนดาเมจในการโจมตีครั้งก่อน เพื่อให้เริ่มนับคอมโบใหม่และตีโดนจากการขยับ
    hitEnemiesThisAttack.clear();
  }

  // -------------------------------------------------------------------
  // ✅ Scan World — "The World" (สแกนทำลายเกราะศัตรู)
  // -------------------------------------------------------------------
  void scanWorld() {
    // 1. หาศัตรูที่ใกล้ที่สุดที่มีเกราะ
    Enemy? targetEnemy;
    double minDistance = 150.0; // ระยะมองของสแกน 150px
    for (final e in world.children.whereType<Enemy>()) {
      if (e.alive && e.hasShield) {
        final double dist = rabbit.position.distanceTo(e.position);
        if (dist < minDistance) {
          minDistance = dist;
          targetEnemy = e;
        }
      }
    }

    if (targetEnemy != null) {
      freezeWorld();
      // 2. ถ้าเจอ ให้เข้าสู่โหมดตอบคำถาม
      enemy = targetEnemy;
      inQuestion = true;
      answered = false;
      joystickDirection.setZero();
      _walkStepTimer = 0.0;
      AudioManager().playBgm(AudioManager.bgmBattle);
      overlays.remove('BattleOverlay');
      overlays.add('BattleOverlay');
      overlays.remove('SkillOverlay');
      overlays.remove('QuestOverlay');
      if (activePortal != null || activeNpc != null || activeItem != null) {
        overlays.remove('ActionOverlay');
      }

      // Visual Effects (แค่เล่นเสียงและแว๊บนึง ไม่ค้าง freeze)
      isScanActive = true;
      AudioManager().playSfx(AudioManager.sfxTimeStop);
    } else {
      // 3. ถ้าไม่เจอศัตรู โชว์ข้อความ
      showDialog("ไม่พบศัตรูที่ต้องสแกนในบริเวณใกล้เคียง");
    }
  }

  void endScanWorld() {
    isScanActive = false;
    // Note: ถ้ากำลังสู้ BattleOverlay อยู่ ก็ปล่อยไป หรือถ้าสแกนไม่เจอ ใครทำก็ปลดออก
  }
}

// =====================================================================
// 3. HELPER CLASSES
// =====================================================================

enum NpcState { sleeping, idle }

class Npc extends SpriteAnimationGroupComponent<NpcState>
    with HasGameRef<RabbitGame> {
  final String message;
  Npc(
      {required Vector2 position,
      required Vector2 size,
      required this.message}) {
    this.position = position;
    this.size = size;
    anchor = Anchor.center; // ✅ ใช้ Anchor center เพื่อให้หมุน/ขยับง่าย
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 💤 ท่าทางตอนนอน (192x32, 6 Frames)
    final sleepImage = await gameRef.images.load('npc_sleep.png');
    final sleepAnim = SpriteAnimation.fromFrameData(
      sleepImage,
      SpriteAnimationData.sequenced(
        amount: 6,
        stepTime: 0.3,
        textureSize: Vector2(32, 32),
      ),
    );

    // 👀 ท่าทางตอนคุย (160x32, 5 Frames)
    final idleImage = await gameRef.images.load('npc_idle.png');
    final idleAnim = SpriteAnimation.fromFrameData(
      idleImage,
      SpriteAnimationData.sequenced(
        amount: 5,
        stepTime: 0.2,
        textureSize: Vector2(32, 32),
      ),
    );

    animations = {
      NpcState.sleeping: sleepAnim,
      NpcState.idle: idleAnim,
    };

    current = NpcState.sleeping;
  }

  void setState(NpcState state) {
    current = state;
  }
}

class Portal extends PositionComponent {
  final String targetMap;
  Portal(
      {required Vector2 position,
      required Vector2 size,
      required this.targetMap}) {
    this.position = position;
    this.size = size;
  }
  @override
  void render(Canvas canvas) {
    canvas.drawRect(
        size.toRect(), Paint()..color = Colors.purpleAccent.withOpacity(0.3));
  }
}

class Obstacle extends PositionComponent {
  Obstacle({required Vector2 position, required Vector2 size}) {
    this.position = position;
    this.size = size;
  }
}

class Decoration extends SpriteComponent {
  Decoration(
      {required Vector2 position,
      required Vector2 size,
      required Sprite sprite})
      : super(
          sprite: sprite,
          position: position,
          size: size,
          anchor: Anchor.bottomLeft,
        );
}

// ✅ Class สำหรับไอเทมในฉาก
class WorldItem extends SpriteAnimationComponent with HasGameRef<RabbitGame> {
  final String name;
  final Sprite? mapSprite; // ✅ เพิ่มตัวแปรสำหรับรับ Sprite จาก Tiled

  WorldItem({
    required Vector2 position,
    required Vector2 size,
    required this.name,
    this.mapSprite, // ✅ รับค่า mapSprite
  }) {
    this.position = position;
    this.size = size;
    anchor = Anchor.bottomLeft;
  }

  @override
  Future<void> onLoad() async {
    // ✅ 1) ถ้ามี sprite จาก Tiled ให้ใช้เป็นแอนิเมชันเฟรมเดียว
    if (mapSprite != null) {
      animation = SpriteAnimation.spriteList([mapSprite!], stepTime: 1.0);
      await super.onLoad();
      return;
    }

    // ✅ 2) Coin drop: sprite sheet 16x16, 15 frames
    if (name.toLowerCase().contains('gold') || name.contains('เหรียญ')) {
      final coinImage = await gameRef.images.load('coin1_16x16.png');
      size = Vector2(16, 16);
      animation = SpriteAnimation.fromFrameData(
        coinImage,
        SpriteAnimationData.sequenced(
          amount: 15,
          stepTime: 0.08,
          textureSize: Vector2(16, 16),
        ),
      );
      await super.onLoad();
      return;
    }

    // ✅ 3) อื่น ๆ ใช้ภาพเดี่ยว (แอนิเมชัน 1 เฟรม)
    String spriteFile = 'arrow.png';
    if (name.contains('story') || name.contains('เรื่องเล่า')) {
      spriteFile = 'book_story.png';
      size = Vector2(32, 32);
    } else if (name.contains('question') || name.contains('คำถาม')) {
      spriteFile = 'book_questions.png';
      size = Vector2(32, 32);
    } else if (name.toLowerCase().contains('potion') || name.contains('ยา')) {
      size = Vector2(24, 24);
      for (final file in const <String>['hp.png', 'h.png', 'potion.png']) {
        try {
          final s = await gameRef.loadSprite(file);
          animation = SpriteAnimation.spriteList([s], stepTime: 1.0);
          await super.onLoad();
          return;
        } catch (_) {
          // try next
        }
      }
    }

    final fallbackSprite = await gameRef.loadSprite(spriteFile);
    animation = SpriteAnimation.spriteList([fallbackSprite], stepTime: 1.0);
    await super.onLoad();
  }
}

class Fireball extends SpriteAnimationComponent
    with HasGameRef<RabbitGame>, CollisionCallbacks {
  final Vector2 direction;
  final double speed = 300;
  final double lifetime = 1.5;
  double elapsed = 0;

  Fireball({required Vector2 position, required this.direction})
      : super(position: position, size: Vector2(24, 24), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox(isSolid: true));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(
        Offset(size.x / 2, size.y / 2), 8, Paint()..color = Colors.orange);
    canvas.drawCircle(
        Offset(size.x / 2, size.y / 2), 5, Paint()..color = Colors.yellow);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += direction * speed * dt;
    elapsed += dt;
    if (elapsed > lifetime) removeFromParent();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Enemy) {
      other.playHit();
      other.die();
      removeFromParent();
    } else if (other is Obstacle) {
      removeFromParent();
    }
  }
}

// ✅ Class สำหรับเก็บข้อมูลสำหรับเรียกมอนสเตอร์กลับมาเกิดใหม่
class _RespawnData {
  final Vector2 position;
  final String name;
  final String element;
  final String strongSubject;
  final String weakSubject;
  final Map<String, double> proficiency;
  double timer;

  _RespawnData({
    required this.position,
    required this.name,
    required this.element,
    required this.strongSubject,
    required this.weakSubject,
    required this.proficiency,
    required this.timer,
  });
}

// ✅ กล่องสีแดงสำหรับเช็คระยะ Hitbox
class DebugHitbox extends PositionComponent {
  final double lifetime;
  double elapsed = 0.0;

  DebugHitbox({
    required Vector2 position,
    required Vector2 size,
    this.lifetime = 0.3,
  }) : super(position: position, size: size, anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(
      size.toRect(),
      Paint()
        ..color = Colors.red.withOpacity(0.5)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt;
    if (elapsed >= lifetime) {
      removeFromParent();
    }
  }
}

