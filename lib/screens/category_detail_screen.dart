import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/pdf_document.dart';
import '../database/category_repo.dart';
import '../database/pdf_repo.dart';
import '../providers/settings_provider.dart';
import '../services/pdf_storage_service.dart';
import 'pdf_reader_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final Category category;

  const CategoryDetailScreen({Key? key, required this.category}) : super(key: key);

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final CategoryRepo _catRepo = CategoryRepo();
  final PdfRepo _pdfRepo = PdfRepo();

  List<Category> _subcategories = [];
  List<PdfDocument> _pdfs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final subs = await _catRepo.getSubcategories(widget.category.id!);
    final pdfDocs = await _pdfRepo.getPdfsByCategory(widget.category.id!);
    setState(() {
      _subcategories = subs;
      _pdfs = pdfDocs;
      _isLoading = false;
    });
  }

  void _addPdf() async {
    final pdf = await PdfStorageService.pickAndSavePdf(
      categoryId: widget.category.id,
      examId: widget.category.examId,
    );
    if (pdf != null) {
      await _pdfRepo.insertPdf(pdf);
      _loadData();
    }
  }

  void _deletePdf(PdfDocument pdf) async {
    await _pdfRepo.deletePdf(pdf.id!);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final showDelete = Provider.of<SettingsProvider>(context).showDeleteActions;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_subcategories.isNotEmpty) ...[
                  const Text(
                    'Subcategories',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _subcategories.map((sub) {
                      return ActionChip(
                        avatar: const Icon(Icons.folder, size: 18),
                        label: Text(sub.title),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CategoryDetailScreen(category: sub),
                            ),
                          ).then((_) => _loadData());
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Study Notes & PDFs',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_pdfs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Column(
                      children: const [
                        Icon(Icons.picture_as_pdf, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No PDFs added yet.\nTap + to import your notes!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                else
                  ..._pdfs.map((pdf) {
                    final mbSize = (pdf.fileSize / (1024 * 1024)).toStringAsFixed(1);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        ),
                        title: Text(
                          pdf.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${mbSize}MB • Page ${pdf.lastPage}/${pdf.totalPages} ${pdf.isCompleted == 1 ? "• ✓ Completed" : ""}',
                          style: TextStyle(
                            fontSize: 12,
                            color: pdf.isCompleted == 1 ? Colors.green : Colors.grey,
                          ),
                        ),
                        trailing: showDelete
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                onPressed: () => _deletePdf(pdf),
                              )
                            : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PdfReaderScreen(pdf: pdf),
                            ),
                          ).then((_) => _loadData());
                        },
                      ),
                    );
                  }),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPdf,
        icon: const Icon(Icons.add),
        label: const Text('Add PDF Note'),
      ),
    );
  }
}
