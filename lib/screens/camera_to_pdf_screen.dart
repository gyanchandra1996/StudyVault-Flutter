import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/study_provider.dart';
import '../services/pdf_tools_service.dart';
import '../services/share_service.dart';
import '../models/pdf_document.dart' as model;
import 'pdf_reader_screen.dart';

class CameraToPdfScreen extends StatefulWidget {
  const CameraToPdfScreen({Key? key}) : super(key: key);

  @override
  State<CameraToPdfScreen> createState() => _CameraToPdfScreenState();
}

class _CameraToPdfScreenState extends State<CameraToPdfScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<String> _pageImagePaths = [];
  late TextEditingController _titleController;
  int? _selectedCategoryId;
  bool _isConverting = false;
  model.PdfDocument? _generatedPdf;

  @override
  void initState() {
    super.initState();
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    _titleController = TextEditingController(text: 'Scan_Notes_$timestamp');
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // 1. Click photo with camera & auto-prompt for next page
  Future<void> _clickCameraImage() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (photo != null) {
        setState(() {
          _pageImagePaths.add(photo.path);
        });
        _promptForNextPage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 2. Multi-pick from gallery
  Future<void> _pickGalleryImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 90);
      if (images.isNotEmpty) {
        setState(() {
          for (final img in images) {
            if (!_pageImagePaths.contains(img.path)) {
              _pageImagePaths.add(img.path);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _promptForNextPage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Page ${_pageImagePaths.length} added! Click more pages or convert to PDF.'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '📷 Next Page',
          textColor: Colors.amber,
          onPressed: _clickCameraImage,
        ),
      ),
    );
  }

  void _movePage(int index, int delta) {
    final newIndex = index + delta;
    if (newIndex < 0 || newIndex >= _pageImagePaths.length) return;
    setState(() {
      final item = _pageImagePaths.removeAt(index);
      _pageImagePaths.insert(newIndex, item);
    });
  }

  void _removePage(int index) {
    setState(() {
      _pageImagePaths.removeAt(index);
    });
  }

  Future<void> _convertToPdf() async {
    if (_pageImagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture or select at least 1 image.')),
      );
      return;
    }

    setState(() => _isConverting = true);
    final study = Provider.of<StudyProvider>(context, listen: false);

    try {
      final title = _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : 'Scanned_Notes';

      final pdfDoc = await PdfToolsService.convertImagesToPdf(
        _pageImagePaths,
        title,
        categoryId: _selectedCategoryId ?? study.selectedCategory?.id,
        examId: study.selectedExam?.id,
      );

      await study.loadInitialData();

      if (mounted) {
        setState(() {
          _isConverting = false;
          _generatedPdf = pdfDoc;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConverting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF conversion failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final study = Provider.of<StudyProvider>(context);
    final accent = settings.activeAccentColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera & Image to PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          if (_pageImagePaths.isNotEmpty && _generatedPdf == null)
            TextButton.icon(
              icon: _isConverting
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: Text(
                _isConverting ? 'Compiling...' : 'Create PDF (${_pageImagePaths.length})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: _isConverting ? null : _convertToPdf,
            ),
        ],
      ),
      body: _generatedPdf != null
          ? _buildSuccessView(_generatedPdf!, accent, isDark)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Capture Bar (Camera & Gallery Buttons)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accent.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: accent.withOpacity(0.2),
                              child: Icon(Icons.camera_enhance_rounded, color: accent),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Click or Select Pages',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Text(
                                    'Snap book pages, class notes, or handwritten sheets',
                                    style: TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Open Camera', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: _clickCameraImage,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('From Gallery'),
                                onPressed: _pickGalleryImages,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metadata Card (Title & Category)
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'PDF Document Title',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category Selector
                  if (study.categories.isNotEmpty)
                    DropdownButtonFormField<int?>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'Assign to Category (Optional)',
                        prefixIcon: const Icon(Icons.folder_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('No Category (General)')),
                        ...study.categories.map((c) => DropdownMenuItem<int?>(
                              value: c.id,
                              child: Text(c.title),
                            )),
                      ],
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                    ),
                  const SizedBox(height: 20),

                  // Pages List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Captured Pages (${_pageImagePaths.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (_pageImagePaths.isNotEmpty)
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Page'),
                          onPressed: _clickCameraImage,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_pageImagePaths.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_camera_back_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No images added yet',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap "Open Camera" to snap your first page or select from gallery',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pageImagePaths.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, idx) {
                        final imgPath = _pageImagePaths[idx];
                        final file = File(imgPath);

                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))
                            ],
                          ),
                          child: Row(
                            children: [
                              // Page Number
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${idx + 1}',
                                  style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Image Thumbnail
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  file,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 30),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Info
                              Expanded(
                                child: Text(
                                  'Page ${idx + 1}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),

                              // Reorder & Delete controls
                              IconButton(
                                icon: const Icon(Icons.arrow_upward, size: 18),
                                tooltip: 'Move Up',
                                onPressed: idx > 0 ? () => _movePage(idx, -1) : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_downward, size: 18),
                                tooltip: 'Move Down',
                                onPressed: idx < _pageImagePaths.length - 1 ? () => _movePage(idx, 1) : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                tooltip: 'Delete Page',
                                onPressed: () => _removePage(idx),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),
                  if (_pageImagePaths.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _isConverting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.picture_as_pdf),
                        label: Text(
                          _isConverting ? 'Generating PDF Document...' : 'Convert to PDF (${_pageImagePaths.length} Pages)',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isConverting ? null : _convertToPdf,
                      ),
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildSuccessView(model.PdfDocument pdf, Color accent, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
            ),
            const SizedBox(height: 18),
            Text(
              pdf.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${pdf.totalPages} Pages • ${(pdf.fileSize / 1024).toStringAsFixed(1)} KB • Stored in Vault',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.menu_book),
                label: const Text('Open in PDF Reader', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => PdfReaderScreen(pdf: pdf)),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share PDF'),
                    onPressed: () => ShareService.sharePdf(pdf.localPath, pdf.title),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Scan Another'),
                    onPressed: () {
                      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
                      setState(() {
                        _pageImagePaths.clear();
                        _generatedPdf = null;
                        _titleController.text = 'Scan_Notes_$timestamp';
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
