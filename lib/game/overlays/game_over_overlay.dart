import 'package:flutter/material.dart';
import '../main_game.dart';
import '../../utils/audio_manager.dart'; // ✅ Import AudioManager

class GameOverOverlay extends StatelessWidget {
  final RabbitGame game;

  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    // ✅ หยุด BGM เมื่อ Game Over
    AudioManager().stopBgm();
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "GAME OVER",
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 60,
                fontWeight: FontWeight.bold,
                fontFamily: 'Comic Sans MS',
                shadows: [
                  Shadow(
                      color: Colors.black, blurRadius: 4, offset: Offset(2, 2))
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "พลังชีวิตของคุณหมดแล้ว...",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8D6E63),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFF5D4037), width: 3),
                ),
              ),
              onPressed: () {
                AudioManager().playSfx(AudioManager.sfxUiClick); // ✅ SFX
                game.resetGame();
              },
              child: const Text(
                "เกิดใหม่ที่จุดเริ่มต้น",
                style: TextStyle(
                  color: Color(0xFFFFEB3B),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Comic Sans MS',
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                AudioManager().playSfx(AudioManager.sfxUiClick); // ✅ SFX
                Navigator.of(context).pop(); // กลับหน้าจอ Character/Home
              },
              child: const Text(
                "ออกไปพักผ่อน",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
