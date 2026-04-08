import 'dart:async' as async_lib;
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

  // ✅ Attack & Scan cooldowns
  double _attackCooldown = 0;
  static const double _attackMaxCooldown = 0.8;
  double _scanCooldown = 0;
  static const double _scanMaxCooldown = 15.0;
  bool _isScanActive = false;

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

  // ✅ Attack button handler
  void _onAttackTap() {
    if (_attackCooldown > 0) return;
    widget.game.attackNearbyEnemy();
    setState(() {
      _attackCooldown = _attackMaxCooldown;
    });
    _startActionCooldownTick('attack');
  }

  // ✅ Scan ("The World") button handler
  void _onScanTap() {
    if (_scanCooldown > 0 || _isScanActive) return;
    setState(() {
      _isScanActive = true;
      _scanCooldown = _scanMaxCooldown;
    });
    widget.game.scanWorld();
    // Scan lasts 3 seconds, then unfreeze
    async_lib.Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      widget.game.endScanWorld();
      setState(() {
        _isScanActive = false;
      });
    });
    _startActionCooldownTick('scan');
  }

  void _startActionCooldownTick(String action) {
    async_lib.Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() {
        if (action == 'attack') {
          _attackCooldown = (_attackCooldown - 0.1).clamp(0.0, _attackMaxCooldown);
        } else if (action == 'scan') {
          _scanCooldown = (_scanCooldown - 0.1).clamp(0.0, _scanMaxCooldown);
        }
      });
      final cd = action == 'attack' ? _attackCooldown : _scanCooldown;
      if (cd > 0) {
        _startActionCooldownTick(action);
      }
    });
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
          bottom: 160, // ย้ายขึ้นเพื่อเว้นที่ให้ Attack/Scan
          child: Column(
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
        ),

        // --- ⚔️ Attack & 🔍 Scan Buttons (ขวาล่างสุด) ---
        Positioned(
          right: 16,
          bottom: 30,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 🔍 Scan Button ("The World")
              _buildActionButton(
                label: 'สแกน',
                icon: Icons.radar,
                color: const Color(0xFF7B1FA2),
                glowColor: Colors.purpleAccent,
                cooldown: _scanCooldown,
                maxCooldown: _scanMaxCooldown,
                isActive: _isScanActive,
                onTap: _onScanTap,
                size: 58,
              ),
              const SizedBox(width: 14),
              // ⚔️ Attack Button
              _buildActionButton(
                label: 'โจมตี',
                icon: Icons.sports_martial_arts,
                color: const Color(0xFFC62828),
                glowColor: Colors.redAccent,
                cooldown: _attackCooldown,
                maxCooldown: _attackMaxCooldown,
                isActive: false,
                onTap: _onAttackTap,
                size: 68,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ Premium Action Button (Attack / Scan) with cooldown
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color glowColor,
    required double cooldown,
    required double maxCooldown,
    required bool isActive,
    required VoidCallback onTap,
    double size = 64,
  }) {
    final isOnCooldown = cooldown > 0;
    final cdPercent = isOnCooldown ? (cooldown / maxCooldown).clamp(0.0, 1.0) : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: (isOnCooldown && !isActive) ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isActive
                  ? RadialGradient(
                      colors: [glowColor.withOpacity(0.9), color],
                      center: const Alignment(-0.3, -0.3),
                      radius: 0.9,
                    )
                  : RadialGradient(
                      colors: isOnCooldown
                          ? [Colors.grey.shade600, Colors.grey.shade800]
                          : [color.withOpacity(0.9), color.withOpacity(0.7)],
                      center: const Alignment(-0.3, -0.3),
                      radius: 0.9,
                    ),
              border: Border.all(
                color: isActive
                    ? Colors.white
                    : isOnCooldown
                        ? Colors.grey.shade500
                        : Colors.white.withOpacity(0.8),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? glowColor.withOpacity(0.6)
                      : isOnCooldown
                          ? Colors.black26
                          : color.withOpacity(0.4),
                  blurRadius: isActive ? 16 : 6,
                  spreadRadius: isActive ? 2 : 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Cooldown progress
                if (isOnCooldown && !isActive)
                  SizedBox(
                    width: size - 6,
                    height: size - 6,
                    child: CircularProgressIndicator(
                      value: 1.0 - cdPercent,
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          color.withOpacity(0.7)),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                // Icon
                Icon(
                  icon,
                  color: isOnCooldown && !isActive
                      ? Colors.white38
                      : Colors.white,
                  size: size * 0.45,
                ),
                // Cooldown timer text
                if (isOnCooldown && !isActive && cooldown >= 1)
                  Positioned(
                    bottom: 4,
                    child: Text(
                      cooldown.toStringAsFixed(0),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: size * 0.2,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(
                              color: Colors.black,
                              offset: Offset(1, 1),
                              blurRadius: 2),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isActive ? '⏳' : label,
          style: TextStyle(
            color: isActive
                ? Colors.amberAccent
                : isOnCooldown
                    ? Colors.white38
                    : Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(
                  color: Colors.black54,
                  offset: Offset(1, 1),
                  blurRadius: 2),
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