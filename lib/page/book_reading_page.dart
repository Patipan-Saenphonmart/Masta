import 'package:flutter/material.dart';
import '../models/book.dart';
import 'package:flame/game.dart';
import '../game/components/animated_book.dart';

class BookReadingPage extends StatefulWidget {
  final Book book;

  const BookReadingPage({super.key, required this.book});

  @override
  State<BookReadingPage> createState() => _BookReadingPageState();
}

class _BookReadingPageState extends State<BookReadingPage> {
  // 1. สร้างอินสแตนซ์ของเกม
  late final BookReadingGame myGame;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    myGame = BookReadingGame(
      onOpenBookFinished: () {
        if (mounted && !_dialogShown) {
          _dialogShown = true;
          _showStoryDialog();
        }
      }
    ); // สร้างเกม
  }

  void _showStoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFD4AF37), width: 2), // Gold border
          ),
          title: const Text(
            "ความจริงจากอดีตกาล",
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                )
              ]
            ),
            textAlign: TextAlign.center,
          ),
          content: const SingleChildScrollView(
            child: Text(
              "แด่ดวงจิตผู้มองเห็นความจริง... หากเจ้าอ่านอักขระเหล่านี้ออก แสดงว่าเจ้าคือผู้ถูกเลือกจาก MASTA\n\n"
              "โลกนี้กำลังป่วยหนัก สิ่งที่ประชากรดั้งเดิมหวาดกลัวและเทิดทูนว่าคือ 'เวทมนตร์'...\n\n"
              "แท้จริงแล้วมันคือ 'สมการทางวิทยาศาสตร์' ที่สูญเสียการควบคุมต่างหาก\n\n"
              "พวกมันใช้พลังงานโดยไม่เข้าใจหลักอุณหพลศาสตร์ บิดเบือนแรงโน้มถ่วงโดยไม่สนมวลของสสาร...\n\n"
              "จงใช้ความรู้ของเจ้า แก้ไขตัวแปรที่ผิดเพี้ยนเหล่านี้ และจงบันทึกความจริงลงในหน้ากระดาษที่เหลือ... ก่อนที่มิติแห่งนี้จะล่มสลาย",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.6,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A341B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: const BorderSide(color: Color(0xFFD4AF37)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("ข้าเข้าใจแล้ว", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A), // Deep mystical dark
      appBar: AppBar(
        title: Text(
          widget.book.title,
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          )
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFD4AF37)),
          onPressed: () async {
            // 1. สั่งให้ Flame เล่นแอนิเมชันปิดสมุด
            myGame.closeBook();
            // 2. สั่งให้ Flutter รอประมาณ 1 วินาทีเพื่อให้แอนิเมชันเล่นจนจบ
            await Future.delayed(const Duration(milliseconds: 1000));
            
            // 3. เช็คว่าผู้ใช้ยังอยู่หน้านี้ไหม แล้วค่อยปิดหน้าจอ
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF2E1A47), Color(0xFF0D0D1A)],
            radius: 0.9,
            center: Alignment.center,
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 350, // กำหนดขนาดของสมุด
            height: 350,
            // 2. แทนที่เนื้อหาสมุดด้วย FlameWidget
            child: GameWidget(
              game: myGame,
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0, right: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'left',
              backgroundColor: const Color(0xFF2E1A47),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
              ),
              onPressed: () {
                // 3. เชื่อมต่อปุ่มกับการเรียกใช้แอนิเมชัน
                myGame.turnRight();
              },
              child: const Icon(Icons.arrow_back, color: Color(0xFFD4AF37)),
            ),
            const SizedBox(width: 15),
            FloatingActionButton(
              heroTag: 'right',
              backgroundColor: const Color(0xFF2E1A47),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
              ),
              onPressed: () {
                // 3. เชื่อมต่อปุ่มกับการเรียกใช้แอนิเมชัน
                myGame.turnLeft();
              },
              child: const Icon(Icons.arrow_forward, color: Color(0xFFD4AF37)),
            ),
          ],
        ),
      ),
    );
  }
}
