import 'dart:async'; // ใช้ในการรอโหลด Future<void> _loadSpriteImage() async { ... }
import 'dart:ui' as ui; // สำหรับการจัดการภาพระดับล่าง
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; //  สำหรับ rootBundle
import 'topic_selection_page.dart';
import 'shop_page.dart';
import '../dialog/character_dialog.dart';
import 'event_page.dart';
import 'warehouse_page.dart';
import '../data/game_data.dart'; // Import GameData เพื่อใช้ค่าจริง
import '../utils/audio_manager.dart'; // ✅ Import AudioManager

class LearningGameHome extends StatefulWidget {
  const LearningGameHome({super.key});

  @override
  State<LearningGameHome> createState() => _LearningGameHomeState();
}

class _LearningGameHomeState extends State<LearningGameHome>
    with SingleTickerProviderStateMixin {
  late AnimationController _spriteController; // ✅ เปลี่ยนชื่อ controller
  ui.Image? _spriteImage; // ✅ ตัวแปรเก็บภาพ sprite sheet
  bool _isImageLoaded = false; // ✅ ตัวแปรเช็คว่าโหลดภาพเสร็จหรือยัง

  @override
  void initState() {
    super.initState();
    _loadSpriteImage(); // ✅ เรียกฟังก์ชันโหลดภาพ
    AudioManager().playBgm(AudioManager.bgmMenuPages); // ✅ เล่น BGM หน้า Home

    // ✅ Setup Animation: สำหรับเล่น sprite sheet วนลูป
    // สมมติว่ามี 4 เฟรม, เฟรมละ 150ms = 600ms (ปรับแก้ตามจำนวนเฟรมจริงของภาพ)
    _spriteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1650),
    )..repeat(); // เล่นวนลูปไปเรื่อยๆ
  }

  // ✅ ฟังก์ชันสำหรับโหลดภาพ Sprite Sheet
  Future<void> _loadSpriteImage() async {
    final ByteData data =
        await rootBundle.load('assets/images/rabbit_idle.png');
    final ui.Codec codec =
        await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo fi = await codec.getNextFrame();
    setState(() {
      _spriteImage = fi.image;
      _isImageLoaded = true;
    });
  }

  @override
  void dispose() {
    _spriteController.dispose(); // ✅ dispose controller
    super.dispose();
  }

  // ฟังก์ชันนำทาง (คงเดิม ห้ามลบ)
  void onButtonPressed(String label) {
    AudioManager().playSfx(AudioManager.sfxUiClick); // ✅ SFX ทุกปุ่ม
    if (label == "แบบทดสอบ") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TopicSelectionPage()),
      );
    } else if (label == "ออกผจญภัย") {
      showDialog(
        context: context,
        barrierColor:
            Colors.transparent, // Keeps the background dark but transparent
        builder: (context) => const CharacterPage(),
      );
    } else if (label == "ร้านค้า") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ShopPage()),
      );
    } else if (label == "กิจกรรม") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Event()),
      );
    } else if (label == "คลังของ") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WarehousePage()),
      );
    } else {
      print("Pressed: $label");
    }
  }

  // --- Widget สไตล์ Fantasy: ปุ่มแถบบน (Shop) ---
  Widget _buildTopTabButton(String label, IconData icon, bool isSelected) {
    return InkWell(
      onTap: () => onButtonPressed(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF795548) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFDCEDC8), size: 24),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: const Color(0xFFDCEDC8),
                fontWeight: FontWeight.w900,
                fontSize: 12,
                fontFamily: 'Comic Sans MS',
                shadows: [
                  Shadow(
                      blurRadius: 2,
                      color: const Color(0xFF3E2723).withOpacity(0.8),
                      offset: const Offset(2, 2))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget สไตล์ Fantasy: การ์ดโหมดเกม ---
  Widget _buildGameModeCard(
      String label, String subLabel, IconData icon, Color bgImageColor) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onButtonPressed(label),
        child: Container(
          height: 110,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF8D6E63),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF795548), width: 3),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      bgImageColor.withOpacity(0.7),
                      const Color(0xFF8D6E63).withOpacity(0.9),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: -15,
                bottom: -15,
                child: Icon(icon,
                    size: 90, color: const Color(0xFFDCEDC8).withOpacity(0.3)),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: const Color(0xFFDCEDC8),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'Comic Sans MS',
                        shadows: [
                          Shadow(
                              blurRadius: 2,
                              color: const Color(0xFF3E2723),
                              offset: const Offset(1, 1))
                        ],
                      ),
                    ),
                    Text(
                      subLabel,
                      style: TextStyle(
                        color: const Color(0xFFFFEB3B),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Comic Sans MS',
                        shadows: [
                          Shadow(
                              blurRadius: 2,
                              color: const Color(0xFF3E2723),
                              offset: const Offset(1, 1))
                        ],
                      ),
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

  // --- Widget สไตล์ Fantasy: ปุ่ม Play ---
  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: () => onButtonPressed("ออกผจญภัย"),
      child: Container(
        height: 70,
        width: double.infinity,
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFA1887F), Color(0xFF795548)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF5D4037), width: 3),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(0, 6),
                blurRadius: 2),
          ],
        ),
        child: Center(
          child: Text(
            "ออกเดินทาง !",
            style: TextStyle(
              color: const Color(0xFFFFEB3B),
              fontSize: 36,
              fontWeight: FontWeight.w900,
              fontFamily: 'Comic Sans MS',
              letterSpacing: 2,
              shadows: [
                Shadow(
                    blurRadius: 4,
                    color: const Color(0xFF3E2723),
                    offset: const Offset(2, 2))
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/bg_fantasy.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. Character Area (พื้นที่โชว์ตัวละคร)
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CharacterPage()),
                      );
                    },
                    child: Container(
                      height: 300,
                      width: 300,
                      color: Colors.transparent, // ให้พื้นที่ว่างกดได้ด้วย
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // แสงด้านหลัง
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFFFFEB3B)
                                        .withOpacity(0.5),
                                    blurRadius: 120,
                                    spreadRadius: 30),
                                BoxShadow(
                                    color: const Color(0xFFC5E1A5)
                                        .withOpacity(0.3),
                                    blurRadius: 80,
                                    spreadRadius: 10)
                              ],
                            ),
                          ),

                          // ✅ Animation: ใช้ CustomPaint กับ SpritePainter
                          if (_isImageLoaded)
                            SizedBox(
                              width: 32 * 8.0, // กว้าง 32 * scale 8
                              height: 32 * 8.0, // สูง 32 * scale 8
                              child: AnimatedBuilder(
                                animation: _spriteController,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: _SpritePainter(
                                      image: _spriteImage!,
                                      animationValue: _spriteController.value,
                                      frameWidth: 32,
                                      frameHeight: 32,
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            const SizedBox(
                                width: 256,
                                height: 256), // Placeholder ระหว่างรอโหลด
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. UI Content
          SafeArea(
            child: Column(
              children: [
                // TOP BAR
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      _buildTopTabButton("ร้านค้า", Icons.storefront, true),
                      const SizedBox(width: 10),
                      _buildTopTabButton("คลังของ", Icons.backpack, true),
                      const Spacer(),
                      // ✅ Level Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 3, vertical: 2),
                        margin: const EdgeInsets.only(right: 3),
                        decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.red.shade800, width: 1.5)),
                        child: Row(
                          children: [
                            const SizedBox(width: 2),
                            Text("Lv.${GameData.playerLevel}",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                      // ✅ เงิน — ใช้ค่าจริงจาก GameData
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                            color: const Color(0xFF5D4037).withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFA1887F), width: 1.5)),
                        child: Row(
                          children: [
                            const Icon(Icons.monetization_on,
                                color: Color(0xFFFFEB3B), size: 14),
                            const SizedBox(width: 2),
                            Text("${GameData.playerGold}",
                                style: const TextStyle(
                                    color: Color(0xFFDCEDC8),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                const Spacer(),

                // BOTTOM PANEL
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF5D4037).withOpacity(0.9),
                          const Color(0xFF3E2723),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24))),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildGameModeCard("แบบทดสอบ", "ฝึกทำโจทย์", Icons.menu_book, const Color(0xFFC5E1A5)),
                          
                          _buildGameModeCard("ภารกิจ","คำใบ้!", Icons.local_fire_department, const Color(0xFFEF5350)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const SizedBox(width: 12),
                          Expanded(child: _buildPlayButton()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "เตรียมตัวให้พร้อม แล้วออกไปลุยกันเลย!",
                        style: TextStyle(
                            color: const Color(0xFFDCEDC8).withOpacity(0.8),
                            fontSize: 12,
                            fontFamily: 'Comic Sans MS'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ คลาสสำหรับวาด Sprite Sheet
class _SpritePainter extends CustomPainter {
  final ui.Image image;
  final double animationValue;
  final int frameWidth;
  final int frameHeight;

  _SpritePainter({
    required this.image,
    required this.animationValue,
    required this.frameWidth,
    required this.frameHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // สมมติว่าเป็น sprite sheet แถวเดียว
    final int totalFrames = image.width ~/ frameWidth;
    // คำนวณเฟรมปัจจุบันจาก animationValue (0.0 -> 1.0)
    final int currentFrame =
        (animationValue * totalFrames).floor() % totalFrames;

    final double srcX = currentFrame * frameWidth.toDouble();
    final double srcY = 0.0; // แถวแรก

    // พื้นที่ที่จะตัดมาจาก sprite sheet
    final Rect srcRect = Rect.fromLTWH(
        srcX, srcY, frameWidth.toDouble(), frameHeight.toDouble());
    // พื้นที่ที่จะวาดลงบน canvas (เต็มพื้นที่ที่กำหนดไว้)
    final Rect dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // วาดภาพโดยใช้ filterQuality.none เพื่อให้ภาพ pixel ไม่เบลอ
    canvas.drawImageRect(
        image, srcRect, dstRect, Paint()..filterQuality = FilterQuality.none);
  }

  @override
  bool shouldRepaint(covariant _SpritePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
