import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart'; // Added this to use Colors.transparent

enum BookState {
  open,
  close,
  turnPageRight,
  turnPageLeft,
  appear,
  disappear,
  idleOpen,
  idleClosed
}

// 1. Changed to SpriteAnimationGroupComponent to handle multiple states without flickering
class AnimatedBook extends SpriteAnimationGroupComponent<BookState> with HasGameRef {
  
  @override
  Future<void> onLoad() async {
    // Load all Sprite Sheets
    final appearAnim = await gameRef.loadSpriteAnimation(
      'pages_apper.png',
      SpriteAnimationData.sequenced(
        amount: 2, 
        stepTime: 0.08, 
        textureSize: Vector2(240, 176),
        loop: false, 
      ),
    );

    final disappearAnim = await gameRef.loadSpriteAnimation(
      'pages_desappear-Sheet.png',
      SpriteAnimationData.sequenced(
        amount: 2,
        stepTime: 0.08,
        textureSize: Vector2(240, 176),
        loop: false,
      ),
    );

   // For the Open Book (12 frames, 4 columns)
    final openAnim = await gameRef.loadSpriteAnimation(
      'Open_book.png',
      SpriteAnimationData.sequenced(
        amount: 12,
        stepTime: 0.08,
        textureSize: Vector2(272, 272),
        amountPerRow: 4, // ✅ ADD THIS: Tells Flame to drop to the next row after 4 frames
        loop: false,
      ),
    );

    // For the Close Book (12 frames, 4 columns)
    final closeAnim = await gameRef.loadSpriteAnimation(
      'Close_book.png',
      SpriteAnimationData.sequenced(
        amount: 12,
        stepTime: 0.08,
        textureSize: Vector2(272, 272),
        amountPerRow: 4, // ✅ ADD THIS
        loop: false,
      ),
    );

    // For Turning Pages Right (14 frames, 4 columns)
    final turnRightAnim = await gameRef.loadSpriteAnimation(
      'Turning_pages_right.png',
      SpriteAnimationData.sequenced(
        amount: 15,
        stepTime: 0.08,
        textureSize: Vector2(272, 272),
        amountPerRow: 4, // ✅ ADD THIS
        loop: false,
      ),
    );

    // For Turning Pages Left (14 frames, 4 columns)
    final turnLeftAnim = await gameRef.loadSpriteAnimation(
      'Turning_pages_left.png',
      SpriteAnimationData.sequenced(
        amount: 15,
        stepTime: 0.08,
        textureSize: Vector2(272, 272),
        amountPerRow: 4, // ✅ ADD THIS
        loop: false,
      ),
    );
    // Setup Idle Animations
    final idleClosedAnim = SpriteAnimation.spriteList(
      [openAnim.frames.first.sprite],
      stepTime: 1.0,
      loop: false,
    );
    final idleOpenAnim = SpriteAnimation.spriteList(
      [openAnim.frames.last.sprite],
      stepTime: 1.0,
      loop: false,
    );

    // 2. Map all animations to their states
    animations = {
      BookState.appear: appearAnim,
      BookState.disappear: disappearAnim,
      BookState.open: openAnim,
      BookState.close: closeAnim,
      BookState.turnPageRight: turnRightAnim,
      BookState.turnPageLeft: turnLeftAnim,
      BookState.idleClosed: idleClosedAnim,
      BookState.idleOpen: idleOpenAnim,
    };

    // 3. Set initial state
    current = BookState.idleClosed;
    anchor = Anchor.center; 
    size = Vector2(300, 300); 
    super.onLoad();
  }

  // Function to change animation
  // ฟังก์ชันเพื่อเปลี่ยนแอนิเมชัน (แก้ไขแล้ว)
  void setBookState(BookState newState) {
    // 1. เปลี่ยนสถานะเสมอ
    current = newState;
    
    // 2. บังคับให้แอนิเมชันเริ่มใหม่จากเฟรมที่ 0 เสมอ ไม่ว่าจะกดปุ่มเดิมซ้ำหรือไม่ก็ตาม
    if (animationTickers != null && animationTickers![newState] != null) {
      animationTickers![newState]!.reset();
    }
  }
}

class BookReadingGame extends FlameGame {
  late AnimatedBook book;
  final VoidCallback? onOpenBookFinished;

  BookReadingGame({this.onOpenBookFinished});

  // 5. This removes the black box background!
  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    book = AnimatedBook();
    add(book);
    book.position = size / 2;
    super.onLoad();
    await Future.delayed(const Duration(milliseconds: 200));
    openBook();
    
    // Wait for the open animation to finish (approx 12 frames @ 0.08s = 0.96s)
    await Future.delayed(const Duration(milliseconds: 1000));
    onOpenBookFinished?.call();
  }
  
  void openBook() => book.setBookState(BookState.open);
  void closeBook() => book.setBookState(BookState.close);
  void turnRight() => book.setBookState(BookState.turnPageRight);
  void turnLeft() => book.setBookState(BookState.turnPageLeft);
  void appear() => book.setBookState(BookState.appear);
  void disappear() => book.setBookState(BookState.disappear);
}