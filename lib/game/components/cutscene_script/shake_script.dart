import '../../../models/cutscene_script.dart';

final CutsceneScript shakeSceneScript = CutsceneScript(
  lines: [
    CutsceneLine(
      speaker: 'ผู้เล่น',
      text: 'แผ่นดินไหวงั้นเหรอ... เกิดอะไรขึ้นเนี่ย!',
      gameAction: 'shake_camera' // 🌟 สั่งให้กล้องสั่น
    ),
    CutsceneLine(
      speaker: '✦ SYSTEM',
      text: '[ ระวังตัวด้วย! ]',
    ),
  ],
);
