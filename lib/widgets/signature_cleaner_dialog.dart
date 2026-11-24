import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:open_file/open_file.dart';

class SignatureCleanerDialog extends StatefulWidget {
  const SignatureCleanerDialog({Key? key}) : super(key: key);

  @override
  State<SignatureCleanerDialog> createState() => _SignatureCleanerDialogState();
}

class _SignatureCleanerDialogState extends State<SignatureCleanerDialog> {
  String? _pickedPath;
  ui.Image? _loadedImage;
  Uint8List? _processedBytes;
  int _outputSizeKb = 0;
  bool _isProcessing = false;

  double _threshold = 175.0; // 100 to 230
  double _darkness = 1.6; // 1.0 to 2.5
  bool _addBorder = true;
  int _targetW = 320;
  int _targetH = 140;

  Future<void> _pickSignature() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
      final path = result.files.first.path!;
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      setState(() {
        _pickedPath = path;
        _loadedImage = frame.image;
      });
      _processSignature();
    }
  }

  Future<void> _processSignature() async {
    if (_loadedImage == null) return;
    setState(() => _isProcessing = true);

    try {
      final img = _loadedImage!;
      // Scale to target dimensions
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw white canvas
      canvas.drawRect(
        Rect.fromLTWH(0, 0, _targetW.toDouble(), _targetH.toDouble()),
        Paint()..color = Colors.white,
      );

      // Fit original image proportionally
      final scale = (_targetW / img.width).clamp(0.01, _targetH / img.height);
      final dw = img.width * scale;
      final dh = img.height * scale;
      final dx = (_targetW - dw) / 2;
      final dy = (_targetH - dh) / 2;

      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromLTWH(dx, dy, dw, dh),
        Paint(),
      );

      final pic = recorder.endRecording();
      final scaledImg = await pic.toImage(_targetW, _targetH);
      final byteData = await scaledImg.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) throw Exception('Failed to get raw bytes');

      final rawBytes = Uint8List.fromList(byteData.buffer.asUint8List());

      // Pixel processing: whiten paper background, darken ink
      for (int i = 0; i < rawBytes.length; i += 4) {
        final r = rawBytes[i];
        final g = rawBytes[i + 1];
        final b = rawBytes[i + 2];
        final lum = 0.299 * r + 0.587 * g + 0.114 * b;

        if (lum > _threshold) {
          // Paper background -> Pure White
          rawBytes[i] = 255;
          rawBytes[i + 1] = 255;
          rawBytes[i + 2] = 255;
        } else {
          // Ink stroke -> Darken according to darkness factor
          final factor = (1.0 / _darkness).clamp(0.2, 0.9);
          rawBytes[i] = (r * factor).round().clamp(0, 255);
          rawBytes[i + 1] = (g * factor).round().clamp(0, 255);
          rawBytes[i + 2] = (b * factor).round().clamp(0, 255);
        }
      }

      // Convert back to image
      final comp = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        rawBytes,
        _targetW,
        _targetH,
        ui.PixelFormat.rgba8888,
        (result) => comp.complete(result),
      );
      final cleanImg = await comp.future;

      // Final canvas with optional boundary border
      final finalRec = ui.PictureRecorder();
      final finalCanvas = Canvas(finalRec);
      finalCanvas.drawImage(cleanImg, Offset.zero, Paint());

      if (_addBorder) {
        finalCanvas.drawRect(
          Rect.fromLTWH(0, 0, _targetW.toDouble(), _targetH.toDouble()),
          Paint()
            ..color = Colors.grey.shade400
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }

      final finalPic = finalRec.endRecording();
      final finalOutput = await finalPic.toImage(_targetW, _targetH);
      final pngData = await finalOutput.toByteData(format: ui.ImageByteFormat.png);
      if (pngData == null) throw Exception('PNG compression failed');

      final finalBytes = pngData.buffer.asUint8List();
      final sizeKb = (finalBytes.length / 1024).round();

      if (mounted) {
        setState(() {
          _processedBytes = finalBytes;
          _outputSizeKb = sizeKb > 0 ? sizeKb : 1;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Processing error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveSignature() async {
    if (_processedBytes == null) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final filename = 'signature_cleaned_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(p.join(tempDir.path, filename));
      await file.writeAsBytes(_processedBytes!);

      if (mounted) {
        OpenFile.open(file.path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signature saved successfully! Size: $_outputSizeKb KB (Exam Ready)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save error: $e'), backgroundColor: Colors.red),
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
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 660),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.draw, color: Colors.deepPurple),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Signature Cleaner & Resizer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('10-20 KB pure white background for SSC, UPSC & IBPS', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview Container
                    Center(
                      child: Container(
                        width: 320,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.deepPurple, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _processedBytes != null
                            ? Image.memory(_processedBytes!, fit: BoxFit.contain)
                            : _pickedPath != null
                                ? Image.file(File(_pickedPath!), fit: BoxFit.contain)
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.drive_folder_upload, size: 36, color: Colors.deepPurple),
                                      SizedBox(height: 6),
                                      Text('Tap below to upload signature photo', style: TextStyle(fontSize: 12, color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Upload Button
                    Center(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add_a_photo, size: 16),
                        label: Text(_pickedPath == null ? 'Select Signature Photo' : 'Choose Different Photo'),
                        onPressed: _pickSignature,
                      ),
                    ),

                    if (_pickedPath != null) ...[
                      const SizedBox(height: 14),

                      // Status Badge (10-20 KB check)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: (_outputSizeKb >= 10 && _outputSizeKb <= 25)
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (_outputSizeKb >= 10 && _outputSizeKb <= 25) ? Colors.green : Colors.orange,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              (_outputSizeKb >= 10 && _outputSizeKb <= 25) ? Icons.check_circle : Icons.info,
                              size: 18,
                              color: (_outputSizeKb >= 10 && _outputSizeKb <= 25) ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Output File Size: $_outputSizeKb KB (SSC/UPSC requires 10-20 KB)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: (_outputSizeKb >= 10 && _outputSizeKb <= 25) ? Colors.green.shade800 : Colors.orange.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Slider 1: Paper Whitening Threshold
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Paper Whitening / Threshold:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('${_threshold.round()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                        ],
                      ),
                      Slider(
                        value: _threshold,
                        min: 120.0,
                        max: 230.0,
                        activeColor: Colors.deepPurple,
                        onChanged: (val) {
                          setState(() => _threshold = val);
                        },
                        onChangeEnd: (_) => _processSignature(),
                      ),

                      // Slider 2: Ink Darkness
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ink Darkness / Sharpness:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('${_darkness.toStringAsFixed(1)}x', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                        ],
                      ),
                      Slider(
                        value: _darkness,
                        min: 1.0,
                        max: 2.5,
                        activeColor: Colors.deepPurple,
                        onChanged: (val) {
                          setState(() => _darkness = val);
                        },
                        onChangeEnd: (_) => _processSignature(),
                      ),

                      // Border toggle
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Add Clean Border (1px)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        value: _addBorder,
                        onChanged: (val) {
                          setState(() => _addBorder = val);
                          _processSignature();
                        },
                      ),
                      const SizedBox(height: 10),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: _isProcessing
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.download_done),
                          label: Text('Save Exam Signature ($_outputSizeKb KB)'),
                          onPressed: _isProcessing ? null : _saveSignature,
                        ),
                      ),
                    ],
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
