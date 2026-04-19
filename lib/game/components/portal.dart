import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Portal extends PositionComponent {
  final String targetMap;
  Portal(
      {required Vector2 position,
      required Vector2 size,
      required this.targetMap}) {
    this.position = position;
    this.size = size;
  }
  @override
  void render(Canvas canvas) {
    canvas.drawRect(
        size.toRect(), Paint()..color = Colors.purpleAccent.withValues(alpha: 0.3));
  }
}