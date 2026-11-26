import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/share_service.dart';
import '../models/category.dart';
import '../models/pdf_document.dart';
import '../models/quiz_result.dart';
import '../database/category_repo.dart';
import '../database/pdf_repo.dart';
import '../database/quiz_repo.dart';
import '../providers/settings_provider.dart';
import '../services/pdf_storage_service.dart';
import '../widgets/ai_quiz_modal.dart';
import '../widgets/ai_notes_generator_modal.dart';
import '../widgets/question_modal.dart';
import '../widgets/import_questions_dialog.dart';
import 'pdf_reader_screen.dart';
import 'quiz_runner_screen.dart';
import 'quiz_scorecard_screen.dart';

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
  final QuizRepo _quizRepo = QuizRepo();

  List<Category> _subcategories = [];
  Map<int, int> _subPdfCounts = {};
  List<PdfDocument> _pdfs = [];
  List<QuizResult> _quizzes = [];
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

    final allQuizzes = await _quizRepo.getAllResults();
    final catQuizzes = allQuizzes.where((r) =>
      r.displayCategory.toLowerCase() == widget.category.title.toLowerCase() ||
      r.categoryId == widget.category.id
    ).toList();

    setState(() {
      _subcategories = subs;
      _subPdfCounts = counts;
      _pdfs = pdfDocs;
      _quizzes = catQuizzes;
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
                title: const Text('New Subcategory / Topic', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Create a nested topic (e.g. Stack, Queue, Linked List)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddSubcategoryDialog();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF0FDF4),
                  child: Icon(Icons.table_chart, color: Colors.teal),
                ),
                title: const Text('Import CSV Quiz / Questions', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Import questions from CSV file directly into this category'),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => ImportQuestionsDialog(
                      initialCategory: widget.category.title,
                      initialCategoryId: widget.category.id,
                      examId: widget.category.examId,
                      onImported: _loadData,
                    ),
                  );
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
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.add_task, color: Colors.indigo),
                ),
                title: const Text('Add Question to Bank', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Create a manual question for this category'),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => QuestionModal(
                      initialCategory: widget.category.title,
                      initialCategoryId: widget.category.id,
                      examId: widget.category.examId,
                      onSaved: _loadData,
                    ),
                  );
                },
              ),
              if (Provider.of<SettingsProvider>(context, listen: false).isAiEnabled &&
                  Provider.of<SettingsProvider>(context, listen: false).isAiPdfNotesEnabled) ...[
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF3E8FF),
                    child: Icon(Icons.auto_awesome, color: Colors.purple),
                  ),
                  title: const Text('Generate AI PDF Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('AI writes structured notes and saves directly as PDF'),
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (_) => AiNotesGeneratorModal(onGenerated: _loadData),
                    );
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF0FDF4),
                    child: Icon(Icons.quiz, color: Colors.green),
                  ),
                  title: const Text('Create AI Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Generate MCQs and test your knowledge'),
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (_) => AiQuizModal(
                        initialCategory: widget.category.title,
                        initialCategoryId: widget.category.id,
                        examId: widget.category.examId,
                        onGenerated: _loadData,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameCategoryDialog(Category cat) {
    final titleController = TextEditingController(text: cat.title);
    final descController = TextEditingController(text: cat.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.edit, color: Color(0xFF1E3A8A)),
            SizedBox(width: 8),
            Text('Rename Topic / Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'New Name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
                isDense: true,
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
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (titleController.text.trim().isNotEmpty) {
                final updated = cat.copyWith(
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                );
                await _catRepo.updateCategory(updated);
                Navigator.pop(ctx);
                _loadData();
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
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
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Rename Category',
            onPressed: () => _showRenameCategoryDialog(widget.category),
          ),
          // Edit Mode toggle pill
          InkWell(
            onTap: () {
              settings.toggleEditMode();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(settings.isEditMode ? '✏️ Edit Mode ON: You can add and edit topics/quizzes' : '👁️ View Only Mode: Content is in read-only mode'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: settings.isEditMode ? Colors.orange.withOpacity(0.18) : Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: settings.isEditMode ? Colors.orange : Colors.blue,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    settings.isEditMode ? Icons.edit_note : Icons.visibility_outlined,
                    size: 16,
                    color: settings.isEditMode ? Colors.orange.shade800 : Colors.blue.shade800,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    settings.isEditMode ? 'Edit' : 'View',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: settings.isEditMode ? Colors.orange.shade900 : Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(isGrid ? Icons.view_list : Icons.grid_view),
            tooltip: isGrid ? 'Switch to List View' : 'Switch to Grid View',
            onPressed: () => settings.toggleCategoryViewMode(),
          ),
        ],
      ),
      floatingActionButton: settings.isEditMode
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Content'),
              onPressed: _showActionSheet,
            )
          : null,
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
                            'Subtopics / Folders (${_subcategories.length})',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (settings.isEditMode)
                        TextButton.icon(
                          icon: const Icon(Icons.create_new_folder, size: 16),
                          label: const Text('New Topic', style: TextStyle(fontSize: 12)),
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
                      if (settings.isEditMode)
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
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
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
                  const SizedBox(height: 24),

                  // Category Quizzes Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.quiz_outlined, color: Colors.purple, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Quizzes (${_quizzes.length})',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (settings.isEditMode)
                        Row(
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.table_chart, size: 15, color: Colors.teal),
                              label: const Text('CSV Quiz', style: TextStyle(fontSize: 12, color: Colors.teal)),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => ImportQuestionsDialog(
                                    initialCategory: widget.category.title,
                                    initialCategoryId: widget.category.id,
                                    examId: widget.category.examId,
                                    onImported: _loadData,
                                  ),
                                );
                              },
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.auto_awesome, size: 15, color: Colors.purple),
                              label: const Text('AI Quiz', style: TextStyle(fontSize: 12, color: Colors.purple)),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AiQuizModal(
                                    initialCategory: widget.category.title,
                                    initialCategoryId: widget.category.id,
                                    examId: widget.category.examId,
                                    onGenerated: _loadData,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_quizzes.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.purple.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.quiz, size: 18, color: Colors.purple),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              (settings.isAiEnabled && settings.isAiQuizEnabled)
                                  ? 'No quizzes created for ${widget.category.title} yet. Tap "+ AI Quiz" to generate one!'
                                  : 'No quizzes created for ${widget.category.title} yet. Tap "+ Question" to add questions!',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._quizzes.map((quiz) => _buildCategoryQuizCard(quiz, settings)),
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
      onLongPress: () => _showRenameCategoryDialog(sub),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.indigo.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.indigo.withOpacity(0.22), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.folder, color: Colors.indigo, size: 28),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _showRenameCategoryDialog(sub),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.edit, size: 14, color: Colors.blueGrey),
                      ),
                    ),
                    const SizedBox(width: 4),
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
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.indigo.withOpacity(0.12)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.withOpacity(0.1),
          child: const Icon(Icons.folder, color: Colors.indigo),
        ),
        title: Text(sub.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text('📄 $pdfCount Documents inside', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
              tooltip: 'Rename Folder',
              onPressed: () => _showRenameCategoryDialog(sub),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
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

  Widget _buildCategoryQuizCard(QuizResult r, SettingsProvider settings) {
    final isPassed = r.scorePercentage >= 60;
    final statusColor = isPassed ? Colors.green : Colors.orange;

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.35), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: statusColor.withOpacity(0.12),
                  child: Text(
                    '${r.scorePercentage}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: isPassed ? Colors.green.shade800 : Colors.orange.shade900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.quizTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${r.correctAnswers}/${r.totalQuestions} Correct • ⏱️ ${r.formattedDuration}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                if (settings.showDeleteActions)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                    onPressed: () async {
                      if (r.id != null) {
                        await _quizRepo.deleteQuizResult(r.id!);
                        _loadData();
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 6),
            const Divider(height: 1),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.visibility_outlined, size: 16, color: Colors.indigo),
                  label: const Text('Review', style: TextStyle(fontSize: 12, color: Colors.indigo)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizScorecardScreen(
                          quizTitle: r.quizTitle,
                          categoryName: r.displayCategory,
                          categoryId: r.categoryId,
                          questions: r.parsedQuestions,
                          selectedAnswers: r.parsedUserAnswers,
                          correctCount: r.correctAnswers,
                          durationSeconds: r.durationSeconds,
                        ),
                      ),
                    ).then((_) => _loadData());
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.replay, size: 14, color: Colors.white),
                  label: const Text('Re-attempt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizRunnerScreen(
                          questions: r.parsedQuestions,
                          quizTitle: r.quizTitle,
                          categoryName: r.displayCategory,
                          categoryId: r.categoryId,
                          existingResultId: r.id,
                          durationMinutes: r.durationSeconds > 0 ? ((r.durationSeconds + 59) ~/ 60) : null,
                        ),
                      ),
                    ).then((_) => _loadData());
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
