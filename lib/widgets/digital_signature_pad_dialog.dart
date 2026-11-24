import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:open_file/open_file.dart';

class DigitalSignaturePadDialog extends StatefulWidget {
  const DigitalSignaturePadDialog({Key? key}) : super(key: key);

  @override
  State<DigitalSignaturePadDialog> createState() => _DigitalSignaturePadDialogState();
}

class _DigitalSignaturePadDialogState extends State<DigitalSignaturePadDialog> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  Color _inkColor = Colors.black;
  double _strokeWidth = 3.0;
  bool _whiteBackground = true;
  bool _isSaving = false;

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentStroke = [details.localPosition];
      _strokes.add(_currentStroke);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentStroke.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // Current stroke finished
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
    });
  }

  Future<void> _exportSignature() async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw your signature first on the pad.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Standard signature dimensions for SSC / UPSC: 320 x 140 px
      const width = 320.0;
      const height = 140.0;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));

      if (_whiteBackground) {
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, width, height),
          Paint()..color = Colors.white,
        );
      }

      // Compute bounding box of drawing to center it
      double minX = double.infinity, minY = double.infinity;
      double maxX = double.negativeInfinity, maxY = double.negativeInfinity;

      for (final stroke in _strokes) {
        for (final pt in stroke) {
          if (pt.dx < minX) minX = pt.dx;
          if (pt.dy < minY) minY = pt.dy;
          if (pt.dx > maxX) maxX = pt.dx;
          if (pt.dy > maxY) maxY = pt.dy;
        }
      }

      final drawW = (maxX - minX).clamp(1.0, 1000.0);
      final drawH = (maxY - minY).clamp(1.0, 1000.0);

      // Scale to fit comfortably inside 320x140 with padding
      const pad = 16.0;
      final availW = width - pad * 2;
      final availH = height - pad * 2;
      final scale = (availW / drawW).clamp(0.1, availH / drawH);

      final transX = (width - drawW * scale) / 2 - minX * scale;
      final transY = (height - drawH * scale) / 2 - minY * scale;

      canvas.save();
      canvas.translate(transX, transY);
      canvas.scale(scale);

      final paint = Paint()
        ..color = _inkColor
        ..strokeWidth = _strokeWidth / scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (final stroke in _strokes) {
        if (stroke.length > 1) {
          final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
          for (int i = 1; i < stroke.length; i++) {
            path.lineTo(stroke[i].dx, stroke[i].dy);
          }
          canvas.drawPath(path, paint);
        } else if (stroke.isNotEmpty) {
          canvas.drawCircle(stroke.first, (_strokeWidth / scale) / 2, paint..style = PaintingStyle.fill);
          paint.style = PaintingStyle.stroke;
        }
      }
      canvas.restore();

      // Border line
      if (_whiteBackground) {
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, width, height),
          Paint()
            ..color = Colors.grey.shade400
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Signature encoding failed');

      final finalBytes = byteData.buffer.asUint8List();
      final sizeKb = (finalBytes.length / 1024).round();

      final tempDir = await getTemporaryDirectory();
      final filename = 'signature_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(p.join(tempDir.path, filename));
      await file.writeAsBytes(finalBytes);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signature saved: $filename ($sizeKb KB - Govt standard 10–20 KB)'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () => OpenFile.open(file.path),
            ),
          ),
        );
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting signature: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 660),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: BoxDecoration(
                color: Colors.indigo.shade700,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.gesture_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Digital Signature Pad', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Sign with finger / stylus • Auto 10–20 KB format for SSC / UPSC', style: TextStyle(color: Colors.white70, fontSize: 11)),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Drawing Canvas Pad
                    Container(
                      width: double.infinity,
                      height: 190,
                      decoration: BoxDecoration(
                        color: _whiteBackground ? Colors.white : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.indigo.shade300, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: GestureDetector(
                              onPanStart: _onPanStart,
                              onPanUpdate: _onPanUpdate,
                              onPanEnd: _onPanEnd,
                              child: CustomPaint(
                                painter: _SignaturePainter(_strokes, _inkColor, _strokeWidth),
                                child: Container(color: Colors.transparent),
                              ),
                            ),
                          ),
                          if (_strokes.isEmpty)
                            const Center(
                              child: Text(
                                'Sign Here with Finger or Stylus\n(यहाँ उंगली से हस्ताक्षर करें)',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                              ),
                            ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              tooltip: 'Clear Pad',
                              onPressed: _strokes.isEmpty ? null : _clear,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Controls Row: Ink Color & Width
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Ink Color:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Row(
                          children: [
                            _buildColorChip('Black', Colors.black),
                            const SizedBox(width: 8),
                            _buildColorChip('Royal Blue', const Color(0xFF1E3A8A)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Stroke Thickness:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Fine'),
                              selected: _strokeWidth == 2.0,
                              onSelected: (_) => setState(() => _strokeWidth = 2.0),
                            ),
                            const SizedBox(width: 6),
                            ChoiceChip(
                              label: const Text('Normal'),
                              selected: _strokeWidth == 3.0,
                              onSelected: (_) => setState(() => _strokeWidth = 3.0),
                            ),
                            const SizedBox(width: 6),
                            ChoiceChip(
                              label: const Text('Bold'),
                              selected: _strokeWidth == 4.5,
                              onSelected: (_) => setState(() => _strokeWidth = 4.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Pure White Background', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Required by SSC, UPSC & IBPS forms (no transparency)', style: TextStyle(fontSize: 11)),
                      value: _whiteBackground,
                      onChanged: (val) => setState(() => _whiteBackground = val),
                    ),

                    const Spacer(),

                    Row(
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Clear'),
                          onPressed: _clear,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: _isSaving
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.download_rounded),
                            label: const Text('Save 10-20 KB Signature', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: (_strokes.isEmpty || _isSaving) ? null : _exportSignature,
                          ),
                        ),
                      ],
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

  Widget _buildColorChip(String label, Color col) {
    final isSel = _inkColor == col;
    return InkWell(
      onTap: () => setState(() => _inkColor = col),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSel ? col.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSel ? col : Colors.grey.shade300, width: isSel ? 2 : 1),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 6, backgroundColor: col),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSel ? col : Colors.black87)),
          ],
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color color;
  final double strokeWidth;

  _SignaturePainter(this.strokes, this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length > 1) {
        final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, paint);
      } else if (stroke.isNotEmpty) {
        canvas.drawCircle(stroke.first, strokeWidth / 2, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
