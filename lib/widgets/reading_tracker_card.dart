import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/reading_repo.dart';
import '../database/pdf_repo.dart';
import '../models/pdf_document.dart';
import '../providers/settings_provider.dart';
import '../screens/pdf_reader_screen.dart';

class ReadingTrackerCard extends StatefulWidget {
  const ReadingTrackerCard({Key? key}) : super(key: key);

  @override
  State<ReadingTrackerCard> createState() => _ReadingTrackerCardState();
}

class _ReadingTrackerCardState extends State<ReadingTrackerCard> {
  final ReadingRepo _readingRepo = ReadingRepo();
  final PdfRepo _pdfRepo = PdfRepo();

  int _streakDays = 0;
  int _todayMinutes = 0;
  List<Map<String, dynamic>> _weekData = [];
  PdfDocument? _recentPdf;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrackerData();
  }

  Future<void> _loadTrackerData() async {
    setState(() => _isLoading = true);
    final streak = await _readingRepo.getReadingStreakDays();
    final todayMins = await _readingRepo.getTodayReadingMinutes();
    final week = await _readingRepo.getWeeklyActivity();
    final recentList = await _pdfRepo.getRecentPdfs(limit: 1);

    setState(() {
      _streakDays = streak;
      _todayMinutes = todayMins;
      _weekData = week;
      _recentPdf = recentList.isNotEmpty ? recentList.first : null;
      _isLoading = false;
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning, Scholar 🌅';
    if (hour < 17) return 'Good Afternoon, Scholar ☀️';
    return 'Good Evening, Scholar 🌙';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
    }

    final settings = Provider.of<SettingsProvider>(context);
    final accent = settings.activeAccentColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Greeting Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent,
                accent.withOpacity(0.75),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.3),
                blurRadius: 12,
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
                  Text(
                    _getGreeting(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥 ', style: TextStyle(fontSize: 13)),
                        Text(
                          '$_streakDays ${_streakDays == 1 ? "Day" : "Days"} Streak',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _todayMinutes == 0
                        ? 'Ready for today’s session? Start reading below!'
                        : '$_todayMinutes mins studied today. Keep the momentum!',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Currently Reading Hero Card
        if (_recentPdf != null) ...[
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PdfReaderScreen(pdf: _recentPdf!)),
                );
                _loadTrackerData();
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Circular Progress
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 54,
                          height: 54,
                          child: CircularProgressIndicator(
                            value: _recentPdf!.totalPages > 0
                                ? (_recentPdf!.lastPage / _recentPdf!.totalPages).clamp(0.0, 1.0)
                                : 0.0,
                            strokeWidth: 5,
                            backgroundColor: accent.withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(accent),
                          ),
                        ),
                        Text(
                          '${_recentPdf!.totalPages > 0 ? ((_recentPdf!.lastPage / _recentPdf!.totalPages) * 100).round() : 0}%',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CURRENTLY READING',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _recentPdf!.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Page ${_recentPdf!.lastPage} of ${_recentPdf!.totalPages}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PdfReaderScreen(pdf: _recentPdf!)),
                        );
                        _loadTrackerData();
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Resume'),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 7-Day Activity Mini-Bar Chart
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Weekly Reading Activity',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Last 7 Days',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _weekData.map((day) {
                    final mins = day['minutes'] as int;
                    final isToday = day['isToday'] as bool;
                    final heightFactor = mins > 0 ? (mins / 60).clamp(0.2, 1.0) * 50.0 : 6.0;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          mins > 0 ? '${mins}m' : '',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday ? accent : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 18,
                          height: heightFactor,
                          decoration: BoxDecoration(
                            color: isToday
                                ? accent
                                : mins > 0
                                    ? accent.withOpacity(0.4)
                                    : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          day['day'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday ? accent : Colors.grey,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
