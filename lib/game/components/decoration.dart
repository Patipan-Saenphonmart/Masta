import 'package:flame/components.dart';

class MyDecoration extends SpriteComponent {
  MyDecoration(
      {required Vector2 position,
      required Vector2 size,
      required Sprite sprite})
      : super(
          sprite: sprite,
          position: position,
          size: size,
          anchor: Anchor.bottomLeft,
        );
}