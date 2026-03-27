import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'หน้าhome.dart';
import 'game_data.dart';
import 'utils/save_manager.dart';

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
  }

  Future<void> _checkSaveData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasSave = prefs.containsKey('rabbit_game_save_data');
    });
  }

  void _startNewGame() async {
    // รีเซ็ตข้อมูลสำหรับเริ่มเกมใหม่
    GameData.reset();
    await SaveManager.clearSave();

    if (!mounted) return;
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
  }

  void _loadSaveGame() async {
    bool success = await SaveManager.loadGame();
    if (!mounted) return;
    if (success) {
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
                  'เริ่มเกมใหม่', Icons.play_arrow_rounded, _startNewGame),
              const SizedBox(height: 24),

              // ปุ่ม Continue
              if (_hasSave)
                _buildMenuButton(
                    'โหลดเกมเดิม', Icons.save_alt_rounded, _loadSaveGame)
              else
                _buildMenuButton(
                    'โหลดเกมเดิม (ไม่มีเซฟ)', Icons.save_alt_rounded, null,
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
                size: 30),
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
