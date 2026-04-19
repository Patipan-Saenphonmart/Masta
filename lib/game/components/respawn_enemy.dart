import 'package:flame/components.dart';

// ✅ Class สำหรับเก็บข้อมูลสำหรับเรียกมอนสเตอร์กลับมาเกิดใหม่
class RespawnData {
  final Vector2 position;
  final String name;
  final String element;
  final String strongSubject;
  final String weakSubject;
  final Map<String, double> proficiency;
  double timer;

  RespawnData({
    required this.position,
    required this.name,
    required this.element,
    required this.strongSubject,
    required this.weakSubject,
    required this.proficiency,
    required this.timer,
  });
}