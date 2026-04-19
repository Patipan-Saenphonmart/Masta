import 'package:flame/components.dart';
import '../main_game.dart';

enum NpcState { sleeping, idle }

class Npc extends SpriteAnimationGroupComponent<NpcState> with HasGameReference<RabbitGame> {
  final String message;
  Npc(
      {required Vector2 position,
      required Vector2 size,
      required this.message}) {
    this.position = position;
    this.size = size;
    anchor = Anchor.center; // ✅ ใช้ Anchor center เพื่อให้หมุน/ขยับง่าย
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 💤 ท่าทางตอนนอน (192x32, 6 Frames)
    final sleepImage = await game.images.load('npc_sleep.png');
    final sleepAnim = SpriteAnimation.fromFrameData(
      sleepImage,
      SpriteAnimationData.sequenced(
        amount: 6,
        stepTime: 0.3,
        textureSize: Vector2(32, 32),
      ),
    );

    // 👀 ท่าทางตอนคุย (160x32, 5 Frames)
    final idleImage = await game.images.load('npc_idle.png');
    final idleAnim = SpriteAnimation.fromFrameData(
      idleImage,
      SpriteAnimationData.sequenced(
        amount: 5,
        stepTime: 0.2,
        textureSize: Vector2(32, 32),
      ),
    );

    animations = {
      NpcState.sleeping: sleepAnim,
      NpcState.idle: idleAnim,
    };

    current = NpcState.sleeping;
  }

  void setState(NpcState state) {
    current = state;
  }
}
