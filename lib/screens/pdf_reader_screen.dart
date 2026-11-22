import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:open_file/open_file.dart';
import '../models/pdf_document.dart';
import '../database/pdf_repo.dart';
import '../database/flashcard_repo.dart';
import '../database/note_repo.dart';
import '../database/reading_repo.dart';

class PdfReaderScreen extends StatefulWidget {
  final PdfDocument pdf;

  const PdfReaderScreen({Key? key, required this.pdf}) : super(key: key);

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
  }

  @override
  void dispose() {
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
    final notes = widget.pdf.id != null ? await _noteRepo.getNotesForPdf(widget.pdf.id!) : [];
    final textCtrl = TextEditingController();

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
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                                  child: Text('P${n.pageNumber}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                title: Text(n.noteText),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  onPressed: () async {
                                    await _noteRepo.deleteNote(n.id!);
                                    final updated = await _noteRepo.getNotesForPdf(widget.pdf.id!);
                                    setSheetState(() => notes.clear());
                                    setSheetState(() => notes.addAll(updated));
                                  },
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
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    setState(() {
      _currentPage = details.newPageNumber;
      _pagesTurned++;
    });
    _pdfRepo.updateReadingProgress(widget.pdf.id!, details.newPageNumber, _pageCount);

    if (details.newPageNumber == _pageCount && !_isCompleted) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.pdf.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Page $_currentPage of $_pageCount',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          // Favorite Star Toggle
          IconButton(
            icon: Icon(_isFavorite ? Icons.star : Icons.star_border, color: _isFavorite ? Colors.amber : null),
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
          IconButton(
            icon: const Icon(Icons.style),
            tooltip: 'Create Flashcard',
            onPressed: _showAddFlashcardDialog,
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
          // Mark as Complete Toggle
          IconButton(
            icon: Icon(
              _isCompleted ? Icons.check_circle : Icons.check_circle_outline,
              color: _isCompleted ? Colors.green : null,
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
                  color: isDark ? Colors.grey[900] : Colors.grey[100],
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: 'Search text in document...',
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
                          style: const TextStyle(fontSize: 12),
                        ),
                        IconButton(
                          icon: const Icon(Icons.navigate_before),
                          onPressed: () => _searchResult.previousInstance(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.navigate_next),
                          onPressed: () => _searchResult.nextInstance(),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            : null,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? (isDark ? const Color(0xFF1E293B) : Colors.white),
            border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
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
                        _filterMode == 'night'
                            ? Icons.dark_mode
                            : _filterMode == 'sepia'
                                ? Icons.wb_twilight
                                : Icons.wb_sunny_outlined,
                        size: 18,
                        color: _filterMode == 'sepia' ? Colors.amber[800] : null,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _filterMode == 'night'
                            ? 'Night Mode'
                            : _filterMode == 'sepia'
                                ? 'Sepia Paper'
                                : 'Day Mode',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _filterMode == 'sepia' ? Colors.amber[800] : null,
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
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _scrollDirection == PdfScrollDirection.vertical ? 'Vertical' : 'Page Flip',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

              // Estimated Pace Remaining
              Text(
                '~${((_pageCount - _currentPage) * 1.5).round().clamp(1, 999)}m left',
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
      body: ColorFiltered(
        colorFilter: _getActiveColorFilter(),
        child: SfPdfViewer.file(
          File(widget.pdf.localPath),
          controller: _pdfViewerController,
          scrollDirection: _scrollDirection,
          onDocumentLoaded: _onDocumentLoaded,
          onPageChanged: _onPageChanged,
          canShowScrollHead: true,
          canShowScrollStatus: true,
          enableDoubleTapZooming: true,
          pageSpacing: 4,
        ),
      ),
    );
  }
}
