import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/study_provider.dart';
import '../services/pdf_tools_service.dart';
import '../database/pdf_repo.dart';
import '../models/pdf_document.dart';
import '../screens/pdf_reader_screen.dart';

class PdfToolsModal extends StatefulWidget {
  final VoidCallback onUpdated;

  const PdfToolsModal({Key? key, required this.onUpdated}) : super(key: key);

  @override
  State<PdfToolsModal> createState() => _PdfToolsModalState();
}

class _PdfToolsModalState extends State<PdfToolsModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PdfRepo _pdfRepo = PdfRepo();
  List<PdfDocument> _allPdfs = [];
  bool _isLoadingPdfs = true;

  // 1. Image to PDF State
  final List<String> _selectedImagePaths = [];
  final TextEditingController _imageTitleController = TextEditingController(text: 'Scanned_Study_Notes');
  bool _isConvertingImages = false;

  // 2. Merge PDF State
  final Set<int> _selectedMergePdfIds = {};
  final TextEditingController _mergeTitleController = TextEditingController(text: 'Merged_Study_Notes');
  bool _isMergingPdfs = false;

  // 3. Edit PDF State
  PdfDocument? _selectedEditPdf;
  List<int> _editPagesToKeep = [];
  final TextEditingController _editTitleController = TextEditingController();
  bool _isSavingEditedPdf = false;

  // 4. Compress PDF State
  PdfDocument? _selectedCompressPdf;
  bool _isCompressingPdf = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadPdfs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _imageTitleController.dispose();
    _mergeTitleController.dispose();
    _editTitleController.dispose();
    super.dispose();
  }

  Future<void> _loadPdfs() async {
    final pdfs = await _pdfRepo.getAllPdfs();
    if (mounted) {
      setState(() {
        _allPdfs = pdfs;
        _isLoadingPdfs = false;
      });
    }
  }

  // Pick Images
  void _pickImages() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (res != null && res.paths.isNotEmpty) {
      setState(() {
        for (final p in res.paths) {
          if (p != null && !_selectedImagePaths.contains(p)) {
            _selectedImagePaths.add(p);
          }
        }
      });
    }
  }

  // Convert Images to PDF
  void _convertImagesToPdf() async {
    if (_selectedImagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 1 image.')),
      );
      return;
    }

    setState(() => _isConvertingImages = true);

    try {
      final study = Provider.of<StudyProvider>(context, listen: false);
      final pdfDoc = await PdfToolsService.convertImagesToPdf(
        _selectedImagePaths,
        _imageTitleController.text.trim().isNotEmpty ? _imageTitleController.text.trim() : 'Scanned_Notes',
        categoryId: study.selectedCategory?.id,
        examId: study.selectedExam?.id,
      );

      await study.loadInitialData();
      widget.onUpdated();

      if (mounted) {
        setState(() {
          _isConvertingImages = false;
          _selectedImagePaths.clear();
        });
        Navigator.pop(context);

        _showSuccessDialog('PDF Created! 📄', pdfDoc);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConvertingImages = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Merge Selected PDFs
  void _mergeSelectedPdfs() async {
    if (_selectedMergePdfIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 2 documents to merge.')),
      );
      return;
    }

    setState(() => _isMergingPdfs = true);

    try {
      final study = Provider.of<StudyProvider>(context, listen: false);
      final selectedDocs = _allPdfs.where((p) => _selectedMergePdfIds.contains(p.id)).toList();
      final paths = selectedDocs.map((p) => p.localPath).toList();

      final pdfDoc = await PdfToolsService.mergeMultiplePdfs(
        paths,
        _mergeTitleController.text.trim().isNotEmpty ? _mergeTitleController.text.trim() : 'Merged_Document',
        categoryId: study.selectedCategory?.id,
        examId: study.selectedExam?.id,
      );

      await study.loadInitialData();
      widget.onUpdated();

      if (mounted) {
        setState(() {
          _isMergingPdfs = false;
          _selectedMergePdfIds.clear();
        });
        Navigator.pop(context);

        _showSuccessDialog('Documents Merged! 📑', pdfDoc);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isMergingPdfs = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Merge error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Select PDF to Edit
  void _onSelectPdfToEdit(PdfDocument pdf) {
    setState(() {
      _selectedEditPdf = pdf;
      _editTitleController.text = '${pdf.title} (Trimmed)';
      final total = pdf.totalPages > 0 ? pdf.totalPages : 1;
      _editPagesToKeep = List.generate(total, (i) => i + 1);
    });
  }

  // Save Edited PDF
  void _saveEditedPdf() async {
    if (_selectedEditPdf == null || _editPagesToKeep.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least 1 page to retain.')),
      );
      return;
    }

    setState(() => _isSavingEditedPdf = true);

    try {
      final study = Provider.of<StudyProvider>(context, listen: false);
      final pdfDoc = await PdfToolsService.editPdfDocumentPages(
        _selectedEditPdf!.localPath,
        _editPagesToKeep,
        _editTitleController.text.trim().isNotEmpty ? _editTitleController.text.trim() : '${_selectedEditPdf!.title} (Edited)',
        categoryId: _selectedEditPdf!.categoryId,
        examId: _selectedEditPdf!.examId,
      );

      await study.loadInitialData();
      widget.onUpdated();

      if (mounted) {
        setState(() {
          _isSavingEditedPdf = false;
          _selectedEditPdf = null;
        });
        Navigator.pop(context);

        _showSuccessDialog('PDF Edited & Saved! ✂️', pdfDoc);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingEditedPdf = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Edit error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _compressPdf() async {
    if (_selectedCompressPdf == null) return;
    setState(() => _isCompressingPdf = true);
    try {
      final study = Provider.of<StudyProvider>(context, listen: false);
      final pdfDoc = await PdfToolsService.compressPdfDocument(
        _selectedCompressPdf!.localPath,
        '${_selectedCompressPdf!.title} (Optimized)',
        categoryId: _selectedCompressPdf!.categoryId,
        examId: _selectedCompressPdf!.examId,
      );
      await study.loadInitialData();
      widget.onUpdated();
      if (mounted) {
        setState(() {
          _isCompressingPdf = false;
        });
        Navigator.pop(context);
        _showSuccessDialog('PDF Compressed & Optimized! 🗜️', pdfDoc);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCompressingPdf = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Compress error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog(String title, PdfDocument pdf) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(
          '"${pdf.title}" has been saved into your vault with ${pdf.totalPages} pages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            icon: const Icon(Icons.menu_book),
            label: const Text('Open PDF'),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PdfReaderScreen(pdf: pdf)),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final accent = settings.activeAccentColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.deepOrange.withOpacity(0.18),
                    child: const Icon(Icons.build, color: Colors.deepOrange, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PDF Tools Suite',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Convert, Merge, Edit, and Extract Documents',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: accent,
              unselectedLabelColor: Colors.grey,
              indicatorColor: accent,
              tabs: const [
                Tab(icon: Icon(Icons.add_photo_alternate, size: 18), text: 'Image to PDF'),
                Tab(icon: Icon(Icons.merge, size: 18), text: 'Merge PDFs'),
                Tab(icon: Icon(Icons.cut, size: 18), text: 'Edit / Trim'),
                Tab(icon: Icon(Icons.compress, size: 18), text: 'Compress'),
                Tab(icon: Icon(Icons.image, size: 18), text: 'PDF to Image'),
              ],
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Image to PDF
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Photos & Scanned Pages',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Pick multiple images to combine into a single organized study PDF.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),

                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Pick Images from Device'),
                          onPressed: _pickImages,
                        ),
                        const SizedBox(height: 14),

                        if (_selectedImagePaths.isNotEmpty) ...[
                          Text(
                            'Selected Images (${_selectedImagePaths.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _selectedImagePaths.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (ctx, idx) {
                              final imgPath = _selectedImagePaths[idx];
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.image, color: Colors.indigo, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Page ${idx + 1}: ${imgPath.split(Platform.pathSeparator).last}',
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                      onPressed: () {
                                        setState(() => _selectedImagePaths.removeAt(idx));
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: _imageTitleController,
                            decoration: const InputDecoration(
                              labelText: 'Document Title',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 14),

                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                              ),
                              icon: _isConvertingImages
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.check),
                              label: Text(_isConvertingImages ? 'Converting Images to PDF...' : 'Create PDF Document (${_selectedImagePaths.length} Pages)'),
                              onPressed: _isConvertingImages ? null : _convertImagesToPdf,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Tab 2: Merge PDFs
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Combine Multiple PDF Documents',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Select two or more PDFs from your library to merge into one document.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),

                        if (_isLoadingPdfs)
                          const Center(child: CircularProgressIndicator())
                        else if (_allPdfs.isEmpty)
                          const Text('No PDFs in your library yet. Import PDFs first.')
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _allPdfs.length,
                            itemBuilder: (ctx, idx) {
                              final pdf = _allPdfs[idx];
                              final isSelected = _selectedMergePdfIds.contains(pdf.id);
                              return CheckboxListTile(
                                value: isSelected,
                                activeColor: Colors.indigo,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true && pdf.id != null) {
                                      _selectedMergePdfIds.add(pdf.id!);
                                    } else if (pdf.id != null) {
                                      _selectedMergePdfIds.remove(pdf.id!);
                                    }
                                  });
                                },
                                title: Text(pdf.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                subtitle: Text('${pdf.totalPages} pages', style: const TextStyle(fontSize: 11)),
                              );
                            },
                          ),
                        const SizedBox(height: 14),

                        TextField(
                          controller: _mergeTitleController,
                          decoration: const InputDecoration(
                            labelText: 'Merged Document Title',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 14),

                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                            ),
                            icon: _isMergingPdfs
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.merge),
                            label: Text(_isMergingPdfs ? 'Merging PDFs...' : 'Merge (${_selectedMergePdfIds.length} Selected)'),
                            onPressed: _selectedMergePdfIds.length >= 2 && !_isMergingPdfs ? _mergeSelectedPdfs : null,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab 3: Edit / Trim PDF
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedEditPdf == null) ...[
                          const Text(
                            'Select a Document to Edit',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Choose a PDF to delete unwanted pages or extract a chapter.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),

                          if (_allPdfs.isEmpty)
                            const Text('No PDFs found in library.')
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _allPdfs.length,
                              itemBuilder: (ctx, idx) {
                                final pdf = _allPdfs[idx];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: const Icon(Icons.picture_as_pdf, color: Colors.deepOrange),
                                    title: Text(pdf.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    subtitle: Text('${pdf.totalPages} pages'),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                    onTap: () => _onSelectPdfToEdit(pdf),
                                  ),
                                );
                              },
                            ),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Editing: ${_selectedEditPdf!.title}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(() => _selectedEditPdf = null),
                                child: const Text('Change PDF'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap page numbers to keep or remove them from the new document:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 10),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(_selectedEditPdf!.totalPages, (i) {
                              final pageNum = i + 1;
                              final isKept = _editPagesToKeep.contains(pageNum);
                              return FilterChip(
                                label: Text('Page $pageNum'),
                                selected: isKept,
                                selectedColor: Colors.deepOrange.withOpacity(0.2),
                                onSelected: (val) {
                                  setState(() {
                                    if (val) {
                                      _editPagesToKeep.add(pageNum);
                                      _editPagesToKeep.sort();
                                    } else {
                                      _editPagesToKeep.remove(pageNum);
                                    }
                                  });
                                },
                              );
                            }),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _editTitleController,
                            decoration: const InputDecoration(
                              labelText: 'New Document Title',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 14),

                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                foregroundColor: Colors.white,
                              ),
                              icon: _isSavingEditedPdf
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.content_cut),
                              label: Text(_isSavingEditedPdf ? 'Saving Trimmed PDF...' : 'Save Trimmed PDF (${_editPagesToKeep.length} Pages)'),
                              onPressed: _editPagesToKeep.isNotEmpty && !_isSavingEditedPdf ? _saveEditedPdf : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Tab 4: Compress PDF
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Compress & Optimize PDF File Size',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Reduce PDF size for online government job exam forms, email, and faster loading.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 14),

                        if (_selectedCompressPdf == null) ...[
                          const Text(
                            'Select a PDF from your vault to compress:',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          if (_allPdfs.isEmpty)
                            const Text('No PDFs found in library.')
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _allPdfs.length,
                              itemBuilder: (ctx, idx) {
                                final pdf = _allPdfs[idx];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Color(0xFFFEF3C7),
                                      child: Icon(Icons.compress, color: Colors.amber, size: 20),
                                    ),
                                    title: Text(pdf.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    subtitle: Text('${(pdf.fileSize / 1024).toStringAsFixed(1)} KB • ${pdf.totalPages} pages'),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                    onTap: () => setState(() => _selectedCompressPdf = pdf),
                                  ),
                                );
                              },
                            ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.description, color: Colors.amber, size: 24),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_selectedCompressPdf!.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          Text('Original Size: ${(_selectedCompressPdf!.fileSize / 1024).toStringAsFixed(1)} KB • ${_selectedCompressPdf!.totalPages} pages', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => setState(() => _selectedCompressPdf = null),
                                      child: const Text('Change'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade800,
                                foregroundColor: Colors.white,
                              ),
                              icon: _isCompressingPdf
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.compress),
                              label: Text(_isCompressingPdf ? 'Compressing & Optimizing...' : 'Compress PDF Now'),
                              onPressed: _isCompressingPdf ? null : _compressPdf,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Tab 5: PDF to Image
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PDF to Image & High-Res View',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Select any document from your vault to view pages in high-resolution mode.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 14),

                        if (_allPdfs.isEmpty)
                          const Text('No PDFs found in library.')
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _allPdfs.length,
                            itemBuilder: (ctx, idx) {
                              final pdf = _allPdfs[idx];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const Icon(Icons.image, color: Colors.purple),
                                  title: Text(pdf.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  subtitle: Text('${pdf.totalPages} pages • Tap to view captures'),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => PdfReaderScreen(pdf: pdf)),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
