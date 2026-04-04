import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../data/game_data.dart';
import '../models/book.dart';
import '../game/components/animated_book.dart';

class BookReadingDialog extends StatefulWidget {
  final String itemTitle;
  const BookReadingDialog({super.key, required this.itemTitle});

  static void show(BuildContext context, String itemTitle) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BookReadingDialog(itemTitle: itemTitle);
      },
    );
  }

  @override
  State<BookReadingDialog> createState() => _BookReadingDialogState();
}

class _BookReadingDialogState extends State<BookReadingDialog> {
  late final BookReadingGame myGame;
  late Book bookData;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    Book? foundAppBook = GameData.getBookByTitle(widget.itemTitle);
    if (foundAppBook != null) {
      bookData = foundAppBook;
    } else {
      bookData = Book.regular(
        id: 'default_book',
        title: widget.itemTitle,
        description: 'หนังสือแห่งปริศนา',
        content: 'เนื้อหาในหนังสือนี้ยังคงเป็นความลับ...',
      );
    }

    myGame = BookReadingGame(
      onOpenBookFinished: () {
        if (mounted && !_dialogShown) {
          _dialogShown = true;
          _showStoryDialog();
        }
      }
    );
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        height: 550, // Fixed height or adjust based on screen
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D1A), // Fantasy theme
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD4AF37), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E1A47).withOpacity(0.8),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      bookData.title,
                      style: const TextStyle(
                        color: Color(0xFFD4AF37), 
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFFD4AF37)),
                    onPressed: () async {
                      myGame.closeBook();
                      await Future.delayed(const Duration(milliseconds: 1000));
                      if (mounted) Navigator.of(context).pop();
                    },
                  )
                ],
              ),
            ),
            
            // Game Widget area
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                   Container(
                     decoration: const BoxDecoration(
                       gradient: RadialGradient(
                         colors: [Color(0xFF2E1A47), Color(0xFF0D0D1A)],
                         radius: 0.9,
                       ),
                       borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
                     ),
                   ),
                   SizedBox(
                     width: 350,
                     height: 350,
                     child: GameWidget(game: myGame),
                   ),
                   // Next/Back Book Buttons inside dialog
                   Positioned(
                     bottom: 20,
                     right: 20,
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.end,
                       children: [
                         FloatingActionButton(
                           heroTag: 'dialog_left',
                           backgroundColor: const Color(0xFF2E1A47),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(15),
                             side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                           ),
                           mini: true,
                           onPressed: () => myGame.turnRight(),
                           child: const Icon(Icons.arrow_back, color: Color(0xFFD4AF37)),
                         ),
                         const SizedBox(width: 15),
                         FloatingActionButton(
                           heroTag: 'dialog_right',
                           backgroundColor: const Color(0xFF2E1A47),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(15),
                             side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                           ),
                           mini: true,
                           onPressed: () => myGame.turnLeft(),
                           child: const Icon(Icons.arrow_forward, color: Color(0xFFD4AF37)),
                         ),
                       ],
                     ),
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
