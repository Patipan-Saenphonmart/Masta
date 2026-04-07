import 'package:flutter/material.dart';
import '../main_game.dart';
import '../../page/home_page.dart';
import '../../utils/audio_manager.dart';

class GameEndingOverlay extends StatefulWidget {
  final RabbitGame game;
  const GameEndingOverlay({super.key, required this.game});

  @override
  State<GameEndingOverlay> createState() => _GameEndingOverlayState();
}

class _GameEndingOverlayState extends State<GameEndingOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Fade in effect for the whole screen
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animController);
    _animController.forward();
    
    // Play Victory or Title Theme
    AudioManager().playBgm(AudioManager.bgmTitleScreen);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black.withOpacity(0.9), // Dark background
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 80),
            const SizedBox(height: 20),
            const Text(
              "VICTORY!",
              style: TextStyle(
                color: Colors.amber,
                fontSize: 60,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.0,
                shadows: [
                  Shadow(color: Colors.white, blurRadius: 10)
                ]
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "คุณสามารถเอาชนะบอสใหญ่และปกป้องดินแดนแห่งความรู้ไว้ได้",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 50),
            const Text(
              "- CREDITS -",
              style: TextStyle(color: Colors.grey, fontSize: 18, letterSpacing: 2.0),
            ),
            const SizedBox(height: 10),
            const Text(
              "Project MASTA\nDeveloped with Flutter & Flame",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () {
                // Return to Main Menu
                Navigator.pushAndRemoveUntil(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const LearningGameHome(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                "กลับสู่หน้าหลัก",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}
