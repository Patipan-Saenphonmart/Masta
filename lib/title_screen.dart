import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'page/home_page.dart';
import 'data/game_data.dart';
import 'utils/save_manager.dart';
import 'utils/audio_manager.dart'; // ✅ Import AudioManager
import 'game/rabbit_game.dart'; // ✅ Import RabbitGamePage

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  bool _hasSave = false;

  @override
  void initState() {
    super.initState();
    _checkSaveData();
    AudioManager().playBgm(AudioManager.bgmTitleScreen); // ✅ เล่น BGM หน้า Title
  }

  Future<void> _checkSaveData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasSave = prefs.containsKey('rabbit_game_save_data');
    });
  }

  void _startNewGame() async {
    // ✅ ถ้ามี save data อยู่แล้ว → แสดง dialog ยืนยันก่อน
    if (_hasSave) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFFFFF8E1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF8D6E63), width: 3),
          ),
          title: const Text('⚠️ ยืนยันเริ่มเกมใหม่',
              style: TextStyle(
                  color: Color(0xFF4E342E),
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          content: const Text(
              'ข้อมูลเซฟเดิมจะหายไป\nต้องการเริ่มใหม่หรือไม่?',
              style: TextStyle(color: Color(0xFF5D4037), fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ยกเลิก',
                  style: TextStyle(
                      color: Color(0xFF795548),
                      fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('เริ่มใหม่!',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    // รีเซ็ตข้อมูลสำหรับเริ่มเกมใหม่
    GameData.reset();
    await SaveManager.clearSave();

    if (!mounted) return;
    // ✅ ไปหน้า RabbitGamePage พร้อม Cutscene + Tutorial เลย
    AudioManager().stopBgm(); // ✅ หยุด BGM ก่อนเข้าเกม
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RabbitGamePage(showIntroCutscene: true),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  // ✅ ดำเนินการต่อ — โหลด save และไปหน้า Home
  void _continueGame() async {
    bool success = await SaveManager.loadGame();
    if (!mounted) return;
    if (success) {
      AudioManager().stopBgm(); // ✅ หยุด BGM ก่อนไป Home
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LearningGameHome(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบข้อมูลเซฟเดิม!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // พื้นหลังหน้าเริ่มเกม
          Image.asset(
            'assets/images/bg_fantasy.png',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.5)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // โลโก้ หรือ ชื่อเกม
              const Text(
                'MASTA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Comic Sans MS',
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFEB3B),
                  letterSpacing: 2,
                  height: 1.1,
                  shadows: [
                    Shadow(
                        blurRadius: 10,
                        color: Colors.black,
                        offset: Offset(0, 4)),
                    Shadow(
                        blurRadius: 2,
                        color: Color(0xFFE65100),
                        offset: Offset(0, 2))
                  ],
                ),
              ),
              const SizedBox(height: 80),

              // ปุ่ม New Game
              _buildMenuButton(
                  'เริ่มเกมใหม่', Icons.play_arrow_rounded, () {
                    AudioManager().playSfx(AudioManager.sfxUiClick); // ✅ SFX
                    _startNewGame();
                  }),
              const SizedBox(height: 24),

              // ปุ่ม Continue (ดำเนินการต่อ)
              if (_hasSave)
                _buildMenuButton(
                    'ดำเนินการต่อ', Icons.play_circle_filled_rounded, _continueGame)
              else
                _buildMenuButton(
                    'ดำเนินการต่อ (ไม่มีเซฟ)', Icons.play_circle_filled_rounded, null,
                    disabled: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(String text, IconData icon, VoidCallback? onTap,
      {bool disabled = false}) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 300,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: disabled
                ? [Colors.grey.shade700, Colors.grey.shade800]
                : [const Color(0xFF8D6E63), const Color(0xFF5D4037)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: disabled ? Colors.grey.shade900 : const Color(0xFF3E2723),
              width: 3),
          boxShadow: disabled
              ? []
              : const [
                  BoxShadow(
                      color: Colors.black54,
                      blurRadius: 6,
                      offset: Offset(0, 6))
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color:
                    disabled ? Colors.grey.shade400 : const Color(0xFFFFEB3B),
                size: 20),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: disabled ? Colors.grey.shade400 : Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Comic Sans MS',
                shadows: disabled
                    ? null
                    : [const Shadow(blurRadius: 3, color: Colors.black)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
