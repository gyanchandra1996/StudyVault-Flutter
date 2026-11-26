import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pomodoro_provider.dart';
import '../services/pip_service.dart';

class FloatingPipOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final String currentSubject;

  const FloatingPipOverlay({
    Key? key,
    required this.onClose,
    this.currentSubject = 'Computer Science',
  }) : super(key: key);

  @override
  State<FloatingPipOverlay> createState() => _FloatingPipOverlayState();
}

class _FloatingPipOverlayState extends State<FloatingPipOverlay> {
  Offset _position = const Offset(20, 100);
  bool _isMinimized = false;

  @override
  Widget build(BuildContext context) {
    final pomodoro = Provider.of<PomodoroProvider>(context);
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      left: _position.dx.clamp(10.0, size.width - (_isMinimized ? 90.0 : 230.0)),
      top: _position.dy.clamp(40.0, size.height - (_isMinimized ? 80.0 : 160.0)),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(16),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: Container(
            width: _isMinimized ? 80 : 220,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF2563EB).withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isMinimized
                ? _buildMinimizedContent(pomodoro)
                : _buildExpandedContent(pomodoro),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimizedContent(PomodoroProvider pomodoro) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.picture_in_picture_alt, size: 14, color: Color(0xFF2563EB)),
            InkWell(
              onTap: () => setState(() => _isMinimized = false),
              child: const Icon(Icons.open_in_full, size: 14, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          pomodoro.formattedTime,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2563EB),
          ),
        ),
        InkWell(
          onTap: () {
            if (pomodoro.isRunning) {
              pomodoro.pause();
            } else {
              pomodoro.start();
            }
          },
          child: Icon(
            pomodoro.isRunning ? Icons.pause_circle_filled : Icons.play_circle_filled,
            size: 22,
            color: const Color(0xFF2563EB),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent(PomodoroProvider pomodoro) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.picture_in_picture_alt, size: 14, color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Study PiP',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            // Native Android PiP trigger
            InkWell(
              onTap: () async {
                final ok = await PipService.enterPip();
                if (!ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Android native PiP triggered or supported on Android 8+'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Tooltip(
                message: 'Android System PiP',
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.launch, size: 14, color: Color(0xFF2563EB)),
                ),
              ),
            ),
            InkWell(
              onTap: () => setState(() => _isMinimized = true),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.close_fullscreen, size: 14, color: Colors.grey),
              ),
            ),
            InkWell(
              onTap: widget.onClose,
              child: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.close, size: 16, color: Colors.redAccent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Subject Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.currentSubject,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
          ),
        ),
        const SizedBox(height: 6),

        // Timer Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              pomodoro.formattedTime,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
            Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: Icon(
                    pomodoro.isRunning ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: const Color(0xFF2563EB),
                    size: 26,
                  ),
                  onPressed: () {
                    if (pomodoro.isRunning) {
                      pomodoro.pause();
                    } else {
                      pomodoro.start();
                    }
                  },
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  icon: const Icon(Icons.refresh, size: 18, color: Colors.grey),
                  onPressed: pomodoro.reset,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
