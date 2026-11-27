import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/reading_repo.dart';
import '../database/pdf_repo.dart';
import '../models/pdf_document.dart';
import '../providers/settings_provider.dart';
import '../screens/pdf_reader_screen.dart';

class ReadingTrackerCard extends StatefulWidget {
  final int refreshSignal;

  const ReadingTrackerCard({
    Key? key,
    this.refreshSignal = 0,
  }) : super(key: key);

  @override
  State<ReadingTrackerCard> createState() => _ReadingTrackerCardState();
}

class _ReadingTrackerCardState extends State<ReadingTrackerCard> with AutomaticKeepAliveClientMixin {
  final ReadingRepo _readingRepo = ReadingRepo();
  final PdfRepo _pdfRepo = PdfRepo();

  @override
  bool get wantKeepAlive => true;

  int _streakDays = 0;
  int _todayMinutes = 0;
  List<Map<String, dynamic>> _weekData = [];
  PdfDocument? _recentPdf;
  int? _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    ReadingRepo.changes.addListener(_onReadingLogChanged);
    _loadTrackerData();
  }

  @override
  void dispose() {
    ReadingRepo.changes.removeListener(_onReadingLogChanged);
    super.dispose();
  }

  void _onReadingLogChanged() {
    if (mounted) {
      _loadTrackerData();
    }
  }

  @override
  void didUpdateWidget(covariant ReadingTrackerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      _loadTrackerData();
    }
  }

  Future<void> _loadTrackerData() async {
    final results = await Future.wait([
      _readingRepo.getReadingStreakDays(),
      _readingRepo.getTodayReadingMinutes(),
      _readingRepo.getWeeklyActivity(),
      _pdfRepo.getRecentPdfs(limit: 1),
    ]);

    if (mounted) {
      final recentList = results[3] as List<PdfDocument>;
      setState(() {
        _streakDays = results[0] as int;
        _todayMinutes = results[1] as int;
        _weekData = results[2] as List<Map<String, dynamic>>;
        _recentPdf = recentList.isNotEmpty ? recentList.first : null;
      });
    }
  }

  void _handleChartTap(Offset localPos, double width) {
    if (_weekData.isEmpty) return;
    final n = _weekData.length;
    if (n == 0) return;

    const double leftPad = 36.0;
    const double rightPad = 14.0;
    final double chartW = math.max(10.0, width - leftPad - rightPad);

    int nearest = 0;
    double bestDist = double.infinity;
    for (int i = 0; i < n; i++) {
      final double x = n == 1 ? leftPad + chartW / 2 : leftPad + (chartW * i / (n - 1));
      final dist = (localPos.dx - x).abs();
      if (dist < bestDist) {
        bestDist = dist;
        nearest = i;
      }
    }

    setState(() {
      _selectedDayIndex = _selectedDayIndex == nearest ? null : nearest;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final accent = context.select<SettingsProvider, Color>((s) => s.activeAccentColor);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final int totalWeekMinutes = _weekData.fold<int>(
      0,
      (sum, d) => sum + ((d['minutes'] as int?) ?? 0),
    );
    final int avgDailyMinutes = _weekData.isNotEmpty ? (totalWeekMinutes / _weekData.length).round() : 0;

    final int? safeSelected = (_selectedDayIndex != null && _selectedDayIndex! < _weekData.length)
        ? _selectedDayIndex
        : null;
    final Map<String, dynamic>? selectedDay = safeSelected != null ? _weekData[safeSelected] : null;

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          // 7-Day Weekly Report Line Chart Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.show_chart_rounded, size: 16, color: accent),
                          ),
                          const SizedBox(width: 8),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Weekly Reading Report',
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Last 7 Days Trend • Tap point for details',
                                style: TextStyle(fontSize: 10.5, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          selectedDay != null
                              ? '${selectedDay['day']}: ${selectedDay['minutes'] ?? 0}m'
                              : '${totalWeekMinutes}m total',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Summary Metrics Row
                  Row(
                    children: [
                      _buildMiniMetric('Today', '${_todayMinutes}m', accent),
                      const SizedBox(width: 8),
                      _buildMiniMetric('Daily Avg', '${avgDailyMinutes}m', Colors.teal),
                      const SizedBox(width: 8),
                      _buildMiniMetric('Streak', '${_streakDays}d', Colors.deepOrange),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Animated Interactive Line Chart Canvas
                  SizedBox(
                    width: double.infinity,
                    height: 148,
                    child: _weekData.isEmpty
                        ? const Center(
                            child: Text(
                              'Start reading to see your weekly chart',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (ctx, constraints) {
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapDown: (details) => _handleChartTap(
                                  details.localPosition,
                                  constraints.maxWidth,
                                ),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOutCubic,
                                  builder: (ctx, animValue, _) {
                                    return CustomPaint(
                                      size: Size(constraints.maxWidth, 148),
                                      painter: WeeklyLineChartPainter(
                                        weekData: _weekData,
                                        accentColor: accent,
                                        isDark: isDark,
                                        selectedIndex: safeSelected,
                                        animProgress: animValue,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$label: ',
              style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class WeeklyLineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> weekData;
  final Color accentColor;
  final bool isDark;
  final int? selectedIndex;
  final double animProgress;

  const WeeklyLineChartPainter({
    required this.weekData,
    required this.accentColor,
    required this.isDark,
    this.selectedIndex,
    this.animProgress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weekData.isEmpty) return;

    final List<int> values = weekData.map((d) => (d['minutes'] as int?) ?? 0).toList();
    final int rawMax = values.fold<int>(0, (m, v) => v > m ? v : m);
    final int maxScale = rawMax <= 30
        ? 30
        : (((rawMax + 14) ~/ 15) * 15);

    final gridColor = (isDark ? Colors.white : Colors.grey).withOpacity(0.18);
    final labelColor = isDark ? Colors.white60 : Colors.grey.shade600;

    // Measure max Y-axis label width dynamically so 3-4 digit numbers never clip
    final yTicks = [0, (maxScale / 2).round(), maxScale];
    double maxTickW = 0;
    final tickPainters = <int, TextPainter>{};
    for (final tick in yTicks) {
      final tp = TextPainter(
        text: TextSpan(
          text: '${tick}m',
          style: TextStyle(fontSize: 9.5, color: labelColor, fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tickPainters[tick] = tp;
      if (tp.width > maxTickW) maxTickW = tp.width;
    }

    final double leftPad = math.max(34.0, maxTickW + 10.0);
    const double rightPad = 16.0;
    const double topPad = 20.0;
    const double bottomPad = 24.0;

    final double chartW = math.max(10.0, size.width - leftPad - rightPad);
    final double chartH = math.max(10.0, size.height - topPad - bottomPad);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    for (final tick in yTicks) {
      final ratio = tick / maxScale;
      final y = topPad + chartH * (1.0 - ratio);

      const dashW = 4.0;
      const gapW = 4.0;
      double startX = leftPad;
      while (startX < leftPad + chartW) {
        final endX = math.min(startX + dashW, leftPad + chartW);
        canvas.drawLine(Offset(startX, y), Offset(endX, y), gridPaint);
        startX += dashW + gapW;
      }

      final tp = tickPainters[tick]!;
      tp.paint(canvas, Offset(leftPad - tp.width - 6, y - tp.height / 2));
    }

    // Compute (x, y) coordinates with smooth vertical growth animation
    final int n = weekData.length;
    final double baselineY = topPad + chartH;
    final List<Offset> points = [];
    for (int i = 0; i < n; i++) {
      final double x = n == 1
          ? leftPad + chartW / 2
          : leftPad + (chartW * i / (n - 1));
      final double ratio = ((values[i] / maxScale) * animProgress).clamp(0.0, 1.0);
      final double y = baselineY - chartH * ratio;
      points.add(Offset(x, y));
    }

    // Build smooth horizontal-tangent cubic path
    final Path linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    // Gradient fill beneath the line
    final Path fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, baselineY)
      ..lineTo(points.first.dx, baselineY)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withOpacity(0.28),
          accentColor.withOpacity(0.02),
        ],
      ).createShader(Rect.fromLTWH(leftPad, topPad, chartW, chartH));

    canvas.drawPath(fillPath, fillPaint);

    // Draw selected vertical guide line
    if (selectedIndex != null && selectedIndex! >= 0 && selectedIndex! < points.length) {
      final selPt = points[selectedIndex!];
      canvas.drawLine(
        Offset(selPt.dx, topPad),
        Offset(selPt.dx, baselineY),
        Paint()
          ..color = accentColor.withOpacity(0.4)
          ..strokeWidth = 1.4,
      );
    }

    // Draw line stroke
    final linePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // Draw points, value labels, and X-axis day labels
    for (int i = 0; i < n; i++) {
      final pt = points[i];
      final mins = values[i];
      final dayLabel = (weekData[i]['day'] as String?) ?? '';
      final isToday = (weekData[i]['isToday'] as bool?) ?? false;
      final isSelected = selectedIndex == i;

      if (isSelected || isToday) {
        canvas.drawCircle(pt, isSelected ? 10.0 : 8.5, Paint()..color = accentColor.withOpacity(0.22));
        canvas.drawCircle(pt, isSelected ? 5.5 : 4.8, Paint()..color = accentColor);
        canvas.drawCircle(pt, 2.2, Paint()..color = Colors.white);
      } else {
        canvas.drawCircle(pt, 4.0, Paint()..color = isDark ? const Color(0xFF1E293B) : Colors.white);
        canvas.drawCircle(
          pt,
          4.0,
          Paint()
            ..color = accentColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
      }

      // Value label above point (clamped cleanly inside canvas bounds)
      if (mins > 0 || isToday || isSelected) {
        final valTp = TextPainter(
          text: TextSpan(
            text: '${mins}m',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: (isToday || isSelected) ? FontWeight.bold : FontWeight.w600,
              color: (isToday || isSelected) ? accentColor : labelColor,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final double vx = (pt.dx - valTp.width / 2).clamp(leftPad, math.max(leftPad, size.width - valTp.width - 2));
        final double vy = (pt.dy - valTp.height - 7).clamp(0.0, math.max(0.0, baselineY - valTp.height));
        valTp.paint(canvas, Offset(vx, vy));
      }

      // Day label below X-axis
      final dayTp = TextPainter(
        text: TextSpan(
          text: dayLabel,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: (isToday || isSelected) ? FontWeight.bold : FontWeight.w500,
            color: (isToday || isSelected) ? accentColor : labelColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final double dx = (pt.dx - dayTp.width / 2).clamp(2.0, math.max(2.0, size.width - dayTp.width - 2));
      dayTp.paint(canvas, Offset(dx, baselineY + 7));
    }
  }

  @override
  bool shouldRepaint(covariant WeeklyLineChartPainter oldDelegate) {
    if (oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.animProgress != animProgress ||
        oldDelegate.weekData.length != weekData.length) {
      return true;
    }
    for (int i = 0; i < weekData.length; i++) {
      if (oldDelegate.weekData[i]['minutes'] != weekData[i]['minutes'] ||
          oldDelegate.weekData[i]['day'] != weekData[i]['day'] ||
          oldDelegate.weekData[i]['isToday'] != weekData[i]['isToday']) {
        return true;
      }
    }
    return false;
  }
}
