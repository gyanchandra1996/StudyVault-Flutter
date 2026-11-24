import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:open_file/open_file.dart';

class BackgroundRemoverDialog extends StatefulWidget {
  const BackgroundRemoverDialog({Key? key}) : super(key: key);

  @override
  State<BackgroundRemoverDialog> createState() => _BackgroundRemoverDialogState();
}

class _BackgroundRemoverDialogState extends State<BackgroundRemoverDialog> {
  String? _pickedPath;
  ui.Image? _loadedImage;
  Uint8List? _processedBytes;
  int _outputSizeKb = 0;
  bool _isProcessing = false;

  // Background options: 'white', 'blue', 'transparent'
  String _bgOption = 'white';
  double _tolerance = 42.0; // 15 to 80
  int _targetMaxDim = 600;

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
      final path = result.files.first.path!;
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      setState(() {
        _pickedPath = path;
        _loadedImage = frame.image;
        _processedBytes = null;
      });
      _processBackground();
    }
  }

  Future<void> _processBackground() async {
    if (_loadedImage == null) return;
    setState(() => _isProcessing = true);

    try {
      final img = _loadedImage!;
      // Scale down proportionally if larger than targetMaxDim for speed
      double scale = 1.0;
      if (img.width > _targetMaxDim || img.height > _targetMaxDim) {
        scale = (_targetMaxDim / img.width).clamp(0.01, _targetMaxDim / img.height);
      }
      final outW = (img.width * scale).round();
      final outH = (img.height * scale).round();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()),
        Paint()..filterQuality = ui.FilterQuality.medium,
      );
      final scaledPic = recorder.endRecording();
      final scaledImg = await scaledPic.toImage(outW, outH);
      final byteData = await scaledImg.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) throw Exception('Could not read image buffer');

      final raw = Uint8List.fromList(byteData.buffer.asUint8List());

      // 1. Detect background color by sampling the 4 corners (top-left, top-right, etc.)
      int bgR = 0, bgG = 0, bgB = 0;
      final cornerOffsets = [
        0, // top-left
        (outW - 1) * 4, // top-right
        ((outH - 1) * outW) * 4, // bottom-left
        ((outH - 1) * outW + (outW - 1)) * 4, // bottom-right
        (outW ~/ 2) * 4, // top-center
      ];
      int samples = 0;
      for (final off in cornerOffsets) {
        if (off + 2 < raw.length) {
          bgR += raw[off];
          bgG += raw[off + 1];
          bgB += raw[off + 2];
          samples++;
        }
      }
      if (samples > 0) {
        bgR ~/= samples;
        bgG ~/= samples;
        bgB ~/= samples;
      }

      // Desired replacement color
      int replaceR = 255, replaceG = 255, replaceB = 255, replaceA = 255;
      if (_bgOption == 'blue') {
        replaceR = 93;
        replaceG = 156;
        replaceB = 236; // Clean exam standard light blue
        replaceA = 255;
      } else if (_bgOption == 'transparent') {
        replaceR = 0;
        replaceG = 0;
        replaceB = 0;
        replaceA = 0;
      } else {
        // white
        replaceR = 255;
        replaceG = 255;
        replaceB = 255;
        replaceA = 255;
      }

      final tolSq = _tolerance * _tolerance * 3;

      // Replace pixels that match background within tolerance
      for (int i = 0; i < raw.length; i += 4) {
        final r = raw[i];
        final g = raw[i + 1];
        final b = raw[i + 2];

        final dr = r - bgR;
        final dg = g - bgG;
        final db = b - bgB;
        final distSq = dr * dr + dg * dg + db * db;

        if (distSq < tolSq) {
          raw[i] = replaceR;
          raw[i + 1] = replaceG;
          raw[i + 2] = replaceB;
          raw[i + 3] = replaceA;
        }
      }

      // Convert back to PNG image
      final comp = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        raw,
        outW,
        outH,
        ui.PixelFormat.rgba8888,
        (result) => comp.complete(result),
      );
      final finalImage = await comp.future;
      final finalPng = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      if (finalPng == null) throw Exception('PNG compression failed');

      final finalBytes = finalPng.buffer.asUint8List();
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

  Future<void> _saveAndOpen() async {
    if (_processedBytes == null) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final filename = 'bg_removed_${_bgOption}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(p.join(tempDir.path, filename));
      await file.writeAsBytes(_processedBytes!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved: $filename ($_outputSizeKb KB)'),
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: BoxDecoration(
                color: Colors.purple.shade700,
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
                    child: const Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Image Background Remover', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Replace with Pure White, Light Blue or Transparent PNG', style: TextStyle(color: Colors.white70, fontSize: 11)),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview Area
                    Center(
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: Container(
                          width: double.infinity,
                          height: 220,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.purple.shade300, width: 1.5),
                          ),
                          child: _isProcessing
                              ? const Center(child: CircularProgressIndicator())
                              : _processedBytes != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(_processedBytes!, fit: BoxFit.contain),
                                    )
                                  : _pickedPath != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(File(_pickedPath!), fit: BoxFit.contain),
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_photo_alternate, size: 48, color: Colors.purple.shade400),
                                            const SizedBox(height: 10),
                                            const Text('Select Photo from Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                            const SizedBox(height: 4),
                                            Text('Supports JPEG, PNG, Passport photos', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                          ],
                                        ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Center(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.upload_file, size: 16),
                        label: Text(_pickedPath == null ? 'Upload Photo' : 'Choose Different Photo'),
                        onPressed: _pickPhoto,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Color Replacement Selector
                    const Text('REPLACE BACKGROUND WITH:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildBgPill(
                            id: 'white',
                            title: 'Pure White',
                            subtitle: 'SSC / UPSC / IBPS',
                            dotColor: Colors.white,
                            borderColor: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildBgPill(
                            id: 'blue',
                            title: 'Light Blue',
                            subtitle: 'Railway / Police',
                            dotColor: const Color(0xFF5D9CEC),
                            borderColor: const Color(0xFF5D9CEC),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildBgPill(
                            id: 'transparent',
                            title: 'Transparent',
                            subtitle: 'ID Card / Web',
                            dotColor: Colors.black45,
                            borderColor: Colors.black26,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tolerance Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Color Removal Sensitivity:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('${_tolerance.round()}', style: TextStyle(color: Colors.purple.shade700, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: _tolerance,
                      min: 15.0,
                      max: 80.0,
                      divisions: 65,
                      activeColor: Colors.purple.shade700,
                      onChanged: (val) {
                        setState(() => _tolerance = val);
                      },
                      onChangeEnd: (_) => _processBackground(),
                    ),
                    const Text(
                      'Tip: If edges look rough, decrease sensitivity; if background remains, increase it.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),

                    if (_outputSizeKb > 0) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 18),
                            const SizedBox(width: 8),
                            Text('Processed Size: $_outputSizeKb KB (Clean Output)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Save & Open Image', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: (_processedBytes == null || _isProcessing) ? null : _saveAndOpen,
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

  Widget _buildBgPill({
    required String id,
    required String title,
    required String subtitle,
    required Color dotColor,
    required Color borderColor,
  }) {
    final isSel = _bgOption == id;
    return InkWell(
      onTap: () {
        setState(() => _bgOption = id);
        _processBackground();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSel ? Colors.purple.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSel ? Colors.purple.shade700 : Colors.grey.shade300,
            width: isSel ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isSel ? Colors.purple.shade900 : Colors.black87)),
            Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
