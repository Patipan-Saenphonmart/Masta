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
}
