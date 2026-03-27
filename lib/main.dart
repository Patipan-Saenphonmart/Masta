import 'package:flutter/material.dart';
import 'supabase_config.dart';
import 'title_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init(); // initialize Supabase (placeholder)
  runApp(const LearningGameApp());
}

class LearningGameApp extends StatelessWidget {
  const LearningGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learning Game',
      debugShowCheckedModeBanner: false,
      home: const TitleScreen(), // ✅ เปลี่ยนมาโหลดหน้าเริ่มเกมเป็นหน้าแรกสุด
    );
  }
}
