import 'package:flutter/material.dart';
import '../rabbit_game.dart';
import '../../game_data.dart'; // ✅ เชื่อม GameData

class SkillOverlay extends StatefulWidget {
  final RabbitGame game;
  const SkillOverlay({super.key, required this.game});

  @override
  State<SkillOverlay> createState() => _SkillOverlayState();
}

class _SkillOverlayState extends State<SkillOverlay> {
  Offset? startDrag;
  Offset knobOffset = Offset.zero;
  final double padSize = 140; 
  final double knobSize = 60;

  // Joystick Logic
  void onPanStart(DragStartDetails d) {
    startDrag = d.localPosition;
  }

  void onPanUpdate(DragUpdateDetails d) {
    startDrag ??= d.localPosition;
    Offset delta = d.localPosition - startDrag!;
    final maxRadius = (padSize - knobSize) / 2;

    if (delta.distance > maxRadius) {
      delta = Offset.fromDirection(delta.direction, maxRadius);
    }

    setState(() {
      knobOffset = delta;
    });

    final vx = (knobOffset.dx / maxRadius).clamp(-1.0, 1.0);
    final vy = (knobOffset.dy / maxRadius).clamp(-1.0, 1.0);
    
    // ✅ แก้ไข: เรียกใช้ joystickDirection โดยตรงแทนการใช้ setJoystickDirection
    widget.game.joystickDirection.setValues(vx, vy);
  }

  void onPanEnd(DragEndDetails d) {
    setState(() {
      knobOffset = Offset.zero;
    });
    startDrag = null;
    
    // ✅ แก้ไข: รีเซ็ตค่า joystickDirection โดยตรง
    widget.game.joystickDirection.setZero();
  }

  // ✅ สร้างปุ่มสกิล
  Widget _buildSkillButton(String skillId, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: GestureDetector(
        onTap: () {
          widget.game.activateSkill(skillId);
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFF5D4037);
    const hpColor = Color(0xFFE53935);

    return Stack(
      children: [
        // --- HP Bar ---
        Positioned(
          left: 16,
          top: 16,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF3E2723),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: hpColor, size: 28),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ โชว์ HP จริง
                    Text(
                      "HP ${widget.game.playerHP}/${widget.game.maxHP}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 150,
                      height: 16,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CustomPaint(
                              size: Size(150, 16),
                              painter: _HpBarPainter(
                                widget.game.playerHP, 
                                widget.game.maxHP,
                                hpColor
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // --- Joystick ---
        Positioned(
          left: 24,
          bottom: 24,
          child: GestureDetector(
            onPanStart: onPanStart,
            onPanUpdate: onPanUpdate,
            onPanEnd: onPanEnd,
            child: SizedBox(
              width: padSize,
              height: padSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: padSize,
                    height: padSize,
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 4),
                    ),
                  ),
                  Transform.translate(
                    offset: knobOffset,
                    child: Container(
                      width: knobSize,
                      height: knobSize,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB74D),
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 4),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 0, offset: Offset(0, 6))
                        ],
                        gradient: const RadialGradient(
                          colors: [Colors.white, Color(0xFFFFB74D)],
                          center: Alignment(-0.4, -0.4),
                          radius: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // --- Skill Buttons (ขวาล่าง) ---
        Positioned(
          right: 24,
          bottom: 40,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ เช็คจาก GameData.equippedSkills เพื่อแสดงเฉพาะสกิลที่ติดตั้ง
              if (GameData.isSkillEquipped('fireball')) 
                _buildSkillButton('fireball', Icons.whatshot, Colors.orange),
              
              if (GameData.isSkillEquipped('heal')) 
                _buildSkillButton('heal', Icons.favorite, Colors.pinkAccent),
              
              if (GameData.isSkillEquipped('dash')) 
                _buildSkillButton('dash', Icons.run_circle, Colors.blueAccent),
                
              if (GameData.isSkillEquipped('ice_blast')) 
                _buildSkillButton('ice_blast', Icons.ac_unit, Colors.cyan),
            ],
          ),
        ),
      ],
    );
  }
}

class _HpBarPainter extends CustomPainter {
  final int currentHP;
  final int maxHP;
  final Color color;

  _HpBarPainter(this.currentHP, this.maxHP, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final hpPercent = (currentHP / maxHP).clamp(0.0, 1.0);
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final fillWidth = size.width * hpPercent;
    final rect = Rect.fromLTWH(0, 0, fillWidth, size.height);
    canvas.drawRect(rect, paint);

    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(Rect.fromLTWH(0, 0, fillWidth, size.height * 0.4), highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}