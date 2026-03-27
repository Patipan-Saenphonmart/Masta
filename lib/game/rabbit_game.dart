import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flame_tiled/flame_tiled.dart' hide Text;
import 'package:flame/collisions.dart';

import '../game_data.dart';
import 'components/rabbit.dart';
import 'components/enemy.dart';
import 'components/tree.dart';
import 'utils/astar.dart';
import 'overlays/question_overlay.dart';
import 'overlays/skill_overlay.dart';
import 'overlays/battle_overlay.dart';
import 'overlays/game_over_overlay.dart';
import 'overlays/quest_overlay.dart'; // ✅ Import QuestOverlay
import 'overlays/inventory_overlay.dart'; // ✅ Import InventoryOverlay
import '../utils/save_manager.dart'; // ✅ Import SaveManager
import '../title_screen.dart'; // ✅ Import TitleScreen

// =====================================================================
// 1. WIDGET: Game Page & UI Overlays
// =====================================================================

class RabbitGamePage extends StatelessWidget {
  const RabbitGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final game = RabbitGame();

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
        },
        initialActiveOverlays: const [
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

              // 💾 บันทึกเกม
              _optionButton(
                  icon: Icons.save_alt_rounded,
                  label: "บันทึกเกม (Save Game)",
                  color: const Color(0xFF4CAF50),
                  onTap: () async {
                    await SaveManager.saveGame();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('บันทึกข้อมูลเรียบร้อยแล้ว! 💾',
                              style: TextStyle(fontWeight: FontWeight.bold))));
                      game.overlays.remove('OptionMenuOverlay');
                    }
                  }),
              const SizedBox(height: 12),

              // 🎵 ปิด/เปิดเสียง
              _optionButton(
                  icon: Icons.music_note_rounded,
                  label: "เปิด/ปิด ระบบเสียง",
                  color: const Color(0xFF1976D2),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('ระบบเสียงจะมาในการอัปเดตถัดไป! 🎧',
                            style: TextStyle(fontWeight: FontWeight.bold))));
                  }),
              const SizedBox(height: 12),

              // 🚪 ออกจากเกมกลับเมนูหลัก
              _optionButton(
                  icon: Icons.door_back_door_rounded,
                  label: "กลับหน้าหลัก (Quit)",
                  color: const Color(0xFFD32F2F),
                  onTap: () async {
                    await SaveManager.saveGame(); // Auto-save ก่อนออก
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const TitleScreen(),
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

  // --- Interaction State ---
  String currentDialogMessage = "";
  bool isDialogActive = false;
  @override
  bool isLoading = false;
  double collisionCooldown = 0.0;

  // ✅ เพิ่มตัวแปรเก็บสิ่งที่กำลังเจอ
  Portal? activePortal;
  Npc? activeNpc;
  WorldItem? activeItem; // ✅ เก็บ Item ที่ยืนทับอยู่

  // --- Skill States ---
  bool isDashing = false;
  double dashTimer = 0.0;
  double freezeTimer = 0.0;

  // --- Input ---
  final Random rand = Random();
  Vector2 joystickDirection = Vector2.zero();
  Vector2 lastDirection = Vector2(1, 0);

  // -------------------------------------------------------------------
  // Lifecycle Methods
  // -------------------------------------------------------------------

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    playerHP = maxHP;

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
      ..size = Vector2(50, 50)
      ..position = Vector2(100, 100);
    world.add(rabbit);
    cameraComponent.follow(rabbit);

    await loadLevel('new.tmx', Vector2(600, 540));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isLoading) return;

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

    if (isDashing) {
      dashTimer -= dt;
      if (dashTimer <= 0) isDashing = false;
    }

    if (freezeTimer > 0) {
      freezeTimer -= dt;
    }

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
  }

  // -------------------------------------------------------------------
  // Update Logic Helpers
  // -------------------------------------------------------------------

  void _updatePlayer(double dt) {
    if (rabbit.isHitPlaying) return;

    if (joystickDirection.length > 0.01) {
      rabbit.setState(RabbitState.run);
      rabbit.faceDirection(joystickDirection.x);

      lastDirection = joystickDirection.normalized();

      double currentSpeed = 100.0 + (GameData.agility * 1.5);
      if (isDashing) currentSpeed *= 2.5;

      final velocity = joystickDirection.normalized() * currentSpeed * dt;
      // ✅ ใช้อิงจากขนาดและตำแหน่ง Hitbox ใหม่ (เฉพาะเท้า)
      // ตัวละคร 50x50, Center=25x25, Hitbox อยู่วายจากด้านบน 36 มีความสูง 14
      // แปลว่าจุดศูนย์กลางเท้าจะอยู่ขยับลงมาจากกึ่งกลางตัวประมาณ 18 พิกเซล
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
    } else {
      rabbit.setState(RabbitState.idle);
    }
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
    for (final e in world.children.whereType<Enemy>()) {
      if (e.isMounted && e.alive) {
        if (freezeTimer > 0) continue;

        final distance = rabbit.position.distanceTo(e.position);
        Vector2 moveDir = Vector2.zero();

        e.pathRecalculateTimer -= dt;

        if (distance < enemyChaseRange) {
          // รีแคลคิวเลท Path ทุกๆ 0.5 วินาทีเพื่อไม่ให้หน่วงเครื่อง
          if (e.pathRecalculateTimer <= 0) {
            e.currentPath = findPathToPlayer(e.position);
            e.pathRecalculateTimer = 0.5;
          }

          if (e.currentPath.isNotEmpty) {
            // เล็งเป้าที่ waypoint ปัจจุบัน
            final waypoint = e.currentPath.first;
            if (e.position.distanceTo(waypoint) < 5.0) {
              assert(() {
                debugPrint('Enemy Reached Waypoint');
                return true;
              }());
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

          if (moveDir.length > 0.01) {
            e.setState(EnemyState.run);
          } else {
            e.setState(EnemyState.idle);
          }
        } else {
          e.setState(EnemyState.idle);
          e.currentPath.clear();
        }

        e.faceDirection(moveDir.x);

        // --- Enemy Sliding Collision (เช็คกำแพงเฉพาะเท้าแบบ 2D Top-Down) ---
        final double enemyHitW = 20.0;
        final double enemyHitH = 10.0;
        final double enemyOffsetY = 10.0; // ขยับจุดเช็คชนลงมาที่เท้า

        final double moveX = moveDir.x * enemySpeed * dt;
        final double moveY = moveDir.y * enemySpeed * dt;

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

        if (collisionCooldown <= 0 && rabbit.toRect().overlaps(e.toRect())) {
          enemy = e;
          inQuestion = true;
          answered = false;
          joystickDirection.setZero();
          // ✅ ใช้ BattleOverlay แทน QuestionOverlay
          overlays.remove(
              'BattleOverlay'); // remove ก่อนเพื่อ rebuild ด้วย enemy ใหม่
          overlays.add('BattleOverlay');
          overlays.remove('SkillOverlay');
          overlays.remove('QuestOverlay'); // ✅ ซ่อนเควสต์ตอนต่อสู้
          if (activePortal != null || activeNpc != null || activeItem != null)
            overlays.remove('ActionOverlay');
        }
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
        targetPos = Vector2(480, 270);
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

  // -------------------------------------------------------------------
  // Map & Level Loading
  // -------------------------------------------------------------------

  Future<void> loadLevel(String mapName, Vector2 targetSpawnPosition) async {
    if (isLoading) return;
    isLoading = true;

    activePortal = null;
    activeNpc = null;
    activeItem = null;
    overlays.remove('ActionOverlay');

    try {
      debugPrint("🔄 Loading map: $mapName");
      final newMap = await TiledComponent.load(mapName, Vector2(16, 16));
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
              world.add(WorldItem(
                position: Vector2(obj.x, obj.y),
                size: Vector2(obj.width, obj.height),
                name: obj.name.isNotEmpty ? obj.name : 'Unknown Item',
              )..priority = 5);
              break;
          }
        }
      }

      final colLayer = map.tileMap.getLayer<ObjectGroup>('Collisions');
      if (colLayer != null) {
        for (final obj in colLayer.objects) {
          world.add(Obstacle(
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
      isLoading = false;
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
        final spacing = tileset.spacing ?? 0;
        final margin = tileset.margin ?? 0;
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
  // ส่วนที่ 2: แก้ไข Update เพื่อให้ลำดับ Layer ของต้นไม้ทำงานถูกต้อง
  // -------------------------------------------------------------------
  // @override
  // void update(double dt) {
  //   super.update(dt);

  //   if (isLoading) return;
  //   if (collisionCooldown > 0) collisionCooldown -= dt;
  //   if (isDashing) {
  //     dashTimer -= dt;
  //     if (dashTimer <= 0) isDashing = false;
  //   }
  //   if (freezeTimer > 0) freezeTimer -= dt;

  //   // ✅ เพิ่มเงื่อนไขเช็ค Tree เข้าไปในลูปจัดลำดับความลึก (Z-Index)
  //   world.children.whereType<PositionComponent>().forEach((component) {
  //     if (component is Rabbit ||
  //         component is Enemy ||
  //         component is Npc ||
  //         component is Decoration ||
  //         component is WorldItem ||
  //         component is Tree) { // <--- เพิ่ม Tree ตรงนี้!

  //       double bottomY = component.position.y;
  //       if (component.anchor == Anchor.center) {
  //         bottomY += component.size.y / 2;
  //       }
  //       component.priority = bottomY.toInt();
  //     }
  //   });

  //   if (!inQuestion && !isDialogActive) {
  //     _updatePlayer(dt);
  //     _checkInteractions();
  //     _updateEnemies(dt);
  //   }
  // }

  // -------------------------------------------------------------------
  // UI & Input Callbacks
  // -------------------------------------------------------------------

  void setJoystickDirection(double x, double y) {
    joystickDirection.setValues(x, y);
  }

  void showDialog(String message) {
    currentDialogMessage = message;
    isDialogActive = true;
    overlays.add('DialogOverlay');
    overlays.remove('SkillOverlay');
    overlays.remove('ActionOverlay');
  }

  void closeDialog() {
    isDialogActive = false;
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
  }

  void healPlayer() {
    playerHP = maxHP;
  }

  // ✅ Quiz Battle: callbacks หลังจบ Battle
  void onBattleWon() {
    if (enemy != null) {
      enemy!.die();
    }
    inQuestion = false;
    collisionCooldown = 2.0;
    overlays.remove('BattleOverlay');
    overlays.add('SkillOverlay');
    overlays.add('QuestOverlay'); // ✅ กลับมาแสดงเควสต์
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
    collisionCooldown = 2.0;
    overlays.remove('BattleOverlay');
    overlays.add('SkillOverlay');
    overlays.add('QuestOverlay'); // ✅ กลับมาแสดงเควสต์
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
}

// =====================================================================
// 3. HELPER CLASSES
// =====================================================================

class HpBar extends PositionComponent {
  final RabbitGame game;
  HpBar(this.game);
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    const width = 100.0;
    const height = 10.0;
    final hpPercent = (game.playerHP / game.maxHP).clamp(0.0, 1.0);
    final bg = Paint()..color = Colors.red.withOpacity(0.3);
    final fg = Paint()..color = Colors.green;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bg);
    canvas.drawRect(Rect.fromLTWH(0, 0, width * hpPercent, height), fg);
  }
}

class Npc extends PositionComponent with HasGameRef<RabbitGame> {
  final String message;
  Npc(
      {required Vector2 position,
      required Vector2 size,
      required this.message}) {
    this.position = position;
    this.size = size;
  }
  @override
  void render(Canvas canvas) {
    canvas.drawRect(
        size.toRect(), Paint()..color = Colors.blueAccent.withOpacity(0.3));
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
class WorldItem extends PositionComponent {
  final String name;
  WorldItem(
      {required Vector2 position, required Vector2 size, required this.name}) {
    this.position = position;
    this.size = size;
  }

  @override
  void render(Canvas canvas) {
    // วาดกล่องสีเขียวแทนไอเทม (ถ้ามีรูป ให้เปลี่ยนเป็น SpriteComponent)
    canvas.drawRect(
        size.toRect(), Paint()..color = Colors.greenAccent.withOpacity(0.7));
    // วาดขอบ
    canvas.drawRect(
        size.toRect(),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
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
