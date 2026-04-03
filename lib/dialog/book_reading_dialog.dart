import 'package:flutter/material.dart';
import '../data/game_data.dart';
import '../models/book.dart';
import '../page/book_reading_page.dart';

class BookReadingDialog {
  static void show(BuildContext context, String itemTitle) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF8D6E63), width: 3),
          ),
          elevation: 10,
          backgroundColor: const Color(0xFFFFF8E1),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFFF8E1),
                  const Color(0xFFF5F5DC).withOpacity(0.95),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8D6E63).withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF8D6E63), width: 2),
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    size: 50,
                    color: Color(0xFF5D4037),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                Text(
                  'อ่านหนังสือ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3E2723),
                    fontFamily: 'Comic Sans MS',
                    shadows: [
                      Shadow(
                        blurRadius: 2,
                        color: Colors.brown.withOpacity(0.3),
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Question
                Text(
                  'คุณต้องการอ่านหนังสือเล่มนี้หรือไม่?\n"$itemTitle"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.brown.shade700,
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Cancel Button
                    SizedBox(
                      width: 120,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'ยกเลิก',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    // Confirm Button
                    SizedBox(
                      width: 120,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          _openBook(context, itemTitle);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'ตกลง',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _openBook(BuildContext context, String itemTitle) {
    Book? book = GameData.getBookByTitle(itemTitle);
    
    if (book != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookReadingPage(book: book),
        ),
      );
    } else {
      // If book not found in books list, create a default book
      final defaultBook = Book.regular(
        id: 'default_book',
        title: itemTitle,
        description: 'หนังสือธรรมดา',
        content: 'นี่คือเนื้อหาของหนังสือ "$itemTitle"\n\n'
                    'เนื้อหากำลังถูกพัฒนาเพิ่มเติม...\n\n'
                    'คุณสามารถเพลิดเพลินกับการอ่านหนังสือเล่มนี้ได้',
      );
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookReadingPage(book: defaultBook),
        ),
      );
    }
  }
}
