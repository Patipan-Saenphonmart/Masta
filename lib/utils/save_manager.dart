import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../game_data.dart';

class SaveManager {
  static const String _saveKey = 'rabbit_game_save_data';

  static Future<void> saveGame() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonData = jsonEncode(GameData.toJson());
    await prefs.setString(_saveKey, jsonData);
    print("Game Saved Successfully!");
  }

  static Future<bool> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_saveKey)) {
      return false; // No save data found
    }
    
    try {
      final String? jsonData = prefs.getString(_saveKey);
      if (jsonData != null) {
        final Map<String, dynamic> decoded = jsonDecode(jsonData);
        GameData.fromJson(decoded);
        print("Game Loaded Successfully!");
        return true;
      }
    } catch (e) {
      print("Error loading game: $e");
    }
    return false;
  }
  
  static Future<void> clearSave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
    print("Save data cleared.");
  }
}
