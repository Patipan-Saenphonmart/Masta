import '../../../models/cutscene_script.dart';

/// Returns the complete opening cutscene script.
///
/// All 3 acts are merged into a single flat list of [CutsceneLine].
/// Visual transitions between acts are encoded as [uiEffect] values,
/// and game-world side effects are encoded as [gameAction] values.
CutsceneScript getOpeningScript() {
  return const CutsceneScript(lines: [
    // =============================================================
    // องก์ 1: The Summoning Void (จอดำ + สัญลักษณ์ MASTA)
    // =============================================================
    CutsceneLine(
      speaker: 'MASTA (ลึกลับ)',
      text: 'สมการกำลังพังทลาย... กฎเกณฑ์ถูกบิดเบือน...',
      uiEffect: 'showMastaBg',
    ),
    CutsceneLine(
      speaker: 'MASTA',
      text: 'พวกเขาใช้พลังโดยไม่เข้าใจแก่นแท้... โลกนี้กำลังจะแตกสลาย...',
    ),
    CutsceneLine(
      speaker: 'MASTA',
      text:
          'ดวงจิตจากต่างภพเอ๋ย... ผู้มองเห็นความจริงเบื้องหลังมายา... จงมาเป็นตาให้ข้า... จงมาเป็นผู้บันทึก...',
      uiEffect: 'whiteFlash', // → จบองก์ 1 ด้วยแสงแฟลชขาว
    ),

    // =============================================================
    // องก์ 2: The Awakening (ตื่นขึ้นในป่า)
    // =============================================================
    CutsceneLine(
      speaker: 'ผู้เล่น (คิดในใจ)',
      text:
          '(อูย... ปวดหัวจัง... ที่นี่ที่ไหนเนี่ย? การสอบวิชาฟิสิกส์เมื่อกี้จบหรือยัง?)',
      uiEffect: 'fadeFromWhite', // → เริ่มองก์ 2 ด้วยการ fade จากขาว
    ),
    CutsceneLine(
      speaker: '✦ SYSTEM',
      text: '[ ตัวละครลุกขึ้นยืน ]',
      gameAction: 'wakeUp',
    ),
    CutsceneLine(
      speaker: 'ผู้เล่น (ตกใจ)',
      text: 'เดี๋ยว!! ที่นี้มันที่ไหนเนี่ย เกิดอะไรขึ้นกับฉัน!?',
    ),
    CutsceneLine(
      speaker: '✦ SYSTEM',
      text: '[ มีหนังสือปกหนาตกอยู่ข้างๆ... มีออร่าเรืองแสง ]',
      gameAction: 'panToBook',
    ),
    CutsceneLine(
      speaker: 'ผู้เล่น',
      text:
          '(สมุดบันทึกงั้นเหรอ? หน้าปกเขียนว่า... The Scholar\'s Grimoire...)',
    ),
    CutsceneLine(
      speaker: '✦ SYSTEM',
      text: '✦ ได้รับ: บันทึกแห่งจอมปราชญ์ (The Scholar\'s Grimoire) ✦',
      gameAction: 'pickUpBook',
      uiEffect: 'transitionFlash', // → จบองก์ 2 ด้วย flash สั้นๆ
    ),
  ]);
}
