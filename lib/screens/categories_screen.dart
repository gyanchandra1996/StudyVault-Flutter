import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/study_provider.dart';
import '../providers/settings_provider.dart';
import 'category_detail_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog(BuildContext context, StudyProvider study) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Subject / Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Category Title',
                hintText: 'e.g. Operating Systems, Algebra',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
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
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                study.addCategory(Category(
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                  examId: study.selectedExam?.id,
                ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'computer':
        return Icons.computer;
      case 'calculate':
        return Icons.calculate_outlined;
      case 'psychology':
        return Icons.psychology_outlined;
      case 'public':
        return Icons.public;
      case 'translate':
        return Icons.translate;
      case 'menu_book':
        return Icons.menu_book;
      default:
        return Icons.folder_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final study = Provider.of<StudyProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final accent = settings.activeAccentColor;

    final filteredCategories = study.categories.where((cat) {
      if (_searchQuery.trim().isEmpty) return true;
      return cat.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          cat.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects & Categories', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(settings.isCategoryGridView ? Icons.view_list : Icons.grid_view),
            tooltip: settings.isCategoryGridView ? 'Switch to List View' : 'Switch to Grid View',
            onPressed: () => settings.toggleCategoryViewMode(),
          ),
          if (settings.isStudyFolderAndImportEnabled)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add Category',
              onPressed: () => _showAddCategoryDialog(context, study),
            ),
        ],
      ),
      body: study.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search subjects & categories...',
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),

                // Exam Filter Chips
                if (study.exams.isNotEmpty)
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: study.exams.length,
                      itemBuilder: (ctx, idx) {
                        final exam = study.exams[idx];
                        final isSelected = study.selectedExam?.id == exam.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(exam.title),
                            selected: isSelected,
                            onSelected: (_) => study.selectExam(exam),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 8),

                // Category Grid View
                Expanded(
                  child: filteredCategories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              const Text('No Categories Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              const Text('Tap "+" above to add your first subject.', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : settings.isCategoryGridView
                          ? GridView.builder(
                              cacheExtent: 1500.0,
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.15,
                              ),
                              itemCount: filteredCategories.length,
                              itemBuilder: (ctx, idx) {
                                final cat = filteredCategories[idx];
                                final pdfCount = study.categoryPdfCounts[cat.id] ?? 0;
                                return InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CategoryDetailScreen(category: cat),
                                      ),
                                    ).then((_) => study.refreshRecentPdfs());
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: accent.withOpacity(0.25), width: 1.2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accent.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
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
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: accent.withOpacity(0.18),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Icon(_getIconData(cat.icon), color: accent, size: 22),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: accent.withOpacity(0.14),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    '📄 $pdfCount',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: accent,
                                                    ),
                                                  ),
                                                ),
                                                if (settings.showDeleteActions) ...[
                                                  const SizedBox(width: 4),
                                                  GestureDetector(
                                                    onTap: () => study.deleteCategory(cat.id!),
                                                    child: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              cat.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            if (cat.description.isNotEmpty) ...[
                                              const SizedBox(height: 3),
                                              Text(
                                                cat.description,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : ListView.builder(
                              cacheExtent: 1500.0,
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                              itemCount: filteredCategories.length,
                              itemBuilder: (ctx, idx) {
                                final cat = filteredCategories[idx];
                                final pdfCount = study.categoryPdfCounts[cat.id] ?? 0;
                                return Card(
                                  elevation: 1,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: accent.withOpacity(0.15)),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: accent.withOpacity(0.12),
                                      child: Icon(_getIconData(cat.icon), color: accent),
                                    ),
                                    title: Text(
                                      cat.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      cat.description.isNotEmpty
                                          ? '${cat.description} • 📄 $pdfCount PDFs'
                                          : '📄 $pdfCount PDFs inside',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (settings.showDeleteActions)
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                            onPressed: () => study.deleteCategory(cat.id!),
                                          ),
                                        const Icon(Icons.chevron_right, color: Colors.grey),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CategoryDetailScreen(category: cat),
                                        ),
                                      ).then((_) => study.refreshRecentPdfs());
                                    },
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}
