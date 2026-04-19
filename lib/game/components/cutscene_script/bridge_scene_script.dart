import '../../../models/cutscene_script.dart'; 


final CutsceneScript bridgeSceneScript = CutsceneScript(
  lines: [
    CutsceneLine(speaker: 'ผู้เล่น', text: 'เดี๋ยว! นั่นตัวอะไรน่ะ!?'),
    CutsceneLine(
      speaker: '✦ SYSTEM', 
      text: '[ มอนสเตอร์พืชปรากฏตัว! ]', 
      gameAction: 'spawn_tutorial_enemy' // 🌟 สั่งให้เสกศัตรู
    ),
    CutsceneLine(
      speaker: 'ผู้เล่น', 
      text: 'มันคือการกลายพันธุ์นี่นา ฉันต้องสู้แล้ว!',
      gameAction: 'pan_camera_to_enemy' // 🌟 สั่งให้กล้องแพนไปหาศัตรู
    ),
  ],
);