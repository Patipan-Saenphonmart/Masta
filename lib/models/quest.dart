class Quest {
  final String id;
  final String title;
  final String description;
  final String targetAction; // e.g. 'kill_monster', 'answer_correct'
  final int targetCount;
  int currentCount;
  bool isCompleted;
  
  final int rewardGold;
  final int rewardExp;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.targetAction,
    required this.targetCount,
    this.currentCount = 0,
    this.isCompleted = false,
    this.rewardGold = 0,
    this.rewardExp = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetAction': targetAction,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'isCompleted': isCompleted,
      'rewardGold': rewardGold,
      'rewardExp': rewardExp,
    };
  }

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      targetAction: json['targetAction'],
      targetCount: json['targetCount'],
      currentCount: json['currentCount'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
      rewardGold: json['rewardGold'] ?? 0,
      rewardExp: json['rewardExp'] ?? 0,
    );
  }
}
