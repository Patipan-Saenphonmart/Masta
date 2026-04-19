/// A single line of dialogue in a cutscene.
///
/// Follows the Single Responsibility Principle by cleanly separating:
/// - [uiEffect]: visual instructions for the Flutter overlay (e.g., 'whiteFlash')
/// - [gameAction]: commands for the Flame engine (e.g., 'spawnEnemy')
class CutsceneLine {
  /// The name displayed in the speaker label (e.g., 'MASTA', '✦ SYSTEM').
  final String speaker;

  /// The dialogue text that gets typed out character by character.
  final String text;

  /// Optional visual effect handled by the overlay widget.
  /// Examples: 'showMastaBg', 'whiteFlash', 'fadeFromWhite', 'hideMastaBg'
  final String? uiEffect;

  /// Optional command passed back to the Flame game engine.
  /// Examples: 'wakeUp', 'panToBook', 'pickUpBook', 'spawnEnemy'
  final String? gameAction;

  const CutsceneLine({
    required this.speaker,
    required this.text,
    this.uiEffect,
    this.gameAction,
  });
}

/// A complete cutscene script composed of sequential [CutsceneLine]s.
///
/// The overlay iterates through [lines] one by one.
/// Transition effects are embedded as [uiEffect] values on specific lines,
/// and game-world side effects are embedded as [gameAction] values.
class CutsceneScript {
  final List<CutsceneLine> lines;

  const CutsceneScript({required this.lines});

  /// Total number of dialogue lines.
  int get length => lines.length;
}
