import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://tatajdbtmpkcihpeujhr.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRhdGFqZGJ0bXBrY2locGV1amhyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTE0ODEwMiwiZXhwIjoyMDc2NzI0MTAyfQ.-72ZIg3iV2alggLPvIPVwmzJ-QOI6FbISVcx5CF3ol0';

  static Future<void> init() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}

class QuestionService {
  static Future<List<Map<String, dynamic>>> fetchQuestions(String topic) async {
    final response = await SupabaseConfig.client
        .from('questions')
        .select()
        .eq('topic', topic)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// ✅ ดึงคำถามตามวิชาและ difficulty (สำหรับ Battle System)
  static Future<List<Map<String, dynamic>>> fetchQuestionsBySubjectAndDifficulty(
      String subject, int difficulty) async {
    try {
      var query = SupabaseConfig.client
          .from('questions')
          .select()
          .eq('topic', subject);

      // ถ้ามี column difficulty ใน database ก็ filter ด้วย
      // query = query.eq('difficulty', difficulty);

      final response = await query.order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// ✅ สุ่มคำถาม 1 ข้อจากวิชาที่กำหนด
  static Future<Map<String, dynamic>?> fetchRandomQuestion(String subject) async {
    try {
      final questions = await fetchQuestions(subject);
      if (questions.isEmpty) return null;
      questions.shuffle();
      return questions.first;
    } catch (e) {
      return null;
    }
  }
}
