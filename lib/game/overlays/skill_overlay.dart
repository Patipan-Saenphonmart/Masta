import 'package:flutter/material.dart';
import '../main_game.dart';
import '../../data/game_data.dart';

class SkillOverlay extends StatefulWidget {
  final RabbitGame game;
  const SkillOverlay({super.key, required this.game});

  @override
  State<SkillOverlay> createState() => _SkillOverlayState();
}

class _SkillOverlayState extends State<SkillOverlay>
    with SingleTickerProviderStateMixin {
  Offset? startDrag;
  Offset knobOffset = Offset.zero;
  final double padSize = 140;
  final double knobSize = 60;

  // ✅ Cooldown tracking
  final Map<String, double> _cooldowns = {};
  final Map<String, double> _maxCooldowns = {
    'fireball': 3.0,
    'heal': 8.0,
    'dash': 2.0,
    'ice_blast': 5.0,
  };

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

    widget.game.joystickDirection.setValues(vx, vy);
  }

  void onPanEnd(DragEndDetails d) {
    setState(() {
      knobOffset = Offset.zero;
    });
    startDrag = null;

    widget.game.joystickDirection.setZero();
  }

  void _onSkillTap(String skillId) {
    // เช็ค cooldown
    if ((_cooldowns[skillId] ?? 0) > 0) return;

    widget.game.activateSkill(skillId);

    // ตั้ง cooldown
    final maxCd = _maxCooldowns[skillId] ?? 2.0;
    setState(() {
      _cooldowns[skillId] = maxCd;
    });

    // Tick cooldown ทุก 100ms
    _startCooldownTick(skillId);
  }

  void _startCooldownTick(String skillId) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() {
        _cooldowns[skillId] = (_cooldowns[skillId] ?? 0) - 0.1;
        if ((_cooldowns[skillId] ?? 0) <= 0) {
          _cooldowns[skillId] = 0;
        }
      });
      if ((_cooldowns[skillId] ?? 0) > 0) {
        _startCooldownTick(skillId);
      }
    });
  }

  // ✅ ปุ่มสกิลพร้อม cooldown overlay + label
  Widget _buildSkillButton(String skillId, String label, IconData icon, Color color) {
    final cd = _cooldowns[skillId] ?? 0;
    final maxCd = _maxCooldowns[skillId] ?? 2.0;
    final isOnCooldown = cd > 0;
    final cdPercent = isOnCooldown ? (cd / maxCd).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _onSkillTap(skillId),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Base button
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isOnCooldown ? Colors.grey.shade700 : color.withOpacity(0.9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isOnCooldown ? Colors.grey.shade500 : Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isOnCooldown ? Colors.black26 : Colors.black45,
                        blurRadius: 4,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon,
                      color: isOnCooldown ? Colors.white38 : Colors.white,
                      size: 28),
                ),
                // Cooldown overlay (circular wipe)
                if (isOnCooldown)
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      value: 1.0 - cdPercent,
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          color.withOpacity(0.7)),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                // Cooldown text
                if (isOnCooldown)
                  Text(
                    cd.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          // ✅ Skill label
          Text(
            label,
            style: TextStyle(
              color: isOnCooldown ? Colors.white38 : Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2),
              ],
            ),
          ),
        ],
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
                              size: const Size(150, 16),
                              painter: _HpBarPainter(
                                widget.game.playerHP,
                                widget.game.maxHP,
                                hpColor,
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

        // --- Map Button (ขวาบน) ---
        Positioned(
          top: 80,
          right: 16,
          child: GestureDetector(
            onTap: () {
              // เปิด MiniMap
              if (!widget.game.overlays.isActive('MiniMapOverlay')) {
                widget.game.overlays.add('MiniMapOverlay');
              } else {
                widget.game.overlays.remove('MiniMapOverlay');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3E2723),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 3)),
                ]
              ),
              child: const Icon(Icons.map_outlined, color: Colors.white, size: 28),
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
                          BoxShadow(
                              color: Colors.black45,
                              blurRadius: 0,
                              offset: Offset(0, 6))
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

        // --- Skill Buttons (ขวาล่าง) + Labels + Cooldown ---
        Positioned(
          right: 24,
          bottom: 40,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ ปุ่มโจมตี (ใหญ่พิเศษ ไว้ซ้ายของสกิล)
              GestureDetector(
                onTap: () {
                  widget.game.rabbit.playAttack();
                },
                child: Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(right: 16, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.shade700,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 6,
                        offset: Offset(0, 4),
                      ),
                    ],
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade900],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.sports_martial_arts, color: Colors.white, size: 42),
                  ),
                ),
              ),

              // สกิลอื่นๆ
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (GameData.isSkillEquipped('fireball'))
                    _buildSkillButton('fireball', 'ไฟ', Icons.whatshot, Colors.orange),

                  if (GameData.isSkillEquipped('heal'))
                    _buildSkillButton('heal', 'ฮีล', Icons.favorite, Colors.pinkAccent),

                  if (GameData.isSkillEquipped('dash'))
                    _buildSkillButton('dash', 'พุ่ง', Icons.run_circle, Colors.blueAccent),

                  if (GameData.isSkillEquipped('ice_blast'))
                    _buildSkillButton('ice_blast', 'น้ำแข็ง', Icons.ac_unit, Colors.cyan),
                ],
              ),
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

    canvas.drawRect(
        Rect.fromLTWH(0, 0, fillWidth, size.height * 0.4), highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}