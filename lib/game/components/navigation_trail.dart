import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class NavigationTrail extends PositionComponent {
  final Vector2 start;
  final Vector2 target;
  double _time = 0;

  NavigationTrail({required this.start, required this.target}) {
    position = start;
    size = target - start; // The bounding box is between start and target
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt * 3; // speed of animation

    // Simple lifetime: disappear after 10 seconds.
    if (_time > 30) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = Colors.amber.withOpacity(0.6)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final dashLength = 10.0;
    final gapLength = 10.0;
    final totalLength = dashLength + gapLength;

    // We draw relative to the component's position (which is `start`)
    final Vector2 localTarget = target - start;
    
    // Draw a dashed line from (0,0) to localTarget
    double distance = localTarget.length;
    Vector2 direction = localTarget.normalized();

    // offset by time to create an animated flowing effect
    double startOffset = _time % totalLength;

    for (double i = -startOffset; i < distance; i += totalLength) {
      if (i + dashLength < 0) continue; // skip dashes before start

      double drawStart = i < 0 ? 0 : i;
      double drawEnd = (i + dashLength > distance) ? distance : i + dashLength;

      Vector2 p1 = direction * drawStart;
      Vector2 p2 = direction * drawEnd;

      canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), paint);
    }
    
    // Draw a star/circle at the target destination
    final targetPaint = Paint()
      ..color = Colors.yellowAccent
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(Offset(localTarget.x, localTarget.y), 10 + (3 * (_time % 2)), targetPaint);
  }
}
