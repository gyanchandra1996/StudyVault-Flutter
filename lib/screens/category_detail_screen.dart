import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/share_service.dart';
import '../models/category.dart';
import '../models/pdf_document.dart';
import '../database/category_repo.dart';
import '../database/pdf_repo.dart';
import '../providers/settings_provider.dart';
import '../services/pdf_storage_service.dart';
import 'pdf_reader_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final Category category;
  final List<Category> breadcrumbPath;

  const CategoryDetailScreen({
    Key? key,
    required this.category,
    this.breadcrumbPath = const [],
  }) : super(key: key);

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final CategoryRepo _catRepo = CategoryRepo();
  final PdfRepo _pdfRepo = PdfRepo();

  List<Category> _subcategories = [];
  Map<int, int> _subPdfCounts = {};
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

    final Map<int, int> counts = {};
    for (final s in subs) {
      if (s.id != null) {
        counts[s.id!] = await _catRepo.getPdfCountForCategory(s.id!);
      }
    }

    setState(() {
      _subcategories = subs;
      _subPdfCounts = counts;
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

  void _showAddSubcategoryDialog() {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.create_new_folder, color: Colors.indigo),
            SizedBox(width: 8),
            Text('New Subfolder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inside: ${widget.category.title}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Subfolder Name',
                hintText: 'e.g. Data Structures, Modern History',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final text = titleController.text.trim();
              if (text.isNotEmpty) {
                final newCat = Category(
                  title: text,
                  parentId: widget.category.id,
                  examId: widget.category.examId,
                  color: widget.category.color,
                  icon: 'folder',
                );
                await _catRepo.insertCategory(newCat);
                Navigator.pop(ctx);
                _loadData();
              }
            },
            child: const Text('Create Folder'),
          ),
        ],
      ),
    );
  }

  void _showActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEEF2FF),
                  child: Icon(Icons.create_new_folder, color: Colors.indigo),
                ),
                title: const Text('New Subcategory / Folder', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Create a nested folder (e.g. Data Structures)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddSubcategoryDialog();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFEF2F2),
                  child: Icon(Icons.upload_file, color: Colors.red),
                ),
                title: const Text('Import PDF Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Add PDF document directly to this folder'),
                onTap: () {
                  Navigator.pop(ctx);
                  _addPdf();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deletePdf(PdfDocument pdf) async {
    await _pdfRepo.deletePdf(pdf.id!);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final showDelete = settings.showDeleteActions;
    final isGrid = settings.isCategoryGridView;

    final fullBreadcrumb = widget.breadcrumbPath.isEmpty
        ? [widget.category]
        : widget.breadcrumbPath;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.title),
        actions: [
          IconButton(
            icon: Icon(isGrid ? Icons.view_list : Icons.grid_view),
            tooltip: isGrid ? 'Switch to List View' : 'Switch to Grid View',
            onPressed: () => settings.toggleCategoryViewMode(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Content'),
        onPressed: _showActionSheet,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Breadcrumb Navigation Bar
                  if (fullBreadcrumb.length > 1) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Icon(Icons.home, size: 16, color: Colors.indigo),
                            const SizedBox(width: 4),
                            ...fullBreadcrumb.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final cat = entry.value;
                              final isLast = idx == fullBreadcrumb.length - 1;

                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (idx > 0)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      child: Icon(Icons.chevron_right, size: 14, color: Colors.grey),
                                    ),
                                  Text(
                                    cat.title,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                                      color: isLast ? Colors.indigo : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Subfolders Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.folder_copy_outlined, color: Colors.indigo, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Subfolders (${_subcategories.length})',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.create_new_folder, size: 16),
                        label: const Text('New Folder', style: TextStyle(fontSize: 12)),
                        onPressed: _showAddSubcategoryDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_subcategories.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline, size: 18, color: Colors.grey),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No subfolders here. Tap "+ New Folder" to organize by topic (e.g. Data Structures).',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isGrid)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.4,
                      ),
                      itemCount: _subcategories.length,
                      itemBuilder: (ctx, idx) {
                        final sub = _subcategories[idx];
                        final pdfCount = _subPdfCounts[sub.id] ?? 0;
                        return _buildFolderGridCard(sub, pdfCount, fullBreadcrumb);
                      },
                    )
                  else
                    ..._subcategories.map((sub) {
                      final pdfCount = _subPdfCounts[sub.id] ?? 0;
                      return _buildFolderListTile(sub, pdfCount, fullBreadcrumb);
                    }),
                  const SizedBox(height: 24),

                  // Study Notes & PDFs Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Colors.red, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Documents & Notes (${_pdfs.length})',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.upload_file, size: 16),
                        label: const Text('Import PDF', style: TextStyle(fontSize: 12)),
                        onPressed: _addPdf,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_pdfs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: const [
                          Icon(Icons.picture_as_pdf, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'No PDFs in this folder.\nTap "+ Import PDF" to add study materials!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 13),
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.share_outlined, size: 20, color: Colors.grey),
                                tooltip: 'Share PDF',
                                onPressed: () {
                                  ShareService.sharePdf(pdf.localPath, title: pdf.title);
                                },
                              ),
                              if (showDelete)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                  onPressed: () => _deletePdf(pdf),
                                ),
                            ],
                          ),
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
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildFolderGridCard(Category sub, int pdfCount, List<Category> breadcrumb) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryDetailScreen(
              category: sub,
              breadcrumbPath: [...breadcrumb, sub],
            ),
          ),
        ).then((_) => _loadData());
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.indigo.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.indigo.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.folder, color: Colors.indigo, size: 28),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '📄 $pdfCount',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                ),
              ],
            ),
            Text(
              sub.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderListTile(Category sub, int pdfCount, List<Category> breadcrumb) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.withOpacity(0.1),
          child: const Icon(Icons.folder, color: Colors.indigo),
        ),
        title: Text(sub.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text('📄 $pdfCount Documents inside', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryDetailScreen(
                category: sub,
                breadcrumbPath: [...breadcrumb, sub],
              ),
            ),
          ).then((_) => _loadData());
        },
      ),
    );
  }
}
