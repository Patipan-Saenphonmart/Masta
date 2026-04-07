import 'package:flutter/material.dart';
import '../../data/game_data.dart';
import '../main_game.dart';

class QuestOverlay extends StatelessWidget {
  final RabbitGame game;
  const QuestOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      top: 100, // ต่ำลงมาจาก HP Bar
      child: ValueListenableBuilder<int>(
        valueListenable: GameData.questUpdateNotifier,
        builder: (context, _, child) {
          final activeQuests = GameData.activeQuests.where((q) => !q.isCompleted).toList();
          if (activeQuests.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: activeQuests.map((quest) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                width: 180,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xCC3E2723), Color(0xCC5D4037)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD7CCC8).withOpacity(0.5), width: 1.5),
                  boxShadow: const [BoxShadow(color: Colors.black45, offset: Offset(0, 4), blurRadius: 4)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            quest.title,
                            style: const TextStyle(
                              color: Color(0xFFFFECB3),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              fontFamily: 'Comic Sans MS',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      quest.description,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: quest.currentCount / quest.targetCount,
                        backgroundColor: Colors.black54,
                        color: Colors.greenAccent,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${quest.currentCount} / ${quest.targetCount}",
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "รางวัล: ${quest.rewardGold}G",
                          style: const TextStyle(color: Colors.amberAccent, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
