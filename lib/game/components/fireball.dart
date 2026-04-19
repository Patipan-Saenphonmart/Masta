import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../main_game.dart';
import 'enemy.dart';
import 'obstacle.dart';

class Fireball extends SpriteAnimationComponent with HasGameReference<RabbitGame>, CollisionCallbacks {
  final Vector2 direction;
  final double speed = 300;
  final double lifetime = 1.5;
  double elapsed = 0;

  Fireball({required Vector2 position, required this.direction})
      : super(position: position, size: Vector2(24, 24), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox(isSolid: true));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(
        Offset(size.x / 2, size.y / 2), 8, Paint()..color = Colors.orange);
    canvas.drawCircle(
        Offset(size.x / 2, size.y / 2), 5, Paint()..color = Colors.yellow);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += direction * speed * dt;
    elapsed += dt;
    if (elapsed > lifetime) removeFromParent();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Enemy) {
      other.playHit();
      other.die();
      removeFromParent();
    } else if (other is Obstacle) {
      removeFromParent();
    }
  }
}