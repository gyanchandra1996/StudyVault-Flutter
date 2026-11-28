import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:open_file/open_file.dart';
import '../providers/settings_provider.dart';
import '../services/share_service.dart';
import '../models/pdf_document.dart';
import '../database/pdf_repo.dart';
import '../database/flashcard_repo.dart';
import '../database/note_repo.dart';
import '../database/reading_repo.dart';
import '../widgets/formatted_note_content.dart';

class PdfReaderScreen extends StatefulWidget {
  final PdfDocument pdf;
  final void Function(int page, int totalPages)? onProgressChanged;

  const PdfReaderScreen({
    Key? key,
    required this.pdf,
    this.onProgressChanged,
  }) : super(key: key);

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  late PdfViewerController _pdfViewerController;
  late PdfTextSearchResult _searchResult;
  final PdfRepo _pdfRepo = PdfRepo();
  final FlashcardRepo _flashcardRepo = FlashcardRepo();
  final NoteRepo _noteRepo = NoteRepo();
  final ReadingRepo _readingRepo = ReadingRepo();
  final DateTime _sessionStart = DateTime.now();

  String _filterMode = 'original'; // 'original', 'sepia', 'night'
  PdfScrollDirection _scrollDirection = PdfScrollDirection.vertical;
  int _pagesTurned = 0;
  bool _isSearchActive = false;
  bool _isCompleted = false;
  bool _isFavorite = false;
  int _currentPage = 1;
  late final ValueNotifier<int> _currentPageNotifier;
  int _pageCount = 1;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _searchResult = PdfTextSearchResult();
    _isCompleted = widget.pdf.isCompleted == 1;
    _isFavorite = widget.pdf.isFavorite == 1;
    _currentPage = widget.pdf.lastPage > 0 ? widget.pdf.lastPage : 1;
    _currentPageNotifier = ValueNotifier<int>(_currentPage);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.readerFilter == 'sepia' ||
        settings.readerFilter == 'night' ||
        settings.readerFilter == 'original') {
      _filterMode = settings.readerFilter;
    }
    _scrollDirection = settings.scrollDirection == 'horizontal'
        ? PdfScrollDirection.horizontal
        : PdfScrollDirection.vertical;
  }

  @override
  void dispose() {
    _currentPageNotifier.dispose();
    final duration = DateTime.now().difference(_sessionStart).inSeconds;
    if (widget.pdf.id != null && duration >= 5) {
      _readingRepo.logReadingTime(widget.pdf.id!, duration, pagesRead: _pagesTurned);
    }
    _searchController.dispose();
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _toggleFavorite() async {
    final next = !_isFavorite;
    setState(() => _isFavorite = next);
    if (widget.pdf.id != null) {
      await _pdfRepo.toggleFavorite(widget.pdf.id!, next);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(next ? 'Added to Favorites ★' : 'Removed from Favorites')),
    );
  }

  void _showAddFlashcardDialog() {
    final qCtrl = TextEditingController();
    final aCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Create Flashcard (Page $_currentPage)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qCtrl,
              decoration: const InputDecoration(labelText: 'Question / Concept', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: aCtrl,
              decoration: const InputDecoration(labelText: 'Answer / Explanation', border: OutlineInputBorder()),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (qCtrl.text.trim().isNotEmpty && aCtrl.text.trim().isNotEmpty) {
                await _flashcardRepo.addFlashcard(
                  pdfId: widget.pdf.id,
                  pageNumber: _currentPage,
                  question: qCtrl.text.trim(),
                  answer: aCtrl.text.trim(),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Flashcard created! Scheduled for review.')),
                );
              }
            },
            child: const Text('Add Card'),
          ),
        ],
      ),
    );
  }

  void _showScratchpadDialog() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final notes = widget.pdf.id != null ? await _noteRepo.getNotesForPdf(widget.pdf.id!) : [];
    final textCtrl = TextEditingController();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 20,
            left: 16,
            right: 16,
          ),
          child: SizedBox(
            height: 480,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Document Scratchpad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 8),
                if (settings.canEdit)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: textCtrl,
                          decoration: InputDecoration(
                            hintText: 'Jot down note on Page $_currentPage...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
                        onPressed: () async {
                          if (textCtrl.text.trim().isNotEmpty) {
                            await _noteRepo.addNote(
                              pdfId: widget.pdf.id,
                              pageNumber: _currentPage,
                              noteText: textCtrl.text.trim(),
                            );
                            textCtrl.clear();
                            final updated = await _noteRepo.getNotesForPdf(widget.pdf.id!);
                            setSheetState(() => notes.clear());
                            setSheetState(() => notes.addAll(updated));
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'View-Only Mode: Enable Master Edit Mode to add or edit notes.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text('Saved Notes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                Expanded(
                  child: notes.isEmpty
                      ? const Center(child: Text('No notes yet for this document.', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: notes.length,
                          itemBuilder: (ctx, i) {
                            final n = notes[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                                      child: Text('P${n.pageNumber}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FormattedNoteContent(
                                        data: n.noteText,
                                        accentColor: const Color(0xFF6366F1),
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (settings.canDelete)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                        onPressed: () async {
                                          await _noteRepo.deleteNote(n.id!);
                                          final updated = await _noteRepo.getNotesForPdf(widget.pdf.id!);
                                          setSheetState(() => notes.clear());
                                          setSheetState(() => notes.addAll(updated));
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    setState(() {
      _pageCount = details.document.pages.count;
    });
    if (widget.pdf.lastPage > 1 && widget.pdf.lastPage <= _pageCount) {
      _pdfViewerController.jumpToPage(widget.pdf.lastPage);
    }
    widget.onProgressChanged?.call(_currentPage, _pageCount);
  }

  int _lastRecordedPage = -1;
  void _onPageChanged(PdfPageChangedDetails details) {
    if (_lastRecordedPage == details.newPageNumber) return;
    _lastRecordedPage = details.newPageNumber;
    _currentPage = details.newPageNumber;
    _currentPageNotifier.value = details.newPageNumber;
    _pagesTurned++;
    if (widget.pdf.id != null) {
      _pdfRepo.updateReadingProgress(widget.pdf.id!, details.newPageNumber, _pageCount);
    }
    widget.onProgressChanged?.call(details.newPageNumber, _pageCount);

    if (details.newPageNumber == _pageCount && !_isCompleted && widget.pdf.id != null) {
      _toggleCompleted(true);
    }
  }

  ColorFilter _getActiveColorFilter() {
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

  void _toggleCompleted(bool value) async {
    setState(() {
      _isCompleted = value;
    });
    if (widget.pdf.id != null) {
      await _pdfRepo.toggleCompleted(widget.pdf.id!, value);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Marked as completed! Great job!' : 'Marked as in progress.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _sharePdf() async {
    final file = File(widget.pdf.localPath);
    if (await file.exists()) {
      await ShareService.sharePdf(widget.pdf.localPath, title: widget.pdf.title);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File not found on device.')),
      );
    }
  }

  void _openInExternalViewer() async {
    try {
      final res = await OpenFile.open(widget.pdf.localPath);
      if (res.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open external viewer: ${res.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file: $e')),
      );
    }
  }

  void _showJumpToPageDialog() {
    final controller = TextEditingController(text: '$_currentPage');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Go to Page'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter page (1 - $_pageCount)',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= _pageCount) {
                _pdfViewerController.jumpToPage(page);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfView() {
    final pdfViewer = SfPdfViewer.file(
      File(widget.pdf.localPath),
      key: ValueKey('sf_viewer_${widget.pdf.id ?? widget.pdf.localPath}'),
      controller: _pdfViewerController,
      scrollDirection: _scrollDirection,
      pageLayoutMode: PdfPageLayoutMode.continuous,
      onDocumentLoaded: _onDocumentLoaded,
      onPageChanged: _onPageChanged,
      canShowScrollHead: false,
      canShowScrollStatus: false,
      canShowPaginationDialog: false,
      enableDoubleTapZooming: true,
      pageSpacing: 4,
    );

    if (_filterMode == 'original') {
      return RepaintBoundary(child: pdfViewer);
    }

    return RepaintBoundary(
      child: ColorFiltered(
        colorFilter: _getActiveColorFilter(),
        child: pdfViewer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = Provider.of<SettingsProvider>(context);
    final bool isSepia = _filterMode == 'sepia';
    final bool isNight = _filterMode == 'night';

    final Color? scaffoldBg = isSepia
        ? const Color(0xFFF3E5C8)
        : (isNight ? const Color(0xFF0B0F17) : null);
    final Color barBg = isSepia
        ? const Color(0xFFEBD9B7)
        : (isNight
            ? const Color(0xFF141B29)
            : (Theme.of(context).cardTheme.color ??
                (isDark ? const Color(0xFF1E293B) : Colors.white)));
    final Color searchBg = isSepia
        ? const Color(0xFFE3CEA7)
        : (isNight
            ? const Color(0xFF1E293B)
            : (isDark ? Colors.grey[900]! : Colors.grey[100]!));
    final Color? fgColor = isSepia
        ? const Color(0xFF432F1E)
        : (isNight ? const Color(0xFFE2E8F0) : null);
    final Color mutedColor = isSepia
        ? const Color(0xFF73563D)
        : (isNight ? const Color(0xFF94A3B8) : Colors.grey);
    final Color borderColor = isSepia
        ? const Color(0xFFD5BE94)
        : (isNight
            ? const Color(0xFF263145)
            : Colors.grey.withOpacity(0.2));

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: (isSepia || isNight) ? barBg : null,
        foregroundColor: fgColor,
        iconTheme: fgColor != null ? IconThemeData(color: fgColor) : null,
        actionsIconTheme: fgColor != null ? IconThemeData(color: fgColor) : null,
        elevation: (isSepia || isNight) ? 0 : null,
        bottomOpacity: 1.0,
        systemOverlayStyle: isSepia
            ? SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: barBg,
                systemNavigationBarColor: barBg,
              )
            : (isNight
                ? SystemUiOverlayStyle.light.copyWith(
                    statusBarColor: barBg,
                    systemNavigationBarColor: barBg,
                  )
                : null),
        shape: (isSepia || isNight)
            ? Border(bottom: BorderSide(color: borderColor))
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.pdf.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: fgColor,
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: _currentPageNotifier,
              builder: (ctx, page, _) => Text(
                'Page $page of $_pageCount',
                style: TextStyle(fontSize: 12, color: mutedColor),
              ),
            ),
          ],
        ),
        actions: [
          if (widget.pdf.id != null) ...[
            // Favorite Star Toggle
            IconButton(
              icon: Icon(_isFavorite ? Icons.star : Icons.star_border, color: _isFavorite ? Colors.amber : fgColor),
              tooltip: _isFavorite ? 'Starred' : 'Add to Favorites',
              onPressed: _toggleFavorite,
            ),
            // Scratchpad Modal
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: 'Document Scratchpad',
              onPressed: _showScratchpadDialog,
            ),
            // Create Flashcard
            if (settings.canEdit)
              IconButton(
                icon: const Icon(Icons.style),
                tooltip: 'Create Flashcard',
                onPressed: _showAddFlashcardDialog,
              ),
          ],
          // Share PDF
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share PDF File',
            onPressed: _sharePdf,
          ),
          // Open in Native / Device Viewer
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Open in Device PDF App',
            onPressed: _openInExternalViewer,
          ),
          // Search in Document
          IconButton(
            icon: Icon(_isSearchActive ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchActive = !_isSearchActive;
                if (!_isSearchActive) {
                  _searchResult.clear();
                  _searchController.clear();
                }
              });
            },
          ),
          if (widget.pdf.id != null)
            // Mark as Complete Toggle
            IconButton(
              icon: Icon(
                _isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                color: _isCompleted ? Colors.green : fgColor,
              ),
              tooltip: _isCompleted ? 'Marked Complete' : 'Mark as Complete',
              onPressed: () => _toggleCompleted(!_isCompleted),
            ),
          // Go to Page
          IconButton(
            icon: const Icon(Icons.dialpad),
            tooltip: 'Go to Page',
            onPressed: _showJumpToPageDialog,
          ),
        ],
        bottom: _isSearchActive
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: searchBg,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: TextStyle(color: fgColor),
                          decoration: InputDecoration(
                            hintText: 'Search text in document...',
                            hintStyle: TextStyle(color: mutedColor),
                            isDense: true,
                            border: InputBorder.none,
                          ),
                          onSubmitted: (query) {
                            _searchResult = _pdfViewerController.searchText(query);
                            setState(() {});
                          },
                        ),
                      ),
                      if (_searchResult.hasResult) ...[
                        Text(
                          '${_searchResult.currentInstanceIndex}/${_searchResult.totalInstanceCount}',
                          style: TextStyle(fontSize: 12, color: fgColor),
                        ),
                        IconButton(
                          icon: Icon(Icons.navigate_before, color: fgColor),
                          onPressed: () => _searchResult.previousInstance(),
                        ),
                        IconButton(
                          icon: Icon(Icons.navigate_next, color: fgColor),
                          onPressed: () => _searchResult.nextInstance(),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            : null,
      ),
      bottomNavigationBar: Material(
        color: barBg,
        child: SafeArea(
          top: false,
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: barBg,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Eye-Care Reading Filter
                InkWell(
                  borderRadius: BorderRadius.circular(8),
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          isNight
                              ? Icons.dark_mode
                              : isSepia
                                  ? Icons.wb_twilight
                                  : Icons.wb_sunny_outlined,
                          size: 18,
                          color: isSepia
                              ? const Color(0xFF8B4513)
                              : (isNight ? Colors.amber.shade300 : null),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isNight
                              ? 'Night Mode'
                              : isSepia
                                  ? 'Sepia Paper'
                                  : 'Day Mode',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSepia
                                ? const Color(0xFF5D3410)
                                : (isNight ? Colors.amber.shade200 : null),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Scroll Orientation Toggle
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      _scrollDirection = _scrollDirection == PdfScrollDirection.vertical
                          ? PdfScrollDirection.horizontal
                          : PdfScrollDirection.vertical;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          _scrollDirection == PdfScrollDirection.vertical
                              ? Icons.swap_vert
                              : Icons.swap_horiz,
                          size: 18,
                          color: fgColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _scrollDirection == PdfScrollDirection.vertical ? 'Vertical' : 'Page Flip',
                          style: TextStyle(fontSize: 12, color: fgColor),
                        ),
                      ],
                    ),
                  ),
                ),

                // Estimated Pace Remaining
                ValueListenableBuilder<int>(
                  valueListenable: _currentPageNotifier,
                  builder: (ctx, page, _) => Text(
                    '~${((_pageCount - page) * 1.5).round().clamp(1, 999)}m left',
                    style: TextStyle(fontSize: 12, color: mutedColor, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        color: scaffoldBg,
        child: _buildPdfView(),
      ),
    );
  }
}
