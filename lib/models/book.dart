class Book {
  final String id;
  final String title;
  final String description;
  final String content;
  final String spritePath;
  final bool isQuestLog;
  final List<String> tags;

  Book({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.spritePath,
    this.isQuestLog = false,
    this.tags = const [],
  });

  factory Book.questLog() {
    return Book(
      id: 'quest_log_book',
      title: 'หนังสือบันทึกโจทย์',
      description: 'บันทึกคำถามและคำตอบที่คุณได้ตอบถูกต้อง',
      content: 'บันทึกโจทย์ที่ผ่านมา',
      spritePath: 'assets/images/book_quest_log.png',
      isQuestLog: true,
      tags: ['Book', 'Quest', 'Log'],
    );
  }

  factory Book.regular({
    required String id,
    required String title,
    required String description,
    required String content,
    String spritePath = 'assets/images/book_regular.png',
  }) {
    return Book(
      id: id,
      title: title,
      description: description,
      content: content,
      spritePath: spritePath,
      tags: ['Book'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'spritePath': spritePath,
      'isQuestLog': isQuestLog,
      'tags': tags,
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      content: json['content'],
      spritePath: json['spritePath'] ?? 'assets/images/book_regular.png',
      isQuestLog: json['isQuestLog'] ?? false,
      tags: List<String>.from(json['tags'] ?? ['Book']),
    );
  }

  bool isBook() {
    return tags.contains('Book');
  }
}
