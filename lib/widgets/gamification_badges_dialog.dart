import 'package:flutter/material.dart';
import '../models/gamification_data.dart';
import '../services/gamification_service.dart';

class GamificationBadgesDialog extends StatefulWidget {
  const GamificationBadgesDialog({Key? key}) : super(key: key);

  @override
  State<GamificationBadgesDialog> createState() => _GamificationBadgesDialogState();
}

class _GamificationBadgesDialogState extends State<GamificationBadgesDialog> {
  GamificationData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await GamificationService.getData();
    if (mounted) {
      setState(() {
        _data = d;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _data == null) {
      return const Dialog(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
    }

    final data = _data!;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Column(
          children: [
            // Header with flame gradient
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE65100), Color(0xFFFF9100)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_fire_department, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🔥 ${data.streakDays} Day Study Streak',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '${data.levelTitle} • Level ${data.level}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // XP & Level Progress Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.shade200.withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.bolt, color: Colors.amber, size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${data.totalXp} Total XP',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '+${data.todayXp} XP Today',
                                  style: TextStyle(
                                    color: Colors.orange.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: data.levelProgress,
                              minHeight: 10,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Level ${data.level}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              Text('${data.xpToNextLevel} XP to Level ${data.level + 1}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Badges Showcase Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '🏆 Study Badges & Trophies',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          '${data.unlockedBadges.length} / ${GamificationService.allBadges.length} Unlocked',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Badges Grid
                    ...GamificationService.allBadges.map((badge) {
                      final isUnlocked = data.unlockedBadges.contains(badge.id);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUnlocked ? badge.color.withOpacity(0.08) : Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isUnlocked ? badge.color.withOpacity(0.4) : Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isUnlocked ? badge.color.withOpacity(0.2) : Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                badge.icon,
                                color: isUnlocked ? badge.color : Colors.grey,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          badge.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isUnlocked ? null : Colors.grey,
                                          ),
                                        ),
                                      ),
                                      if (isUnlocked)
                                        const Icon(Icons.check_circle, color: Colors.green, size: 16)
                                      else
                                        const Icon(Icons.lock_outline, color: Colors.grey, size: 16),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    badge.description,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isUnlocked ? Colors.grey.shade700 : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 12),
                    // How to earn XP card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.blue.shade800),
                              const SizedBox(width: 6),
                              Text(
                                'How to Earn Daily XP & Keep Streak:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue.shade900),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '• 🎯 Solve an Exam Quiz: +20 XP\n'
                            '• 🧠 Train in Brain Games: +15 XP\n'
                            '• 📚 Review Flashcards: +10 XP\n'
                            '• 🍅 Complete Pomodoro block: +25 XP\n'
                            '• Open Medhavi daily to maintain your 🔥 Streak!',
                            style: TextStyle(fontSize: 11, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
