import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../database/ebook_repo.dart';
import '../models/ebook_item.dart';
import '../models/pdf_document.dart';
import '../providers/settings_provider.dart';
import '../services/share_service.dart';
import '../widgets/master_control_section.dart';
import 'pdf_reader_screen.dart';

class EbookLibraryScreen extends StatefulWidget {
  final String? initialAction; // null, 'add_pdf', 'add_images'

  const EbookLibraryScreen({Key? key, this.initialAction}) : super(key: key);

  @override
  State<EbookLibraryScreen> createState() => _EbookLibraryScreenState();
}

class _EbookLibraryScreenState extends State<EbookLibraryScreen> {
  final EbookRepo _ebookRepo = EbookRepo();
  final TextEditingController _searchController = TextEditingController();

  List<EbookItem> _ebooks = [];
  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  String _selectedFilter = 'all'; // 'all', 'pdf', 'image', 'favorites'
  String _searchQuery = '';
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadEbooks(showLoading: true);
    if (widget.initialAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        if (!settings.canManageFiles) {
          _promptEnableFileControl();
          return;
        }
        if (widget.initialAction == 'add_pdf') {
          _pickAndAddPdfEbook();
        } else if (widget.initialAction == 'add_images') {
          _pickAndAddImageEbook();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEbooks({bool showLoading = false}) async {
    if (showLoading || !_hasLoadedOnce) {
      setState(() => _isLoading = true);
    }
    final list = await _ebookRepo.getAllEbooks();
    if (!mounted) return;
    setState(() {
      _ebooks = list;
      _isLoading = false;
      _hasLoadedOnce = true;
    });
  }

  void _promptEnableFileControl() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('View-Only Mode: Enable Master Edit & File Controls to add E-Books.'),
        action: SnackBarAction(
          label: 'Controls',
          onPressed: () => showMasterControlModal(context),
        ),
      ),
    );
  }

  Future<Directory> _ensureEbookDir(String sub) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'ebooks', sub));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _pickAndAddPdfEbook() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.single.path == null) return;

      final srcPath = result.files.single.path!;
      final originalName = result.files.single.name;
      final dir = await _ensureEbookDir('pdfs');
      final safeName = '${DateTime.now().millisecondsSinceEpoch}_${originalName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';
      final savedFile = await File(srcPath).copy(p.join(dir.path, safeName));

      if (!mounted) return;
      await _showMetadataDialog(
        defaultTitle: p.basenameWithoutExtension(originalName),
        mediaType: 'pdf',
        filePath: savedFile.path,
        extraPaths: const [],
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add PDF E-Book: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickAndAddImageEbook() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: true,
      );
      if (result == null || result.files.isEmpty) return;

      final paths = result.files.map((f) => f.path).whereType<String>().toList();
      if (paths.isEmpty) return;

      final dir = await _ensureEbookDir('images');
      final copiedPaths = <String>[];
      final ts = DateTime.now().millisecondsSinceEpoch;
      for (int i = 0; i < paths.length; i++) {
        final ext = p.extension(paths[i]).isNotEmpty ? p.extension(paths[i]) : '.jpg';
        final target = p.join(dir.path, 'ebook_${ts}_$i$ext');
        final copied = await File(paths[i]).copy(target);
        copiedPaths.add(copied.path);
      }

      if (!mounted) return;
      final defaultName = copiedPaths.length == 1
          ? p.basenameWithoutExtension(result.files.first.name)
          : 'Image E-Book (${copiedPaths.length} Pages)';
      await _showMetadataDialog(
        defaultTitle: defaultName,
        mediaType: copiedPaths.length > 1 ? 'image_book' : 'image',
        filePath: copiedPaths.first,
        extraPaths: copiedPaths,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add Image E-Book: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _captureEbookFromCamera() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 90);
      if (picked == null) return;

      final dir = await _ensureEbookDir('images');
      final ext = p.extension(picked.path).isNotEmpty ? p.extension(picked.path) : '.jpg';
      final target = p.join(dir.path, 'cam_ebook_${DateTime.now().millisecondsSinceEpoch}$ext');
      final copied = await File(picked.path).copy(target);

      if (!mounted) return;
      await _showMetadataDialog(
        defaultTitle: 'Scanned E-Book Page',
        mediaType: 'image',
        filePath: copied.path,
        extraPaths: [copied.path],
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera capture error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showMetadataDialog({
    required String defaultTitle,
    required String mediaType,
    required String filePath,
    required List<String> extraPaths,
    EbookItem? existing,
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? defaultTitle);
    final authorCtrl = TextEditingController(text: existing?.author ?? '');
    final subjectCtrl = TextEditingController(text: existing?.subject ?? 'General');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(
              mediaType == 'pdf' ? Icons.picture_as_pdf : Icons.photo_library_outlined,
              color: const Color(0xFF1E3A8A),
            ),
            const SizedBox(width: 8),
            Text(
              existing == null ? 'Save E-Book to Library' : 'Edit E-Book Details',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'E-Book Title *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: authorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Author / Publisher (Optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: subjectCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subject / Category',
                  hintText: 'e.g. Polity, Physics, Computer Science',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes / Description (Optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final title = titleCtrl.text.trim().isEmpty ? defaultTitle : titleCtrl.text.trim();
              final subject = subjectCtrl.text.trim().isEmpty ? 'General' : subjectCtrl.text.trim();

              if (existing != null) {
                await _ebookRepo.updateEbook(
                  existing.copyWith(
                    title: title,
                    author: authorCtrl.text.trim(),
                    subject: subject,
                    notes: notesCtrl.text.trim(),
                  ),
                );
              } else {
                await _ebookRepo.insertEbook(
                  EbookItem(
                    title: title,
                    author: authorCtrl.text.trim(),
                    subject: subject,
                    mediaType: mediaType,
                    filePath: filePath,
                    extraPathsJson: jsonEncode(extraPaths),
                    coverPath: mediaType == 'pdf' ? '' : filePath,
                    totalPages: extraPaths.isNotEmpty ? extraPaths.length : 1,
                    notes: notesCtrl.text.trim(),
                  ),
                );
              }

              if (ctx.mounted) Navigator.pop(ctx);
              await _loadEbooks();
            },
            child: Text(existing == null ? 'Save E-Book' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _showAddEbookSheet() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (!settings.canManageFiles) {
      _promptEnableFileControl();
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add New E-Book',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Import PDF textbooks, reference images, or multi-page image books.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFEE2E2),
                  child: Icon(Icons.picture_as_pdf, color: Colors.red),
                ),
                title: const Text('Add PDF E-Book', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Import any .pdf book or study material'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndAddPdfEbook();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0E7FF),
                  child: Icon(Icons.photo_library_outlined, color: Colors.indigo),
                ),
                title: const Text('Add E-Book Image(s)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Select 1 cover/diagram or multiple book page images'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndAddImageEbook();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFCCFBF1),
                  child: Icon(Icons.camera_alt_outlined, color: Colors.teal),
                ),
                title: const Text('Snap Book Page with Camera', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Capture a textbook page directly as an E-Book'),
                onTap: () {
                  Navigator.pop(ctx);
                  _captureEbookFromCamera();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEbook(EbookItem ebook) {
    if (ebook.isPdf) {
      final f = File(ebook.filePath);
      if (!f.existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF file not found on device.')),
        );
        return;
      }
      final fileSize = f.lengthSync();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfReaderScreen(
            pdf: PdfDocument(
              title: ebook.title,
              localPath: ebook.filePath,
              fileSize: fileSize,
              totalPages: ebook.totalPages,
              lastPage: ebook.lastPage,
            ),
            onProgressChanged: (page, total) {
              if (ebook.id != null) {
                _ebookRepo.updateProgress(ebook.id!, page, total);
              }
            },
          ),
        ),
      ).then((_) => _loadEbooks());
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EbookImageReaderScreen(
            ebook: ebook,
            onUpdated: _loadEbooks,
          ),
        ),
      ).then((_) => _loadEbooks());
    }
  }

  Future<void> _confirmDelete(EbookItem ebook) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete E-Book?'),
        content: Text('Remove "${ebook.title}" from E-Book Library?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _ebookRepo.deleteEbook(ebook);
      await _loadEbooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBlue = Color(0xFF1E3A8A);

    final filtered = _ebooks.where((e) {
      if (_selectedFilter == 'pdf' && !e.isPdf) return false;
      if (_selectedFilter == 'image' && !e.isImageBased) return false;
      if (_selectedFilter == 'favorites' && e.isFavorite != 1) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!e.title.toLowerCase().contains(q) &&
            !e.author.toLowerCase().contains(q) &&
            !e.subject.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('E-Book Library & Reader', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: _isGridView ? 'List View' : 'Grid View',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          if (settings.canManageFiles)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add E-Book',
              onPressed: _showAddEbookSheet,
            ),
        ],
      ),
      floatingActionButton: settings.canManageFiles
          ? FloatingActionButton.extended(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text('Add E-Book'),
              onPressed: _showAddEbookSheet,
            )
          : null,
      body: Column(
        children: [
          // Search + Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search E-Books by title, author, subject...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                isDense: true,
              ),
            ),
          ),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('all', 'All (${_ebooks.length})'),
                const SizedBox(width: 8),
                _buildFilterChip('pdf', 'PDF E-Books (${_ebooks.where((e) => e.isPdf).length})'),
                const SizedBox(width: 8),
                _buildFilterChip('image', 'Image Books (${_ebooks.where((e) => e.isImageBased).length})'),
                const SizedBox(width: 8),
                _buildFilterChip('favorites', 'Favorites ★'),
              ],
            ),
          ),

          if (settings.canManageFiles) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.red),
                      label: const Text('+ E-Book PDF', style: TextStyle(fontSize: 12)),
                      onPressed: _pickAndAddPdfEbook,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library_outlined, size: 16, color: Colors.indigo),
                      label: const Text('+ E-Book Images', style: TextStyle(fontSize: 12)),
                      onPressed: _pickAndAddImageEbook,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_stories_outlined, size: 54, color: Colors.indigo.withOpacity(0.45)),
                              const SizedBox(height: 12),
                              const Text(
                                'Your E-Book Shelf is Empty',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                settings.canManageFiles
                                    ? 'Add PDF textbooks, reference diagrams, or multi-page image E-Books.'
                                    : 'Enable Master Edit & File Controls in Settings to add new E-Books.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    : (_isGridView
                        ? GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.78,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) => _buildEbookGridCard(filtered[i], settings, isDark),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) => _buildEbookListTile(filtered[i], settings),
                          )),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String id, String label) {
    final selected = _selectedFilter == id;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : null,
        ),
      ),
      selected: selected,
      selectedColor: const Color(0xFF1E3A8A),
      onSelected: (_) => setState(() => _selectedFilter = id),
    );
  }

  Widget _buildEbookGridCard(EbookItem ebook, SettingsProvider settings, bool isDark) {
    final hasCoverImage = ebook.isImageBased &&
        ebook.filePath.isNotEmpty &&
        File(ebook.filePath).existsSync();

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.indigo.withOpacity(0.18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openEbook(ebook),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Preview
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasCoverImage)
                    Image.file(File(ebook.filePath), fit: BoxFit.cover)
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: ebook.isPdf
                              ? [Colors.red.shade700, Colors.deepOrange.shade500]
                              : [Colors.indigo.shade700, Colors.blue.shade500],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          ebook.isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                          size: 46,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ebook.isPdf ? 'PDF' : '${ebook.imagePages.length} IMG',
                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: IconButton(
                      icon: Icon(
                        ebook.isFavorite == 1 ? Icons.star : Icons.star_border,
                        color: ebook.isFavorite == 1 ? Colors.amber : Colors.white,
                        size: 20,
                      ),
                      onPressed: () async {
                        if (ebook.id != null) {
                          await _ebookRepo.toggleFavorite(ebook.id!, ebook.isFavorite != 1);
                          await _loadEbooks();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ebook.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, height: 1.25),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ebook.author.isNotEmpty ? '${ebook.subject} • ${ebook.author}' : ebook.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'P.${ebook.lastPage}/${ebook.totalPages}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.indigo),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (settings.canEdit)
                            InkWell(
                              onTap: () => _showMetadataDialog(
                                defaultTitle: ebook.title,
                                mediaType: ebook.mediaType,
                                filePath: ebook.filePath,
                                extraPaths: ebook.imagePages,
                                existing: ebook,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(3),
                                child: Icon(Icons.edit_outlined, size: 15, color: Colors.blueGrey),
                              ),
                            ),
                          if (settings.canDelete)
                            InkWell(
                              onTap: () => _confirmDelete(ebook),
                              child: const Padding(
                                padding: EdgeInsets.all(3),
                                child: Icon(Icons.delete_outline, size: 15, color: Colors.redAccent),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEbookListTile(EbookItem ebook, SettingsProvider settings) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: () => _openEbook(ebook),
        leading: CircleAvatar(
          backgroundColor: (ebook.isPdf ? Colors.red : Colors.indigo).withOpacity(0.12),
          child: Icon(
            ebook.isPdf ? Icons.picture_as_pdf_rounded : Icons.photo_library_outlined,
            color: ebook.isPdf ? Colors.red : Colors.indigo,
          ),
        ),
        title: Text(ebook.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          '${ebook.mediaLabel} • ${ebook.subject} • Page ${ebook.lastPage}/${ebook.totalPages}',
          style: const TextStyle(fontSize: 11.5, color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                ebook.isFavorite == 1 ? Icons.star : Icons.star_border,
                color: ebook.isFavorite == 1 ? Colors.amber : Colors.grey,
                size: 20,
              ),
              onPressed: () async {
                if (ebook.id != null) {
                  await _ebookRepo.toggleFavorite(ebook.id!, ebook.isFavorite != 1);
                  await _loadEbooks();
                }
              },
            ),
            if (settings.canEdit)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                onPressed: () => _showMetadataDialog(
                  defaultTitle: ebook.title,
                  mediaType: ebook.mediaType,
                  filePath: ebook.filePath,
                  extraPaths: ebook.imagePages,
                  existing: ebook,
                ),
              ),
            if (settings.canDelete)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                onPressed: () => _confirmDelete(ebook),
              ),
          ],
        ),
      ),
    );
  }
}

/// Interactive Reader for Single-Image & Multi-Page Image E-Books
/// with pinch-to-zoom, Sepia Paper / Night eye-care filters, and page-adding.
class EbookImageReaderScreen extends StatefulWidget {
  final EbookItem ebook;
  final VoidCallback? onUpdated;

  const EbookImageReaderScreen({
    Key? key,
    required this.ebook,
    this.onUpdated,
  }) : super(key: key);

  @override
  State<EbookImageReaderScreen> createState() => _EbookImageReaderScreenState();
}

class _EbookImageReaderScreenState extends State<EbookImageReaderScreen> {
  final EbookRepo _ebookRepo = EbookRepo();
  late PageController _pageController;
  late List<String> _pages;
  late int _currentPage; // 1-based
  String _filterMode = 'original'; // 'original', 'sepia', 'night'

  @override
  void initState() {
    super.initState();
    _pages = List<String>.from(widget.ebook.imagePages);
    _currentPage = widget.ebook.lastPage.clamp(1, _pages.isNotEmpty ? _pages.length : 1);
    _pageController = PageController(initialPage: _currentPage - 1);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.readerFilter == 'sepia' ||
        settings.readerFilter == 'night' ||
        settings.readerFilter == 'original') {
      _filterMode = settings.readerFilter;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _appendPages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: true,
      );
      if (result == null || result.files.isEmpty) return;

      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(appDir.path, 'ebooks', 'images'));
      if (!await dir.exists()) await dir.create(recursive: true);

      final ts = DateTime.now().millisecondsSinceEpoch;
      final newPaths = <String>[];
      for (int i = 0; i < result.files.length; i++) {
        final src = result.files[i].path;
        if (src == null) continue;
        final ext = p.extension(src).isNotEmpty ? p.extension(src) : '.jpg';
        final copied = await File(src).copy(p.join(dir.path, 'ebook_page_${ts}_$i$ext'));
        newPaths.add(copied.path);
      }
      if (newPaths.isEmpty) return;

      final merged = [..._pages, ...newPaths];
      await _ebookRepo.updateEbook(
        widget.ebook.copyWith(
          mediaType: merged.length > 1 ? 'image_book' : 'image',
          extraPathsJson: jsonEncode(merged),
          totalPages: merged.length,
        ),
      );
      if (!mounted) return;
      setState(() => _pages = merged);
      widget.onUpdated?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add pages: $e')));
      }
    }
  }

  ColorFilter _getFilter() {
    switch (_filterMode) {
      case 'night':
        return const ColorFilter.matrix([
          -1,  0,  0, 0, 255,
           0, -1,  0, 0, 255,
           0,  0, -1, 0, 255,
           0,  0,  0, 1,   0,
        ]);
      case 'sepia':
        return const ColorFilter.mode(Color(0xFFE8D7B8), BlendMode.multiply);
      case 'original':
      default:
        return const ColorFilter.mode(Colors.transparent, BlendMode.multiply);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSepia = _filterMode == 'sepia';
    final bool isNight = _filterMode == 'night';

    final Color scaffoldBg = isSepia
        ? const Color(0xFFF3E5C8)
        : (isNight ? const Color(0xFF0B0F17) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)));
    final Color barBg = isSepia
        ? const Color(0xFFEBD9B7)
        : (isNight ? const Color(0xFF141B29) : (isDark ? const Color(0xFF1E293B) : Colors.white));
    final Color? fgColor = isSepia
        ? const Color(0xFF432F1E)
        : (isNight ? const Color(0xFFE2E8F0) : null);
    final Color mutedColor = isSepia
        ? const Color(0xFF73563D)
        : (isNight ? const Color(0xFF94A3B8) : Colors.grey);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: (isSepia || isNight) ? barBg : null,
        foregroundColor: fgColor,
        iconTheme: fgColor != null ? IconThemeData(color: fgColor) : null,
        actionsIconTheme: fgColor != null ? IconThemeData(color: fgColor) : null,
        systemOverlayStyle: isSepia
            ? SystemUiOverlayStyle.dark.copyWith(statusBarColor: barBg, systemNavigationBarColor: barBg)
            : (isNight
                ? SystemUiOverlayStyle.light.copyWith(statusBarColor: barBg, systemNavigationBarColor: barBg)
                : null),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.ebook.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: fgColor)),
            Text(
              'Page $_currentPage of ${_pages.length}',
              style: TextStyle(fontSize: 11.5, color: mutedColor),
            ),
          ],
        ),
        actions: [
          if (settings.canManageFiles)
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              tooltip: 'Add More Pages',
              onPressed: _appendPages,
            ),
          if (_pages.isNotEmpty && _currentPage - 1 < _pages.length)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share Current Page',
              onPressed: () => ShareService.shareFile(_pages[_currentPage - 1], title: widget.ebook.title),
            ),
        ],
      ),
      bottomNavigationBar: Material(
        color: barBg,
        child: SafeArea(
          top: false,
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: barBg,
              border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      if (_filterMode == 'original') {
                        _filterMode = 'sepia';
                      } else if (_filterMode == 'sepia') {
                        _filterMode = 'night';
                      } else {
                        _filterMode = 'original';
                      }
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        isNight ? Icons.dark_mode : (isSepia ? Icons.wb_twilight : Icons.wb_sunny_outlined),
                        size: 18,
                        color: isSepia ? const Color(0xFF8B4513) : (isNight ? Colors.amber.shade300 : fgColor),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isNight ? 'Night Mode' : (isSepia ? 'Sepia Paper' : 'Day Mode'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSepia ? const Color(0xFF5D3410) : fgColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: fgColor),
                      onPressed: _currentPage > 1
                          ? () => _pageController.previousPage(duration: const Duration(milliseconds: 220), curve: Curves.easeOut)
                          : null,
                    ),
                    Text('$_currentPage / ${_pages.length}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: fgColor)),
                    IconButton(
                      icon: Icon(Icons.chevron_right, color: fgColor),
                      onPressed: _currentPage < _pages.length
                          ? () => _pageController.nextPage(duration: const Duration(milliseconds: 220), curve: Curves.easeOut)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: _pages.isEmpty
          ? const Center(child: Text('No pages found for this E-Book.'))
          : PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (idx) {
                setState(() => _currentPage = idx + 1);
                if (widget.ebook.id != null) {
                  _ebookRepo.updateProgress(widget.ebook.id!, idx + 1, _pages.length);
                }
              },
              itemBuilder: (ctx, idx) {
                final file = File(_pages[idx]);
                if (!file.existsSync()) {
                  return const Center(child: Text('Image page missing on device.'));
                }
                final imgWidget = InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.file(file, fit: BoxFit.contain),
                  ),
                );
                if (_filterMode == 'original') return imgWidget;
                return ColorFiltered(colorFilter: _getFilter(), child: imgWidget);
              },
            ),
    );
  }
}
