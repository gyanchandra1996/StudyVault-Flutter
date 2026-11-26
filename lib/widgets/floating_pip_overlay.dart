import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pomodoro_provider.dart';
import '../services/pip_service.dart';

class FloatingPipOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback? onReturnFullScreen;
  final String currentSubject;

  const FloatingPipOverlay({
    Key? key,
    required this.onClose,
    this.onReturnFullScreen,
    this.currentSubject = 'Computer Science • Data Structures',
  }) : super(key: key);

  @override
  State<FloatingPipOverlay> createState() => _FloatingPipOverlayState();
}

class _FloatingPipOverlayState extends State<FloatingPipOverlay> {
  Offset _position = const Offset(16, 90);
  bool _isMinimized = false;

  @override
  Widget build(BuildContext context) {
    final pomodoro = Provider.of<PomodoroProvider>(context);
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final targetWidth = _isMinimized ? 96.0 : 250.0;
    final targetHeight = _isMinimized ? 76.0 : 160.0;

    return Positioned(
      left: _position.dx.clamp(8.0, (size.width - targetWidth - 8.0).clamp(8.0, size.width)),
      top: _position.dy.clamp(36.0, (size.height - targetHeight - 36.0).clamp(36.0, size.height)),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(16),
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
          child: Container(
            width: targetWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: _isMinimized
                  ? _buildMinimizedPill(pomodoro)
                  : _buildYouTubeStylePlayer(pomodoro),
            ),
          ),
        ),
      ),
    );
  }

  /// Compact mini-pill widget
  Widget _buildMinimizedPill(PomodoroProvider pomodoro) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.play_circle_fill, size: 14, color: Colors.redAccent),
              InkWell(
                onTap: () => setState(() => _isMinimized = false),
                child: const Icon(Icons.fullscreen, size: 16, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            pomodoro.formattedTime,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              fontFamily: 'monospace',
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () {
              if (pomodoro.isRunning) {
                pomodoro.pause();
              } else {
                pomodoro.start();
              }
            },
            child: Icon(
              pomodoro.isRunning ? Icons.pause_circle : Icons.play_circle,
              size: 24,
              color: const Color(0xFF38BDF8),
            ),
          ),
        ],
      ),
    );
  }

  /// YouTube-style PiP Player Floating Window
  Widget _buildYouTubeStylePlayer(PomodoroProvider pomodoro) {
    final totalSeconds = (pomodoro.isWorkMode ? pomodoro.workMinutes : pomodoro.breakMinutes) * 60;
    final progress = totalSeconds > 0
        ? ((totalSeconds - pomodoro.remainingSeconds) / totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Player Window Bar (Simulates YouTube Miniplayer top)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: Colors.black.withOpacity(0.35),
          child: Row(
            children: [
              // Red "LIVE / PIP" Badge like YouTube
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: pomodoro.isRunning ? Colors.red : Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pomodoro.isRunning) ...[
                      const CircleAvatar(radius: 2.5, backgroundColor: Colors.white),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      pomodoro.isRunning ? 'PiP LIVE' : 'PAUSED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.currentSubject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Android System Native PiP (Allows overlay over other apps)
              InkWell(
                onTap: () async {
                  final success = await PipService.enterPip();
                  if (!success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Native Android PiP is active or requires Android 8.0+'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: const Tooltip(
                  message: 'Enter System PiP (Stay over other apps)',
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.picture_in_picture_alt, size: 15, color: Color(0xFF60A5FA)),
                  ),
                ),
              ),
              // Minimize to pill
              InkWell(
                onTap: () => setState(() => _isMinimized = true),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.white70),
                ),
              ),
              // Close PiP
              InkWell(
                onTap: widget.onClose,
                child: const Padding(
                  padding: EdgeInsets.only(left: 3),
                  child: Icon(Icons.close, size: 16, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),

        // Video / Focus Area Viewport
        Container(
          height: 62,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              // Subtle background pulse icon
              Center(
                child: Icon(
                  pomodoro.isWorkMode ? Icons.school_rounded : Icons.coffee_rounded,
                  size: 42,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              // Timer and Mode Text
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pomodoro.formattedTime,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                    ),
                    Text(
                      pomodoro.isWorkMode ? 'Active Study Session' : 'Resting Break',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Progress Scrubber Bar (YouTube style red bar)
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withOpacity(0.12),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.redAccent),
          minHeight: 2.5,
        ),

        // Controls Bottom Bar: [Play/Pause, Fullscreen/Expand, Reset, Close]
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: Colors.black.withOpacity(0.2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Play / Pause Control
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  pomodoro.isRunning ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: Colors.white,
                  size: 26,
                ),
                tooltip: pomodoro.isRunning ? 'Pause' : 'Play',
                onPressed: () {
                  if (pomodoro.isRunning) {
                    pomodoro.pause();
                  } else {
                    pomodoro.start();
                  }
                },
              ),

              // 2. Return to Full Screen / Expand Control
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(
                  Icons.fullscreen,
                  color: Colors.white,
                  size: 24,
                ),
                tooltip: 'Return to Full Screen',
                onPressed: () {
                  if (widget.onReturnFullScreen != null) {
                    widget.onReturnFullScreen!();
                  } else {
                    widget.onClose();
                  }
                },
              ),

              // 3. Reset Timer Control
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: const Icon(
                  Icons.replay,
                  color: Colors.white70,
                  size: 19,
                ),
                tooltip: 'Restart Timer',
                onPressed: pomodoro.reset,
              ),

              // 4. Close PiP Control
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                tooltip: 'Close PiP',
                onPressed: widget.onClose,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
