import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/main_game.dart';
import '../game/overlays/question_overlay.dart';
import '../game/overlays/skill_overlay.dart';
import '../game/overlays/battle_overlay.dart';
import '../game/overlays/game_over_overlay.dart';
import '../game/overlays/quest_overlay.dart';
import '../game/overlays/inventory_overlay.dart';
import '../game/overlays/cutscene_overlay.dart';
import '../game/overlays/minimap_overlay.dart';
import '../game/overlays/game_ending_overlay.dart';
import '../game/components/enemy.dart';
import '../utils/save_manager.dart';
import '../data/game_data.dart';
import '../page/home_page.dart';
import '../utils/audio_manager.dart';
import '../game/components/cutscene_script/openning_script.dart';
import '../page/shop_page.dart';

class MainGamePage extends StatelessWidget {
  final bool showIntroCutscene; // ✅ เพิ่ม parameter สำหรับ cutscene
  const MainGamePage({super.key, this.showIntroCutscene = false});

  @override
  Widget build(BuildContext context) {
    final game = RabbitGame()
      ..isCutsceneMode = showIntroCutscene // ✅ set cutscene mode flag
      ..currentScript = showIntroCutscene ? getOpeningScript() : null // ✅ โหลดสคริปต์เปิดเกม
      ..onOpenShop = () {
        if (context.mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (ctx) => const ShopPage()));
        }
      };

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
                  color: bgColor.withValues(alpha: 0.95),
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
      color: Colors.black.withValues(alpha: 0.6),
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
