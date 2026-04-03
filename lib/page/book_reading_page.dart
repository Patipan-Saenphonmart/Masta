// book_reading_page.dart
import 'package:flutter/material.dart';
import '../models/book.dart';

class BookReadingPage extends StatefulWidget {
  final Book book;

  const BookReadingPage({super.key, required this.book});

  @override
  State<BookReadingPage> createState() => _BookReadingPageState();
}

class _BookReadingPageState extends State<BookReadingPage> {
  // ตัวแปรสำหรับจัดการหน้าหนังสือ
  int _currentSpread = 0;
  final int _maxSpreads = 2; // มี 2 คู่หน้า (หน้า 1-2 และ หน้า 3-4)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.book.title,
          style: const TextStyle(
            fontFamily: 'PixelArtFont',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFFD54F),
            shadows: [
              Shadow(blurRadius: 1, color: Colors.black, offset: Offset(2, 2)),
              Shadow(blurRadius: 1, color: Colors.black, offset: Offset(1, 1)),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_fantasy.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.book.isQuestLog) ...[
                      SizedBox(height: 500, child: _buildQuestLogContent()),
                    ] else ...[
                      _buildRegularBookContent(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegularBookContent() {
    return Column(
      children: [
        Container(
          height: 350, // Fix ความสูงกรอบหนังสือ
          padding: const EdgeInsets.all(16), 
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/UI_TravelBook_BookCover01a.png'),
              fit: BoxFit.fill,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5)),
            ],
          ),
          child: Row(
            // ✅ เพิ่มบรรทัดนี้: บังคับให้กระดาษซ้าย-ขวา ยืดเต็มความสูง 350 เท่ากันเสมอ
            crossAxisAlignment: CrossAxisAlignment.stretch, 
            children: [
              // === หน้าซ้าย (Left Page) ===
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 2),
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/UI_TravelBook_BookPageLeft01a.png'),
                      fit: BoxFit.fill, // ให้รูปกระดาษขยายเต็มพื้นที่
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: _currentSpread == 0 ? _buildPage1() : _buildPage3(),
                  ),
                ),
              ),

              // === หน้าขวา (Right Page) ===
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 2),
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/UI_TravelBook_BookPageRight01a.png'),
                      fit: BoxFit.fill, // ให้รูปกระดาษขยายเต็มพื้นที่
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: _currentSpread == 0 ? _buildPage2() : _buildBlankLines(),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ปุ่มควบคุมการเปิดหน้าหนังสือ (Pagination)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.arrow_back_ios_rounded, 
                  color: _currentSpread > 0 ? Colors.white : Colors.white38, 
                  size: 24,
                ),
                onPressed: _currentSpread > 0 ? () {
                  setState(() {
                    _currentSpread--;
                  });
                } : null,
              ),
              
              const SizedBox(width: 20),
              
              Text(
                'หน้า ${_currentSpread * 2 + 1} - ${_currentSpread * 2 + 2}',
                style: const TextStyle(
                  fontFamily: 'PixelArtFont',
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),

              const SizedBox(width: 20),

              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.arrow_forward_ios_rounded, 
                  color: _currentSpread < _maxSpreads - 1 ? Colors.white : Colors.white38, 
                  size: 24,
                ),
                onPressed: _currentSpread < _maxSpreads - 1 ? () {
                  setState(() {
                    _currentSpread++;
                  });
                } : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // ส่วนเนื้อหาหน้าต่างๆ (Content Pages)
  // ==========================================

  Widget _buildPage1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📖 คำจารึกจากผู้มาก่อน',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
            fontFamily: 'PixelArtFont',
          ),
        ),
        const Divider(color: Color(0xFFA1887F), thickness: 1, height: 12),
        _buildText(
          '"แด่ดวงจิตผู้มองเห็นความจริง... หากเจ้าอ่านอักขระเหล่านี้ออก แสดงว่าเจ้าคือผู้ถูกเลือกจาก MASTA\n\n'
          'โลกนี้กำลังป่วยหนัก สิ่งที่ประชากรดั้งเดิมหวาดกลัวและเทิดทูนว่าคือ \'เวทมนตร์\'... '
          'แท้จริงแล้วมันคือ \'สมการทางวิทยาศาสตร์\' ที่สูญเสียการควบคุมต่างหาก\n\n'
          'พวกมันใช้พลังงานโดยไม่เข้าใจหลักอุณหพลศาสตร์ บิดเบือนแรงโน้มถ่วงโดยไม่สนมวลของสสาร...\n\n'
          'จงใช้ความรู้ของเจ้า แก้ไขตัวแปรที่ผิดเพี้ยนเหล่านี้ และจงบันทึกความจริงลงในหน้ากระดาษที่เหลือ... ก่อนที่มิติแห่งนี้จะล่มสลาย"',
          italic: true,
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Container(
            margin: const EdgeInsets.only(top: 10),
            width: 20,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.brown.shade800.withOpacity(0.4),
              borderRadius: const BorderRadius.all(Radius.elliptical(20, 10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPage2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚔️ กฎแห่งการหักล้าง',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
            fontFamily: 'PixelArtFont',
          ),
        ),
        const Divider(color: Color(0xFFA1887F), thickness: 1, height: 12),
        
        Center(
          child: Container(
            padding: const EdgeInsets.all(4),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.brown.shade300, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department, color: Colors.red.shade400, size: 16),
                const Icon(Icons.arrow_right_alt, color: Colors.brown, size: 16),
                Icon(Icons.water_drop, color: Colors.blue.shade400, size: 16),
              ],
            ),
          ),
        ),
        
        _buildText('🔥 ธาตุไฟ (Ignis):', bold: true, color: Colors.red.shade900),
        _buildText('ปฏิกิริยาออกซิเดชันคายความร้อน\nจุดอ่อน: สารทำความเย็น (เคมี)'),
        const SizedBox(height: 6),
        
        _buildText('❄️ ธาตุน้ำ/น้ำแข็ง:', bold: true, color: Colors.blue.shade900),
        _buildText('พันธะไฮโดรเจนที่ผิดปกติ\nจุดอ่อน: เพิ่มพลังงานความร้อน (ฟิสิกส์)'),
        const SizedBox(height: 6),
        
        _buildText('💡 วิธีต่อสู้:', bold: true, color: Colors.brown.shade800),
        _buildText(
          'วิเคราะห์โครงสร้างของศัตรูเพื่อหาจุดอ่อนที่แท้จริง!',
          bold: true,
        ),
      ],
    );
  }

  Widget _buildPage3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📝 หน้ากระดาษที่ว่างเปล่า',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
            fontFamily: 'PixelArtFont',
          ),
        ),
        const Divider(color: Color(0xFFA1887F), thickness: 1, height: 12),
        const SizedBox(height: 8),
        
        _buildText(
          '(หน้าอื่นว่างเปล่าหมดเลย...)\n\n'
          '"อ๋อ เข้าใจล่ะ MASTA ถึงเรียกฉันว่า \'ผู้บันทึก\' สินะ ฉันต้องเป็นคนเขียนข้อมูลของโลกนี้ลงไปเอง!"',
          italic: true,
          color: Colors.brown.shade600,
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.brown.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.brown.shade200, style: BorderStyle.solid),
          ),
          child: _buildText(
            '[ระบบ Pokedex: ข้อมูลของศัตรูและไอเทมใหม่ๆ จะถูกบันทึกที่นี่]',
            fontSize: 9,
            color: Colors.grey.shade700,
          ),
        )
      ],
    );
  }

  Widget _buildBlankLines() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < 15; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 1,
              width: double.infinity,
              color: const Color(0xFFA1887F).withOpacity(0.5),
            ),
          ),
      ],
    );
  }

  Widget _buildText(String text, {bool bold = false, bool italic = false, Color? color, double fontSize = 10}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        height: 1.4,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        color: color ?? const Color(0xFF3E2723),
        fontFamily: 'PixelArtFont',
      ),
    );
  }

  // --- ส่วนของ Quest Log คงเดิม ---
  Widget _buildQuestLogContent() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFE8F5E8).withOpacity(0.95),
              const Color(0xFFF0F8FF).withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF4CAF50), width: 4),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 8)),
          ],
        ),
        child: const Center(child: Text("Quest Log UI")), 
      ),
    );
  }
}