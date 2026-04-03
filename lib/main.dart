import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ สำหรับ Full Screen
import 'config/supabase_config.dart';
import 'title_screen.dart';
import 'utils/audio_manager.dart'; // ✅ Import AudioManager

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init(); // initialize Supabase (placeholder)
  await AudioManager().init(); // ✅ Initialize AudioManager

  // ✅ ตั้งค่า Full Screen (ซ่อน status bar + navigation bar)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // ✅ ล็อกแนวตั้ง (ถ้าต้องการ)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const LearningGameApp());
}

class LearningGameApp extends StatelessWidget {
  const LearningGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AppLifecycleAudioGuard();
  }
}

class _AppLifecycleAudioGuard extends StatefulWidget {
  const _AppLifecycleAudioGuard();

  @override
  State<_AppLifecycleAudioGuard> createState() => _AppLifecycleAudioGuardState();
}

class _AppLifecycleAudioGuardState extends State<_AppLifecycleAudioGuard>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      AudioManager().stopAllAudio();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Learning Game',
      debugShowCheckedModeBanner: false,
      home: TitleScreen(), // ✅ เปลี่ยนมาโหลดหน้าเริ่มเกมเป็นหน้าแรกสุด
    );
  }
}
