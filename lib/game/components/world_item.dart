import 'package:flame/components.dart';
import '../main_game.dart';

// ✅ Class สำหรับไอเทมในฉาก
class WorldItem extends SpriteAnimationComponent with HasGameReference<RabbitGame> {
  final String name;
  final Sprite? mapSprite; // ✅ เพิ่มตัวแปรสำหรับรับ Sprite จาก Tiled

  WorldItem({
    required Vector2 position,
    required Vector2 size,
    required this.name,
    this.mapSprite, // ✅ รับค่า mapSprite
  }) {
    this.position = position;
    this.size = size;
    anchor = Anchor.bottomLeft;
  }

  @override
  Future<void> onLoad() async {
    // ✅ 1) ถ้ามี sprite จาก Tiled ให้ใช้เป็นแอนิเมชันเฟรมเดียว
    if (mapSprite != null) {
      animation = SpriteAnimation.spriteList([mapSprite!], stepTime: 1.0);
      await super.onLoad();
      return;
    }

    // ✅ 2) Coin drop: sprite sheet 16x16, 15 frames
    if (name.toLowerCase().contains('gold') || name.contains('เหรียญ')) {
      final coinImage = await game.images.load('coin1_16x16.png');
      size = Vector2(16, 16);
      animation = SpriteAnimation.fromFrameData(
        coinImage,
        SpriteAnimationData.sequenced(
          amount: 15,
          stepTime: 0.08,
          textureSize: Vector2(16, 16),
        ),
      );
      await super.onLoad();
      return;
    }

    // ✅ 3) อื่น ๆ ใช้ภาพเดี่ยว (แอนิเมชัน 1 เฟรม)
    String spriteFile = 'arrow.png';
    if (name.contains('story') || name.contains('เรื่องเล่า')) {
      spriteFile = 'book_story.png';
      size = Vector2(32, 32);
    } else if (name.contains('question') || name.contains('คำถาม')) {
      spriteFile = 'book_questions.png';
      size = Vector2(32, 32);
    } else if (name.toLowerCase().contains('potion') || name.contains('ยา')) {
      size = Vector2(24, 24);
      for (final file in const <String>['hp.png', 'h.png', 'potion.png']) {
        try {
          final s = await game.loadSprite(file);
          animation = SpriteAnimation.spriteList([s], stepTime: 1.0);
          await super.onLoad();
          return;
        } catch (_) {
          // try next
        }
      }
    }

    final fallbackSprite = await game.loadSprite(spriteFile);
    animation = SpriteAnimation.spriteList([fallbackSprite], stepTime: 1.0);
    await super.onLoad();
  }
}