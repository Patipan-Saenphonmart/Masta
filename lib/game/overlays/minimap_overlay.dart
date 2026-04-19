import 'dart:math';
import 'package:flutter/material.dart' hide Decoration;
import '../main_game.dart';
import '../../data/game_data.dart';
import '../components/enemy.dart';
import '../components/tree.dart';
import '../components/npc.dart';
import '../components/portal.dart';
import '../components/obstacle.dart';
import '../components/decoration.dart';

class MiniMapOverlay extends StatelessWidget {
  final RabbitGame game;
  const MiniMapOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C), // ขอบเขตด้านนอก
          border: Border.all(color: Colors.amber, width: 4),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // ตัวแปรวาดแผนที่
              Positioned.fill(
                child: CustomPaint(
                  painter: _MiniMapPainter(game: game),
                ),
              ),
              // ปุ่มปิด
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () {
                    game.overlays.remove('MiniMapOverlay');
                  },
                ),
              ),
              // ชื่อแผนที่
              const Positioned(
                top: 16,
                left: 16,
                child: Text(
                  'แผนที่โลก (World Map)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
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

class _MiniMapPainter extends CustomPainter {
  final RabbitGame game;
  const _MiniMapPainter({required this.game});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. อ่านขนาดแผนที่จริง
    double mapNativeWidth = 0.0;
    double mapNativeHeight = 0.0;

    try {
      mapNativeWidth = game.map.tileMap.map.width *
          game.map.tileMap.map.tileWidth.toDouble();
      mapNativeHeight = game.map.tileMap.map.height *
          game.map.tileMap.map.tileHeight.toDouble();
    } catch (_) {}

    // กันเหนียวกรณีแผนที่ยังโหลดไม่เสร็จ
    if (mapNativeWidth <= 0) mapNativeWidth = 3000.0;
    if (mapNativeHeight <= 0) mapNativeHeight = 3000.0;

    // คำนวณ Scale ว่าจะย่อแผนที่ให้พอดีจอได้เท่าไหร่
    final double scaleX = size.width / mapNativeWidth;
    final double scaleY = size.height / mapNativeHeight;
    // เลือก scale น้อยสุดเพื่อไม่ให้บิดเบี้ยว (คงอัตราส่วน)
    final double scale = min(scaleX, scaleY);

    // เลื่อนตำแหน่งแผนที่ให้อยู่ตรงกลางจอ (กรณีที่อัตราส่วนไม่พอดีเป๊ะ)
    final double offsetX = (size.width - (mapNativeWidth * scale)) / 2;
    final double offsetY = (size.height - (mapNativeHeight * scale)) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale, scale);

    // ==========================================
    // 2. วาดพื้นหลัง (สมมติว่าเป็นสีเขียวหญ้า)
    // ==========================================
    final Rect mapRect = Rect.fromLTWH(0, 0, mapNativeWidth, mapNativeHeight);
    canvas.drawRect(mapRect, Paint()..color = const Color(0xFF4CAF50));

    // ==========================================
    // 3. วาดวัตถุต่างๆ บนแผนที่
    // ==========================================

    // อุปสรรค (สีเทา)
    final obstaclePaint = Paint()..color = Colors.grey.shade700;
    for (final obj in game.world.children.whereType<Obstacle>()) {
      canvas.drawRect(obj.toRect(), obstaclePaint);
    }

    // ต้นไม้/ของตกแต่ง (สีเขียวเข้ม)
    final decoPaint = Paint()..color = const Color(0xFF2E7D32);
    for (final deco in game.world.children.whereType<MyDecoration>()) {
      canvas.drawRect(deco.toRect(), decoPaint);
    }
    for (final tree in game.world.children.whereType<Tree>()) {
      canvas.drawRect(tree.toRect(), decoPaint);
    }

    // น้ำ (สมมติว่ามีอุปสรรคและอยากทำให้อุปสรรคบางอันคล้ายแหล่งน้ำ)
    // แต่ของเราทั้งหมดคือ Obstacle ธรรมดา เราจะปล่อยไปก่อน

    // จุดวาร์ป (สีม่วงคริสตัล)
    final portalPaint = Paint()..color = Colors.purpleAccent;
    for (final p in game.world.children.whereType<Portal>()) {
      canvas.drawCircle(Offset(p.position.x, p.position.y), 30, portalPaint);
    }

    // NPC (สีฟ้า)
    final npcPaint = Paint()..color = Colors.blue;
    for (final npc in game.world.children.whereType<Npc>()) {
      canvas.drawCircle(Offset(npc.position.x, npc.position.y), 20, npcPaint);
    }

    // มอนสเตอร์ (สีแดง)
    final enemyPaint = Paint()..color = Colors.red;
    for (final e in game.world.children.whereType<Enemy>()) {
      canvas.drawCircle(Offset(e.position.x, e.position.y), 20, enemyPaint);
    }

    // ==========================================
    // 4. ระบบ Fog of War (พื้นที่ปริศนา สีดำ)
    // ==========================================
    const double chunkSize = 150.0;
    int chunksX = (mapNativeWidth / chunkSize).ceil();
    int chunksY = (mapNativeHeight / chunkSize).ceil();

    final fogPaint = Paint()..color = const Color(0xFF1E1E1E);

    for (int cx = 0; cx < chunksX; cx++) {
      for (int cy = 0; cy < chunksY; cy++) {
        String key = "$cx,$cy";
        // ถ้าเพลเยอร์ยังไม่เคยเดินผ่านให้วาดสีดำทับ
        if (!GameData.exploredChunks.contains(key)) {
          canvas.drawRect(
              Rect.fromLTWH(
                  cx * chunkSize, cy * chunkSize, chunkSize, chunkSize),
              fogPaint);
        }
      }
    }

    // ==========================================
    // 5. วาดตำแหน่งผู้เล่น (กระต่าย - สีทอง / หรือไอคอนลูกศร)
    // ==========================================
    final playerPos = game.rabbit.position;
    final playerPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;

    // ขอบขาวให้สังเกตง่าย
    final playerBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    canvas.drawCircle(Offset(playerPos.x, playerPos.y), 25, playerPaint);
    canvas.drawCircle(Offset(playerPos.x, playerPos.y), 25, playerBorderPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MiniMapPainter oldDelegate) {
    // ต้องอัปเดตตลอดเวลาเพราะกระต่ายเดินเรื่อยๆ
    return true;
  }
}
