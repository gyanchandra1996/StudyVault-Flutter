import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/pomodoro_provider.dart';
import '../services/pip_service.dart';
import '../widgets/pomodoro_widget.dart';
import '../widgets/pomodoro_settings_sheet.dart';
import '../widgets/quick_revision_handbook_modal.dart';
import '../widgets/syllabus_tracker_modal.dart';
import '../widgets/exam_analytics_modal.dart';
import '../widgets/backup_restore_modal.dart';
import 'document_vault_screen.dart';
import 'brain_games/brain_games_hub_screen.dart';
import 'flashcards_screen.dart';
import 'tools_hub_screen.dart';
import 'camera_to_pdf_screen.dart';
import 'notes_screen.dart';

class UtilityHubScreen extends StatefulWidget {
  final VoidCallback? onTriggerPip;

  const UtilityHubScreen({Key? key, this.onTriggerPip}) : super(key: key);

  @override
  State<UtilityHubScreen> createState() => _UtilityHubScreenState();
}

class _UtilityHubScreenState extends State<UtilityHubScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final settings = Provider.of<SettingsProvider>(context);
    final pomodoro = Provider.of<PomodoroProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const primaryBlue = Color(0xFF1E3A8A);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: const Text('DigiLocker Utility Suite', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0.5,
        actions: [
          // PiP trigger in AppBar
          IconButton(
            icon: const Icon(Icons.picture_in_picture_alt, color: primaryBlue),
            tooltip: 'Picture in Picture Timer',
            onPressed: () {
              if (widget.onTriggerPip != null) {
                widget.onTriggerPip!();
              } else {
                PipService.enterPip();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pomodoro Focus Timer with PiP Quick Trigger
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: Colors.blue.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.timer, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Study Focus Timer (PiP)',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Current: ${pomodoro.formattedTime} • ${pomodoro.isWorkMode ? "Focus Mode" : "Break Time"}',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: primaryBlue,
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: Icon(pomodoro.isRunning ? Icons.pause : Icons.play_arrow, size: 16),
                              label: Text(pomodoro.isRunning ? 'Pause' : 'Start Focus'),
                              onPressed: () {
                                if (pomodoro.isRunning) {
                                  pomodoro.pause();
                                } else {
                                  pomodoro.start();
                                }
                              },
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white70),
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.picture_in_picture_alt, size: 16),
                              label: const Text('Floating PiP'),
                              onPressed: () {
                                if (widget.onTriggerPip != null) {
                                  widget.onTriggerPip!();
                                } else {
                                  PipService.enterPip();
                                }
                              },
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white70),
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.tune, size: 16),
                              label: const Text('Set Timer'),
                              onPressed: () => showPomodoroSettingsModal(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section: Core Utilities (Vault, Games, Flashcards)
            const Text(
              'Essential Study Utilities',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 10),

            _buildBigUtilityTile(
              icon: Icons.shield,
              color: Colors.deepOrange,
              title: 'DigiLocker ID Vault',
              subtitle: 'Securely store Aadhaar, PAN Card, Admit Cards & Exam Certificates with PIN lock',
              badge: 'SECURE VAULT',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DocumentVaultScreen()),
                );
              },
            ),
            const SizedBox(height: 10),

            _buildBigUtilityTile(
              icon: Icons.psychology_rounded,
              color: Colors.amber.shade800,
              title: 'Brain Games & Mental Focus',
              subtitle: 'Speed Math, Schulte Grid, Memory Match, Stroop Reflex, Word Scramble & Number Logic',
              badge: '6 GAMES',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BrainGamesHubScreen()),
                );
              },
            ),
            const SizedBox(height: 10),

            _buildBigUtilityTile(
              icon: Icons.style,
              color: Colors.purple,
              title: 'Spaced Memory Flashcards',
              subtitle: 'Leitner system flashcards for formulas, vocab, articles & short revisions',
              badge: 'LEITNER MEMORY',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FlashcardsScreen()),
                );
              },
            ),

            const SizedBox(height: 20),

            // Section: Document & Exam Tools (DigiLocker 3-Column Square Cards)
            const Text(
              'Document, Photo & Study Utilities',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 10),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.88,
              children: [
                _buildSmallToolCard(
                  icon: Icons.handyman_outlined,
                  color: Colors.teal,
                  title: 'PDF Tools Hub',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ToolsHubScreen()),
                    );
                  },
                ),
                _buildSmallToolCard(
                  icon: Icons.portrait_rounded,
                  color: Colors.blue,
                  title: 'Passport Photo Maker',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ToolsHubScreen()),
                    );
                  },
                ),
                _buildSmallToolCard(
                  icon: Icons.camera_alt_outlined,
                  color: Colors.indigo,
                  title: 'Camera to PDF',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CameraToPdfScreen()),
                    );
                  },
                ),
                _buildSmallToolCard(
                  icon: Icons.gesture,
                  color: Colors.deepPurple,
                  title: 'Digital Sign Pad',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ToolsHubScreen()),
                    );
                  },
                ),
                _buildSmallToolCard(
                  icon: Icons.photo_size_select_large,
                  color: Colors.cyan.shade700,
                  title: 'Image Resizer & Compress',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ToolsHubScreen()),
                    );
                  },
                ),
                _buildSmallToolCard(
                  icon: Icons.auto_fix_high_rounded,
                  color: Colors.pink,
                  title: 'BG Remover & Replacer',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ToolsHubScreen()),
                    );
                  },
                ),
                _buildSmallToolCard(
                  icon: Icons.auto_awesome,
                  color: Colors.amber.shade900,
                  title: 'AI Notes to PDF',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ToolsHubScreen()),
                    );
                  },
                ),
                _buildSmallToolCard(
                  icon: Icons.auto_stories,
                  color: Colors.purple,
                  title: 'Quick Revision Handbook',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const QuickRevisionHandbookModal(),
                    );
                  },
                ),
                _buildSmallToolCard(
                  icon: Icons.checklist_rtl_rounded,
                  color: Colors.green,
                  title: 'Syllabus Tracker',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const SyllabusTrackerModal(),
                    );
                  },
                ),
                _buildSmallToolCard(
                  icon: Icons.analytics_outlined,
                  color: Colors.deepOrange,
                  title: 'Exam Analytics',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const ExamAnalyticsModal(),
                    );
                  },
                ),
                _buildSmallToolCard(
                  icon: Icons.edit_note_rounded,
                  color: Colors.blueGrey,
                  title: 'Study Notes & Points',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotesScreen()),
                    );
                  },
                ),
                _buildSmallToolCard(
                  icon: Icons.cloud_sync_outlined,
                  color: const Color(0xFF1E3A8A),
                  title: 'Backup & Restore',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const BackupRestoreModal(),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBigUtilityTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25), width: 1.2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
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
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallToolCard({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  height: 1.2,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
