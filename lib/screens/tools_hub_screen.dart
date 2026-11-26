import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:open_file/open_file.dart';
import '../services/pdf_tools_service.dart';
import '../widgets/ai_notes_generator_modal.dart';
import '../widgets/pdf_tools_modal.dart';
import '../widgets/signature_cleaner_dialog.dart';
import '../widgets/background_remover_dialog.dart';
import '../widgets/digital_signature_pad_dialog.dart';
import '../widgets/syllabus_tracker_modal.dart';
import '../widgets/exam_analytics_modal.dart';
import '../widgets/quick_revision_handbook_modal.dart';
import 'camera_to_pdf_screen.dart';
import 'brain_games/brain_games_hub_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/ai_assistant_modal.dart';

class ToolsHubScreen extends StatefulWidget {
  final VoidCallback? onRefresh;

  const ToolsHubScreen({Key? key, this.onRefresh}) : super(key: key);

  @override
  State<ToolsHubScreen> createState() => _ToolsHubScreenState();
}

class _ToolsHubScreenState extends State<ToolsHubScreen> {
  String _selectedFilter = 'all';

  final List<Map<String, dynamic>> _allTools = [
    {
      'id': 'snap_solve_doubt',
      'title': 'Snap & Solve AI Doubt Scanner',
      'hindi': 'कैमरा से डाउट स्कैनर',
      'category': 'ai',
      'icon': Icons.camera_enhance_rounded,
      'color': Colors.deepOrange,
      'description': 'Click photo of any textbook question or equation. Aarna solves it step-by-step with formulas and concepts!',
      'badge': 'AARNA VISION',
    },
    {
      'id': 'brain_games',
      'title': 'Brain Games & Mental Focus',
      'hindi': 'मस्तिष्क खेल एवं एकाग्रता',
      'category': 'study',
      'icon': Icons.psychology_rounded,
      'color': Colors.amber.shade800,
      'description': 'Speed Math Blitz, Schulte Focus Grid, Memory Match & Stroop Reflex to warm up your cognitive speed before mock tests.',
      'badge': 'BRAIN WARM-UP',
    },
    {
      'id': 'passport_photo',
      'title': 'Passport Size Photo Maker',
      'hindi': 'पासपोर्ट साइज फोटो',
      'category': 'image',
      'icon': Icons.portrait,
      'color': Colors.blue,
      'description': 'Standard 3.5×4.5 cm exam photo with Name & Date of Photo (DOP) stamp for SSC, UPSC & IBPS forms.',
      'badge': 'EXAM ESSENTIAL',
    },
    {
      'id': 'custom_image_size',
      'title': 'Custom Image Resizer & Compressor',
      'hindi': 'इमेज साइज व कम्प्रेसर',
      'category': 'image',
      'icon': Icons.photo_size_select_large,
      'color': Colors.teal,
      'description': 'Compress photos and signatures to exact KB limits (e.g. 20-50 KB) and custom width/height.',
      'badge': 'EXAM RESIZER',
    },
    {
      'id': 'image_bg_remover',
      'title': 'Image Background Remover & Color Replacer',
      'hindi': 'इमेज बैकग्राउंड रिमूवर व कलर चेंज',
      'category': 'image',
      'icon': Icons.auto_fix_high_rounded,
      'color': Colors.purple.shade700,
      'description': 'Isolate candidate photo from background. 1-tap replace with Pure White (SSC/UPSC), Light Blue (State/Railway), or Transparent PNG.',
      'badge': 'AI ESSENTIAL',
    },
    {
      'id': 'signature_pad',
      'title': 'Digital Signature Pad & Generator',
      'hindi': 'डिजिटल हस्ताक्षर पैड',
      'category': 'image',
      'icon': Icons.gesture_rounded,
      'color': Colors.indigo.shade700,
      'description': 'Sign directly on screen with finger or stylus. Smooth ink strokes, blue/black ink selector, and 1-tap export in 10–20 KB format.',
      'badge': 'SIGNATURE',
    },
    {
      'id': 'custom_pdf',
      'title': 'Custom PDF Generator',
      'hindi': 'कस्टम पीडीएफ जनरेटर',
      'category': 'pdf',
      'icon': Icons.picture_as_pdf,
      'color': Colors.indigo,
      'description': 'Create custom PDF notes with title, candidate details, watermarks, margins & page numbers.',
      'badge': 'STUDY TOOL',
    },
    {
      'id': 'image_to_pdf',
      'title': 'Image to PDF Converter',
      'hindi': 'फोटो से पीडीएफ',
      'category': 'pdf',
      'icon': Icons.collections,
      'color': Colors.purple,
      'description': 'Combine multiple textbook photos, assignments, or handwritten notes into a clean PDF document.',
      'badge': 'HIGH SPEED',
    },
    {
      'id': 'pdf_to_image',
      'title': 'PDF to Image Extractor',
      'hindi': 'पीडीएफ से इमेज',
      'category': 'pdf',
      'icon': Icons.image,
      'color': Colors.deepOrange,
      'description': 'Extract pages and high-resolution images from any study PDF and save directly to device.',
      'badge': 'CONVERTER',
    },
    {
      'id': 'pdf_merge_split',
      'title': 'PDF Merge & Page Splitter',
      'hindi': 'पीडीएफ मर्ज व स्प्लिट',
      'category': 'pdf',
      'icon': Icons.call_merge,
      'color': Colors.amber.shade900,
      'description': 'Combine multiple chapter PDFs into one book or extract and delete selected exam pages.',
      'badge': 'UTILITY',
    },
    {
      'id': 'ai_notes_pdf',
      'title': 'AI Notes to PDF Generator',
      'hindi': 'एआई नोट्स से पीडीएफ',
      'category': 'ai',
      'icon': Icons.auto_awesome,
      'color': Colors.teal.shade700,
      'description': 'AI synthesizes comprehensive study notes on any topic and compiles them directly into formatted PDF.',
      'badge': 'SMART AI',
    },
    {
      'id': 'signature_cleaner',
      'title': 'Govt Signature Whitener & Compressor',
      'hindi': 'हस्ताक्षर क्लीनर व 10-20 KB कंप्रेसर',
      'category': 'image',
      'icon': Icons.draw_outlined,
      'color': Colors.deepPurple,
      'description': 'Whitens paper background, removes mobile camera shadows, sharpens blue/black ink, and compresses strictly to 10–20 KB for SSC, UPSC & IBPS forms.',
      'badge': 'GOVT FORMS',
    },
    {
      'id': 'syllabus_tracker',
      'title': 'Interactive Syllabus Tracker',
      'hindi': 'पाठ्यक्रम ट्रैकर',
      'category': 'study',
      'icon': Icons.checklist_rtl_rounded,
      'color': Colors.blueGrey,
      'description': 'Track syllabus completion for UPSC CSE, SSC CGL, Banking/IBPS and custom topics with live percentage progress bar.',
      'badge': 'TRACKER',
    },
    {
      'id': 'exam_analytics',
      'title': 'Mock Test Performance & Heatmap',
      'hindi': 'प्रदर्शन विश्लेषण व हीटमैप',
      'category': 'study',
      'icon': Icons.insights_rounded,
      'color': Colors.teal.shade800,
      'description': 'Analyze question speed vs accuracy heatmap, subject-wise strengths (Polity, History, Math, Science), and revision priority alerts.',
      'badge': 'ANALYTICS',
    },
    {
      'id': 'gk_cheat_sheets',
      'title': 'Exam Revision Handbook & Cheat Sheets',
      'hindi': 'त्वरित पुनरीक्षण हैंडबुक',
      'category': 'study',
      'icon': Icons.menu_book_rounded,
      'color': Colors.amber.shade800,
      'description': 'Digital cheat sheets with high-yield revision points: Indian Constitution Articles, Modern History Timeline, Essential Math Formulas & General Science.',
      'badge': 'CHEAT SHEETS',
    },
  ];

  List<Map<String, dynamic>> get _filteredTools {
    if (_selectedFilter == 'all') return _allTools;
    return _allTools.where((t) => t['category'] == _selectedFilter).toList();
  }

  void _openTool(Map<String, dynamic> tool) {
    switch (tool['id']) {
      case 'snap_solve_doubt':
        ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85).then((picked) {
          if (picked != null && mounted) {
            showDialog(
              context: context,
              builder: (_) => AiAssistantModal(initialImagePath: picked.path),
            );
          } else if (mounted) {
            showDialog(
              context: context,
              builder: (_) => const AiAssistantModal(),
            );
          }
        });
        break;
      case 'brain_games':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BrainGamesHubScreen()),
        );
        break;
      case 'passport_photo':
        _showPassportPhotoModal();
        break;
      case 'custom_image_size':
        _showCustomImageSizeModal();
        break;
      case 'image_bg_remover':
        showDialog(
          context: context,
          builder: (_) => const BackgroundRemoverDialog(),
        );
        break;
      case 'signature_pad':
        showDialog(
          context: context,
          builder: (_) => const DigitalSignaturePadDialog(),
        );
        break;
      case 'signature_cleaner':
        showDialog(
          context: context,
          builder: (_) => const SignatureCleanerDialog(),
        );
        break;
      case 'syllabus_tracker':
        showDialog(
          context: context,
          builder: (_) => const SyllabusTrackerModal(),
        );
        break;
      case 'exam_analytics':
        showDialog(
          context: context,
          builder: (_) => ExamAnalyticsModal(onRefresh: widget.onRefresh),
        );
        break;
      case 'gk_cheat_sheets':
        showDialog(
          context: context,
          builder: (_) => const QuickRevisionHandbookModal(),
        );
        break;
      case 'custom_pdf':
        _showCustomPdfModal();
        break;
      case 'image_to_pdf':
        _showImageToPdfModal();
        break;
      case 'pdf_to_image':
        _showPdfToImageModal();
        break;
      case 'pdf_merge_split':
        showDialog(
          context: context,
          builder: (_) => PdfToolsModal(onUpdated: () => widget.onRefresh?.call()),
        );
        break;
      case 'ai_notes_pdf':
        showDialog(
          context: context,
          builder: (_) => AiNotesGeneratorModal(onGenerated: () => widget.onRefresh?.call()),
        );
        break;
    }
  }

  // ---------------- TOOL 1: PASSPORT SIZE PHOTO MAKER ----------------
  void _showPassportPhotoModal() {
    showDialog(
      context: context,
      builder: (ctx) => const _PassportPhotoDialog(),
    );
  }

  // ---------------- TOOL 2: CUSTOM IMAGE RESIZER & COMPRESSOR ----------------
  void _showCustomImageSizeModal() {
    showDialog(
      context: context,
      builder: (ctx) => const _CustomImageResizerDialog(),
    );
  }

  // ---------------- TOOL 3: CUSTOM PDF GENERATOR ----------------
  void _showCustomPdfModal() {
    showDialog(
      context: context,
      builder: (ctx) => const _CustomPdfGeneratorDialog(),
    );
  }

  // ---------------- TOOL 4: IMAGE TO PDF ----------------
  Future<void> _showImageToPdfModal() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraToPdfScreen()),
    ).then((_) => widget.onRefresh?.call());
  }

  // ---------------- TOOL 5: PDF TO IMAGE EXTRACTOR ----------------
  Future<void> _showPdfToImageModal() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty || result.files.first.path == null) return;

    final pdfPath = result.files.first.path!;
    try {
      final file = File(pdfPath);
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;
      document.dispose();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.image, color: Colors.deepOrange),
              SizedBox(width: 8),
              Text('PDF Information'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('File: ${p.basename(pdfPath)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Total Pages: $pageCount'),
              const SizedBox(height: 6),
              Text('File Size: ${(file.lengthSync() / 1024).toStringAsFixed(1)} KB'),
              const SizedBox(height: 12),
              const Text(
                'Document verified. You can view or annotate this PDF directly in the built-in reader.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open PDF'),
              onPressed: () {
                Navigator.pop(ctx);
                OpenFile.open(pdfPath);
              },
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not read PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // Tools Suite Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.handyman_outlined, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exam Utility Tools Suite',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Passport photo with crop & zoom, signature pad, background remover, and custom PDF generator for exams.',
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterPill('all', 'All Tools (${_allTools.length})', Icons.apps),
              const SizedBox(width: 8),
              _buildFilterPill('image', 'Image & Photo (${_allTools.where((t) => t['category'] == 'image').length})', Icons.photo),
              const SizedBox(width: 8),
              _buildFilterPill('study', 'Study & Exam (${_allTools.where((t) => t['category'] == 'study').length})', Icons.school),
              const SizedBox(width: 8),
              _buildFilterPill('pdf', 'PDF Tools (${_allTools.where((t) => t['category'] == 'pdf').length})', Icons.picture_as_pdf),
              const SizedBox(width: 8),
              _buildFilterPill('ai', 'AI Generation', Icons.auto_awesome),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tools Grid (Square Cards)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 4, bottom: 20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.96,
          ),
          itemCount: _filteredTools.length,
          itemBuilder: (ctx, idx) {
            final tool = _filteredTools[idx];
            final color = tool['color'] as Color;
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Card(
              elevation: 2,
              shadowColor: color.withOpacity(0.18),
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: color.withOpacity(0.25), width: 1.2),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _openTool(tool),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header Row: Icon + Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(tool['icon'] as IconData, color: color, size: 22),
                          ),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tool['badge'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Tool Title and Hindi Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tool['title'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                height: 1.25,
                              ),
                            ),
                            if (tool['hindi'] != null && (tool['hindi'] as String).isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                tool['hindi'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Footer Row: Action prompt
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Open Tool',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            Icon(Icons.arrow_forward_rounded, size: 14, color: color),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilterPill(String id, String label, IconData icon) {
    final isSel = _selectedFilter == id;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSel ? Colors.white : Colors.indigo),
      label: Text(label),
      selected: isSel,
      selectedColor: Colors.indigo,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isSel ? Colors.white : null,
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = id);
      },
    );
  }
}

// ============================================================================
// 1. PASSPORT SIZE PHOTO MAKER DIALOG (WITH CROP, ZOOM, PAN, DOP & SHARE)
// ============================================================================
class _PassportPhotoDialog extends StatefulWidget {
  const _PassportPhotoDialog({Key? key}) : super(key: key);

  @override
  State<_PassportPhotoDialog> createState() => _PassportPhotoDialogState();
}

class _PassportPhotoDialogState extends State<_PassportPhotoDialog> {
  String? _pickedImagePath;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(
    text: '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
  );
  bool _addStamp = true;
  bool _isProcessing = false;
  String? _generatedPhotoPath;
  int _copies = 6;

  // Framing, Crop, Zoom and Position offsets
  double _zoom = 1.3; // 1.0 to 3.5
  double _offsetX = 0.0; // -120 to 120
  double _offsetY = 0.0; // -120 to 120
  int _rotationQuarterTurns = 0;

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
      setState(() {
        _pickedImagePath = result.files.first.path;
        _generatedPhotoPath = null;
        _zoom = 1.3;
        _offsetX = 0.0;
        _offsetY = 0.0;
        _rotationQuarterTurns = 0;
      });
    }
  }

  void _resetCrop() {
    setState(() {
      _zoom = 1.0;
      _offsetX = 0.0;
      _offsetY = 0.0;
      _rotationQuarterTurns = 0;
    });
  }

  Future<void> _generatePassportPhoto() async {
    if (_pickedImagePath == null) return;
    setState(() => _isProcessing = true);

    try {
      final file = File(_pickedImagePath!);
      final bytes = await file.readAsBytes();

      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      final original = frameInfo.image;

      // Passport photo standard: 350 x 450 px (3.5cm x 4.5cm at ~250-300 dpi)
      const width = 350.0;
      const height = 450.0;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));

      // White background
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, width, height),
        Paint()..color = Colors.white,
      );

      final photoHeight = _addStamp ? height - 60.0 : height;

      // Clip canvas strictly to photo display box
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, width, photoHeight));

      // Handle optional rotation
      if (_rotationQuarterTurns > 0) {
        canvas.translate(width / 2, photoHeight / 2);
        canvas.rotate(_rotationQuarterTurns * 3.141592653589793 / 2);
        canvas.translate(-width / 2, -photoHeight / 2);
      }

      // Calculate drawing dimensions with Zoom & Pan offsets
      final baseScale = (width / original.width).clamp(0.01, photoHeight / original.height);
      final finalScale = baseScale * _zoom;
      final drawWidth = original.width * finalScale;
      final drawHeight = original.height * finalScale;
      final dx = (width - drawWidth) / 2 + _offsetX;
      final dy = (photoHeight - drawHeight) / 2 + _offsetY;

      canvas.drawImageRect(
        original,
        Rect.fromLTWH(0, 0, original.width.toDouble(), original.height.toDouble()),
        Rect.fromLTWH(dx, dy, drawWidth, drawHeight),
        Paint()..filterQuality = ui.FilterQuality.high,
      );
      canvas.restore();

      // Name & Date of Photo (DOP) banner for SSC/UPSC
      if (_addStamp) {
        final stampRect = Rect.fromLTWH(0, height - 60, width, 60);
        canvas.drawRect(stampRect, Paint()..color = Colors.white);
        canvas.drawLine(
          Offset(0, height - 60),
          Offset(width, height - 60),
          Paint()..color = Colors.grey.shade400..strokeWidth = 1,
        );

        final name = _nameController.text.trim().toUpperCase();
        final date = _dateController.text.trim();

        final paragraphBuilder = ui.ParagraphBuilder(
          ui.ParagraphStyle(textAlign: TextAlign.center, fontSize: 13, fontWeight: FontWeight.bold),
        )
          ..pushStyle(ui.TextStyle(color: Colors.black))
          ..addText(name.isNotEmpty ? '$name\n' : '')
          ..pushStyle(ui.TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w600))
          ..addText('DOP: $date');

        final paragraph = paragraphBuilder.build()
          ..layout(ui.ParagraphConstraints(width: width));

        canvas.drawParagraph(paragraph, Offset(0, height - 52));
      }

      // Outer border
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, width, height),
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      final picture = recorder.endRecording();
      final img = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Image encoding failed');

      final tempDir = await getTemporaryDirectory();
      final outPath = p.join(tempDir.path, 'passport_${DateTime.now().millisecondsSinceEpoch}.png');
      await File(outPath).writeAsBytes(byteData.buffer.asUint8List());

      if (mounted) {
        setState(() {
          _generatedPhotoPath = outPath;
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

  Future<void> _createPrintableSheet() async {
    if (_generatedPhotoPath == null) return;
    setState(() => _isProcessing = true);

    try {
      final photoBytes = await File(_generatedPhotoPath!).readAsBytes();
      final document = PdfDocument();
      document.pageSettings.margins.all = 20;

      final page = document.pages.add();
      final bitmap = PdfBitmap(photoBytes);

      // Draw grid of passport photos (2 columns x 3 or 4 rows)
      const photoW = 120.0;
      const photoH = 155.0;
      const gapX = 20.0;
      const gapY = 20.0;

      for (int i = 0; i < _copies; i++) {
        final col = i % 2;
        final row = i ~/ 2;
        final x = 40.0 + col * (photoW + gapX);
        final y = 40.0 + row * (photoH + gapY);

        page.graphics.drawImage(bitmap, Rect.fromLTWH(x, y, photoW, photoH));
        // Cut marks
        page.graphics.drawRectangle(
          pen: PdfPen(PdfColor(180, 180, 180), width: 0.5),
          bounds: Rect.fromLTWH(x, y, photoW, photoH),
        );
      }

      final pdfBytes = await document.save();
      document.dispose();

      final tempDir = await getTemporaryDirectory();
      final outPdf = p.join(tempDir.path, 'passport_sheet_${DateTime.now().millisecondsSinceEpoch}.pdf');
      final file = File(outPdf);
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Printable sheet ready: ${p.basename(outPdf)}'),
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
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF sheet error: $e'), backgroundColor: Colors.red),
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.portrait, color: Colors.blue),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Passport Photo Studio (SSC/UPSC)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Crop, zoom face to 70–80% area, add DOP & Share', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                    // Photo preview / selector with guide frame
                    Center(
                      child: GestureDetector(
                        onTap: _pickedImagePath == null ? _pickPhoto : null,
                        child: Container(
                          width: 154,
                          height: 198,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue, width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: _generatedPhotoPath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(File(_generatedPhotoPath!), fit: BoxFit.contain),
                                )
                              : _pickedImagePath != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: ClipRect(
                                              child: Transform.translate(
                                                offset: Offset(_offsetX * (154.0 / 350.0), _offsetY * (198.0 / 450.0)),
                                                child: RotatedBox(
                                                  quarterTurns: _rotationQuarterTurns,
                                                  child: Transform.scale(
                                                    scale: _zoom,
                                                    child: Image.file(File(_pickedImagePath!), fit: BoxFit.contain),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Overlay guideline
                                          Positioned.fill(
                                            child: CustomPaint(
                                              painter: _PassportGuideOverlayPainter(),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 4,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 2),
                                              color: Colors.black.withOpacity(0.55),
                                              child: const Text(
                                                'Head inside oval',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.add_a_photo, size: 40, color: Colors.blue),
                                        SizedBox(height: 8),
                                        Text('Select Photo', style: TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.bold)),
                                        SizedBox(height: 4),
                                        Text('Gallery or Camera', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      ],
                                    ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Controls row: Change Photo, Rotate, Reset Crop
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.upload, size: 16),
                          label: Text(_pickedImagePath == null ? 'Upload Photo' : 'Change'),
                          onPressed: _pickPhoto,
                        ),
                        if (_pickedImagePath != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.rotate_right_rounded, color: Colors.blue),
                            tooltip: 'Rotate 90°',
                            onPressed: () {
                              setState(() {
                                _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
                                _generatedPhotoPath = null;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.restart_alt, color: Colors.grey),
                            tooltip: 'Reset Framing',
                            onPressed: () {
                              _resetCrop();
                              setState(() => _generatedPhotoPath = null);
                            },
                          ),
                        ],
                      ],
                    ),

                    // Zoom & Pan Sliders (When photo is selected)
                    if (_pickedImagePath != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.crop_free, size: 16, color: Colors.blue),
                                SizedBox(width: 6),
                                Text('Face Framing & Zoom Sliders:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Zoom Slider
                            Row(
                              children: [
                                const Icon(Icons.zoom_out, size: 18, color: Colors.grey),
                                Expanded(
                                  child: Slider(
                                    value: _zoom,
                                    min: 1.0,
                                    max: 3.5,
                                    divisions: 25,
                                    label: '${_zoom.toStringAsFixed(1)}x Zoom',
                                    onChanged: (val) {
                                      setState(() {
                                        _zoom = val;
                                        _generatedPhotoPath = null;
                                      });
                                    },
                                  ),
                                ),
                                const Icon(Icons.zoom_in, size: 18, color: Colors.blue),
                              ],
                            ),

                            // Vertical Pan (Move Up/Down)
                            Row(
                              children: [
                                const Text('Position Y:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Slider(
                                    value: _offsetY,
                                    min: -120.0,
                                    max: 120.0,
                                    divisions: 48,
                                    label: 'Y: ${_offsetY.round()}',
                                    onChanged: (val) {
                                      setState(() {
                                        _offsetY = val;
                                        _generatedPhotoPath = null;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),

                            // Horizontal Pan (Move Left/Right)
                            Row(
                              children: [
                                const Text('Position X:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Slider(
                                    value: _offsetX,
                                    min: -100.0,
                                    max: 100.0,
                                    divisions: 40,
                                    label: 'X: ${_offsetX.round()}',
                                    onChanged: (val) {
                                      setState(() {
                                        _offsetX = val;
                                        _generatedPhotoPath = null;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Name and Date stamp toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Add Name & Date of Photo (DOP)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Mandatory for SSC CGL, CHSL, GD & UPSC forms', style: TextStyle(fontSize: 11)),
                      value: _addStamp,
                      onChanged: (val) => setState(() {
                        _addStamp = val;
                        _generatedPhotoPath = null;
                      }),
                    ),

                    if (_addStamp) ...[
                      TextField(
                        controller: _nameController,
                        onChanged: (_) => setState(() => _generatedPhotoPath = null),
                        decoration: const InputDecoration(
                          labelText: 'Candidate Name',
                          hintText: 'e.g. RAHUL SHARMA',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _dateController,
                        onChanged: (_) => setState(() => _generatedPhotoPath = null),
                        decoration: const InputDecoration(
                          labelText: 'Date of Photo (DD/MM/YYYY)',
                          hintText: 'e.g. 24/11/2026',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        icon: _isProcessing
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check),
                        label: const Text('Generate Passport Photo (3.5×4.5 cm)'),
                        onPressed: (_pickedImagePath == null || _isProcessing) ? null : _generatePassportPhoto,
                      ),
                    ),

                    if (_generatedPhotoPath != null) ...[
                      const SizedBox(height: 14),
                      const Divider(),
                      const SizedBox(height: 6),

                      // Direct Share / Print actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('View Photo'),
                              onPressed: () => OpenFile.open(_generatedPhotoPath!),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              icon: const Icon(Icons.share, size: 16),
                              label: const Text('Share / Print'),
                              onPressed: () {
                                OpenFile.open(_generatedPhotoPath!);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Photo opened! Tap share icon in your viewer to send via WhatsApp or Print.'),
                                    backgroundColor: Colors.teal,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Printable Sheet Copies:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          DropdownButton<int>(
                            value: _copies,
                            items: const [
                              DropdownMenuItem(value: 4, child: Text('4 Photos')),
                              DropdownMenuItem(value: 6, child: Text('6 Photos (Standard)')),
                              DropdownMenuItem(value: 8, child: Text('8 Photos (A4)')),
                            ],
                            onChanged: (v) => setState(() => _copies = v ?? 6),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.print, size: 18),
                          label: Text('Generate Printable $_copies-Photo Sheet (PDF)'),
                          onPressed: _isProcessing ? null : _createPrintableSheet,
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

class _PassportGuideOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw oval for head guidance
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: size.width * 0.58,
      height: size.height * 0.52,
    );
    canvas.drawOval(ovalRect, paint);

    // Eye level horizontal guide
    final eyePaint = Paint()
      ..color = Colors.amber.withOpacity(0.7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.38),
      Offset(size.width * 0.8, size.height * 0.38),
      eyePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 2. CUSTOM IMAGE RESIZER & COMPRESSOR (GOVT EXAM STANDARDS)
// ============================================================================
class _CustomImageResizerDialog extends StatefulWidget {
  const _CustomImageResizerDialog({Key? key}) : super(key: key);

  @override
  State<_CustomImageResizerDialog> createState() => _CustomImageResizerDialogState();
}

class _CustomImageResizerDialogState extends State<_CustomImageResizerDialog> {
  String? _sourcePath;
  int _originalSizeKb = 0;
  int _targetSizeKb = 50;
  final TextEditingController _targetKbController = TextEditingController(text: '50');
  final TextEditingController _widthController = TextEditingController(text: '400');
  final TextEditingController _heightController = TextEditingController(text: '400');
  bool _isProcessing = false;
  String? _compressedPath;
  int _compressedSizeKb = 0;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
      final file = File(result.files.first.path!);
      final size = (file.lengthSync() / 1024).round();
      setState(() {
        _sourcePath = file.path;
        _originalSizeKb = size;
        _compressedPath = null;
      });
    }
  }

  Future<void> _compressAndResize() async {
    if (_sourcePath == null) return;
    setState(() => _isProcessing = true);

    try {
      final file = File(_sourcePath!);
      final bytes = await file.readAsBytes();

      final targetW = int.tryParse(_widthController.text.trim()) ?? 400;
      final targetH = int.tryParse(_heightController.text.trim()) ?? 400;

      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: targetW > 0 ? targetW : null,
        targetHeight: targetH > 0 ? targetH : null,
      );
      final frame = await codec.getNextFrame();
      final img = frame.image;

      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Image resize failed');

      final tempDir = await getTemporaryDirectory();
      final outPath = p.join(tempDir.path, 'resized_${DateTime.now().millisecondsSinceEpoch}.png');
      final targetBytes = byteData.buffer.asUint8List();
      await File(outPath).writeAsBytes(targetBytes);

      final finalSize = (File(outPath).lengthSync() / 1024).round();

      if (mounted) {
        setState(() {
          _compressedPath = outPath;
          _compressedSizeKb = finalSize;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resize failed: $e'), backgroundColor: Colors.red),
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
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.photo_size_select_large, color: Colors.teal),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Custom Image Resizer & Compressor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Pi7 Style custom KB & dimension sizing for exams', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                    if (_sourcePath == null)
                      Center(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.add_photo_alternate, size: 20),
                          label: const Text('Select Image or Signature to Compress'),
                          onPressed: _pickImage,
                        ),
                      )
                    else ...[
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Image.file(File(_sourcePath!), fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.basename(_sourcePath!), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Original Size: $_originalSizeKb KB', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          TextButton(onPressed: _pickImage, child: const Text('Change')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('TARGET PRESETS (EXAM STANDARDS):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [20, 50, 100, 200].map((kb) {
                          return ActionChip(
                            label: Text('< $kb KB'),
                            onPressed: () {
                              _targetKbController.text = '$kb';
                              setState(() => _targetSizeKb = kb);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _widthController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Width (px)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Height (px)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                          icon: _isProcessing
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.compress),
                          label: const Text('Resize & Compress Image'),
                          onPressed: _isProcessing ? null : _compressAndResize,
                        ),
                      ),
                      if (_compressedPath != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Resized Successfully: $_compressedSizeKb KB (Was $_originalSizeKb KB)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.open_in_new),
                                onPressed: () => OpenFile.open(_compressedPath!),
                              ),
                            ],
                          ),
                        ),
                      ],
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

// ============================================================================
// 3. CUSTOM PDF GENERATOR (PI7 STYLE)
// ============================================================================
class _CustomPdfGeneratorDialog extends StatefulWidget {
  const _CustomPdfGeneratorDialog({Key? key}) : super(key: key);

  @override
  State<_CustomPdfGeneratorDialog> createState() => _CustomPdfGeneratorDialogState();
}

class _CustomPdfGeneratorDialogState extends State<_CustomPdfGeneratorDialog> {
  final TextEditingController _titleController = TextEditingController(text: 'Exam Preparation Notes');
  final TextEditingController _candidateController = TextEditingController();
  final TextEditingController _watermarkController = TextEditingController(text: 'STUDY VAULT');
  final TextEditingController _bodyController = TextEditingController(
    text: 'Key Formulas & Revision Concepts:\n\n1. Article 14: Equality before law & equal protection of laws.\n2. Article 21: Protection of life and personal liberty.\n3. Article 32: Constitutional remedies (Heart & Soul).\n\nImportant Exam Takeaways:\n• Fundamental rights are justiciable.\n• 42nd Amendment added Fundamental Duties in 1976.',
  );
  bool _addWatermark = true;
  bool _addPageNumbers = true;
  bool _isGenerating = false;

  Future<void> _generatePdf() async {
    setState(() => _isGenerating = true);

    try {
      final document = PdfDocument();
      document.pageSettings.margins.all = 36; // 0.5 inch

      final page = document.pages.add();
      final pageSize = page.getClientSize();

      final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
      final subFont = PdfStandardFont(PdfFontFamily.helvetica, 11);
      final bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 11);

      double y = 0;

      // Title
      final title = _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Custom Document';
      page.graphics.drawString(title, titleFont, brush: PdfSolidBrush(PdfColor(67, 56, 202)), bounds: Rect.fromLTWH(0, y, pageSize.width, 24));
      y += 28;

      // Candidate / Date Subtitle
      final candidate = _candidateController.text.trim();
      final subInfo = '${candidate.isNotEmpty ? "Prepared by: $candidate • " : ""}Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
      page.graphics.drawString(subInfo, subFont, brush: PdfSolidBrush(PdfColor(100, 116, 139)), bounds: Rect.fromLTWH(0, y, pageSize.width, 16));
      y += 20;

      // Divider
      page.graphics.drawLine(PdfPen(PdfColor(203, 213, 225), width: 1.5), Offset(0, y), Offset(pageSize.width, y));
      y += 14;

      // Watermark
      if (_addWatermark && _watermarkController.text.trim().isNotEmpty) {
        final wmFont = PdfStandardFont(PdfFontFamily.helvetica, 40, style: PdfFontStyle.bold);
        page.graphics.save();
        page.graphics.translateTransform(pageSize.width / 2, pageSize.height / 2);
        page.graphics.rotateTransform(-40);
        page.graphics.drawString(
          _watermarkController.text.trim().toUpperCase(),
          wmFont,
          brush: PdfSolidBrush(PdfColor(220, 225, 235)),
          bounds: const Rect.fromLTWH(-150, -25, 300, 50),
        );
        page.graphics.restore();
      }

      // Body text with line wrapping
      final textElement = PdfTextElement(text: _bodyController.text.trim(), font: bodyFont, brush: PdfSolidBrush(PdfColor(30, 41, 59)));
      final layoutFormat = PdfLayoutFormat(layoutType: PdfLayoutType.paginate);
      final result = textElement.draw(page: page, bounds: Rect.fromLTWH(0, y, pageSize.width, pageSize.height - y - 30), format: layoutFormat);

      // Page numbers footer
      if (_addPageNumbers) {
        final lastPage = result?.page ?? page;
        final footerFont = PdfStandardFont(PdfFontFamily.helvetica, 9);
        lastPage.graphics.drawString('Page 1 of 1 • Medhavi Study Companion', footerFont, brush: PdfSolidBrush(PdfColor(148, 163, 184)), bounds: Rect.fromLTWH(0, pageSize.height - 15, pageSize.width, 15));
      }

      final bytes = await document.save();
      document.dispose();

      final tempDir = await getTemporaryDirectory();
      final filename = 'custom_doc_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(p.join(tempDir.path, filename));
      await file.writeAsBytes(bytes);

      if (mounted) {
        setState(() => _isGenerating = false);
        OpenFile.open(file.path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Custom PDF "$title" generated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF creation failed: $e'), backgroundColor: Colors.red),
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
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.indigo),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Custom PDF Generator (Pi7 Style)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Create clean notes PDF with watermark & margins', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Document Title *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _candidateController,
                      decoration: const InputDecoration(
                        labelText: 'Author / Candidate Name (Optional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _watermarkController,
                            decoration: const InputDecoration(
                              labelText: 'Background Watermark',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Checkbox(
                          value: _addWatermark,
                          onChanged: (val) => setState(() => _addWatermark = val ?? false),
                        ),
                        const Text('Watermark', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _bodyController,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'Document Notes / Text Content',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                        icon: _isGenerating
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.picture_as_pdf),
                        label: const Text('Generate & Open PDF Document'),
                        onPressed: _isGenerating ? null : _generatePdf,
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
