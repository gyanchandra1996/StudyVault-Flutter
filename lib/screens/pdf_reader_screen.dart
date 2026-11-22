import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:open_file/open_file.dart';
import '../models/pdf_document.dart';
import '../database/pdf_repo.dart';

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

  bool _isNightMode = false;
  bool _isSearchActive = false;
  bool _isCompleted = false;
  int _currentPage = 1;
  int _pageCount = 1;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _searchResult = PdfTextSearchResult();
    _isCompleted = widget.pdf.isCompleted == 1;
    _currentPage = widget.pdf.lastPage > 0 ? widget.pdf.lastPage : 1;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pdfViewerController.dispose();
    super.dispose();
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
    });
    _pdfRepo.updateReadingProgress(widget.pdf.id!, details.newPageNumber, _pageCount);

    if (details.newPageNumber == _pageCount && !_isCompleted) {
      _toggleCompleted(true);
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
          // Night Mode Toggle
          IconButton(
            icon: Icon(_isNightMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                _isNightMode = !_isNightMode;
              });
            },
          ),
          // Go to Page
          IconButton(
            icon: const Icon(Icons.dialpad),
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
      body: ColorFiltered(
        colorFilter: _isNightMode
            ? const ColorFilter.matrix([
                -1,  0,  0, 0, 255,
                 0, -1,  0, 0, 255,
                 0,  0, -1, 0, 255,
                 0,  0,  0, 1,   0,
              ])
            : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
        child: SfPdfViewer.file(
          File(widget.pdf.localPath),
          controller: _pdfViewerController,
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
