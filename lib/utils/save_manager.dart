import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/game_data.dart';

class SaveManager {
  static const String _saveKey = 'rabbit_game_save_data';
  static const String _playerPosXKey = 'player_pos_x';
  static const String _playerPosYKey = 'player_pos_y';

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
    await prefs.remove(_playerPosXKey);
    await prefs.remove(_playerPosYKey);
    print("Save data cleared.");
  }

  static Future<void> savePlayerPosition(double x, double y) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_playerPosXKey, x);
    await prefs.setDouble(_playerPosYKey, y);
  }

  static Future<Map<String, double>?> loadPlayerPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final x = prefs.getDouble(_playerPosXKey);
    final y = prefs.getDouble(_playerPosYKey);
    if (x == null || y == null) return null;
    return {'x': x, 'y': y};
  }
}
