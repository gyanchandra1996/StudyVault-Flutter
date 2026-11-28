import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/study_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/category_visual_picker.dart';
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
    showCategoryEditorDialog(
      context: context,
      examId: study.selectedExam?.id,
      onSave: (cat) async {
        await study.addCategory(cat);
      },
    );
  }

  void _showEditCategoryDialog(BuildContext context, StudyProvider study, Category cat) {
    showCategoryEditorDialog(
      context: context,
      existing: cat,
      onSave: (updated) async {
        await study.updateCategory(updated);
      },
    );
  }

  Future<void> _confirmDeleteCategory(BuildContext context, StudyProvider study, Category cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Delete "${cat.title}" and all its nested topics?'),
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
    if (confirm == true && cat.id != null) {
      await study.deleteCategory(cat.id!);
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
        title: const Text('All Categories', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (settings.canManageFolders)
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
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.78,
                              ),
                              itemCount: filteredCategories.length,
                              itemBuilder: (ctx, idx) {
                                final cat = filteredCategories[idx];
                                final stats = study.statsFor(cat.id);
                                final isDark = Theme.of(context).brightness == Brightness.dark;
                                final catColor = parseCategoryColor(cat.color);
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
                                  onLongPress: settings.canEdit
                                      ? () => _showEditCategoryDialog(context, study, cat)
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            const SizedBox(height: 2),
                                            CategoryVisualBadge(
                                              category: cat,
                                              size: 46,
                                              borderRadius: 13,
                                            ),
                                            Text(
                                              cat.title,
                                              maxLines: 2,
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                height: 1.15,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: catColor.withOpacity(0.10),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      '${stats.directSubcategoryCount} Topics',
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w700,
                                                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Icon(
                                                    Icons.chevron_right_rounded,
                                                    size: 13,
                                                    color: catColor,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (settings.canEdit)
                                          Positioned(
                                            top: -6,
                                            right: -6,
                                            child: PopupMenuButton<String>(
                                              icon: Icon(Icons.more_vert, size: 16, color: Colors.grey.shade500),
                                              padding: EdgeInsets.zero,
                                              onSelected: (v) {
                                                if (v == 'edit') {
                                                  _showEditCategoryDialog(context, study, cat);
                                                } else if (v == 'delete') {
                                                  _confirmDeleteCategory(context, study, cat);
                                                }
                                              },
                                              itemBuilder: (_) => [
                                                const PopupMenuItem(value: 'edit', child: Text('Edit Category')),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            ),
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
                                final stats = study.statsFor(cat.id);
                                return Card(
                                  elevation: 1,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: accent.withOpacity(0.15)),
                                  ),
                                  child: ListTile(
                                    leading: CategoryVisualBadge(category: cat, size: 42, circular: true),
                                    title: Text(
                                      cat.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      cat.description.isNotEmpty
                                          ? '${cat.description} • 📁 ${stats.directSubcategoryCount} • 📄 ${stats.pdfCount} • ❓ ${stats.questionCount}'
                                          : '📁 ${stats.directSubcategoryCount} Topics • 📄 ${stats.pdfCount} Files • ❓ ${stats.questionCount} Qs',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (settings.canEdit)
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 19, color: Colors.blueGrey),
                                            onPressed: () => _showEditCategoryDialog(context, study, cat),
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                          onPressed: () => _confirmDeleteCategory(context, study, cat),
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
