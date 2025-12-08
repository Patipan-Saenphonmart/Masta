import 'package:flutter/material.dart';
import 'supabase_config.dart';
import 'หน้าhome.dart';

Future<String> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init(); // initialize Supabase (placeholder)
  runApp(const LearningGameApp());
  return "App started";
}

class LearningGameApp extends StatelessWidget {
  const LearningGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learning Game',
      debugShowCheckedModeBanner: false,
      home: const LearningGameHome(),
    );
  }
}
