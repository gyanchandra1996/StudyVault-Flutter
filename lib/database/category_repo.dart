import '../models/category.dart';
import 'app_database.dart';

class CategoryStats {
  final int directSubcategoryCount;
  final int totalSubcategoryCount;
  final int pdfCount;
  final int questionCount;

  const CategoryStats({
    this.directSubcategoryCount = 0,
    this.totalSubcategoryCount = 0,
    this.pdfCount = 0,
    this.questionCount = 0,
  });
}

class CategoryRepo {
  final AppDatabase dbProvider = AppDatabase.instance;

  Future<List<Category>> getCategoriesByExam(int? examId) async {
    final db = await dbProvider.database;
    final res = await db.query(
      'categories',
      where: examId == null ? 'exam_id IS NULL AND parent_id IS NULL' : 'exam_id = ? AND parent_id IS NULL',
      whereArgs: examId == null ? null : [examId],
      orderBy: 'id ASC',
    );
    return res.map((m) => Category.fromMap(m)).toList();
  }

  Future<List<Category>> getSubcategories(int parentId) async {
    final db = await dbProvider.database;
    final res = await db.query(
      'categories',
      where: 'parent_id = ?',
      whereArgs: [parentId],
      orderBy: 'id ASC',
    );
    return res.map((m) => Category.fromMap(m)).toList();
  }

  Future<List<Category>> getAllCategories() async {
    final db = await dbProvider.database;
    final res = await db.query('categories', orderBy: 'id ASC');
    return res.map((m) => Category.fromMap(m)).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await dbProvider.database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await dbProvider.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<Category?> getCategoryById(int id) async {
    final db = await dbProvider.database;
    final res = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) return Category.fromMap(res.first);
    return null;
  }

  Future<int> getSubcategoryCount(int parentId) async {
    final db = await dbProvider.database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM categories WHERE parent_id = ?',
      [parentId],
    );
    return (res.first['count'] as int?) ?? 0;
  }

  Future<int> getQuestionCountForCategory(int categoryId, {bool recursive = true}) async {
    final db = await dbProvider.database;
    if (!recursive) {
      final res = await db.rawQuery(
        'SELECT COUNT(*) as count FROM quiz_questions WHERE category_id = ?',
        [categoryId],
      );
      return (res.first['count'] as int?) ?? 0;
    }

    final allCatIds = await getAllDescendantIds(categoryId);
    final placeholders = List.filled(allCatIds.length, '?').join(',');
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM quiz_questions WHERE category_id IN ($placeholders)',
      allCatIds.toList(),
    );
    return (res.first['count'] as int?) ?? 0;
  }

  Future<Set<int>> getAllDescendantIds(int categoryId) async {
    final db = await dbProvider.database;
    final Set<int> allCatIds = {categoryId};
    List<int> currentLevel = [categoryId];
    while (currentLevel.isNotEmpty) {
      final placeholders = List.filled(currentLevel.length, '?').join(',');
      final childRes = await db.rawQuery(
        'SELECT id FROM categories WHERE parent_id IN ($placeholders)',
        currentLevel,
      );
      currentLevel = childRes.map((r) => r['id'] as int).toList();
      allCatIds.addAll(currentLevel);
    }
    return allCatIds;
  }

  Future<int> getPdfCountForCategory(int categoryId, {bool recursive = true}) async {
    final db = await dbProvider.database;
    if (!recursive) {
      final res = await db.rawQuery(
        'SELECT COUNT(*) as count FROM pdfs WHERE category_id = ? AND is_deleted = 0',
        [categoryId],
      );
      return (res.first['count'] as int?) ?? 0;
    }

    final allCatIds = await getAllDescendantIds(categoryId);
    final placeholders = List.filled(allCatIds.length, '?').join(',');
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM pdfs WHERE category_id IN ($placeholders) AND is_deleted = 0',
      allCatIds.toList(),
    );
    return (res.first['count'] as int?) ?? 0;
  }

  /// Computes recursive subcategory, PDF, and question counts for all categories in 3 fast queries.
  Future<Map<int, CategoryStats>> getAllCategoryStats() async {
    final db = await dbProvider.database;
    final catRows = await db.rawQuery('SELECT id, parent_id FROM categories');
    final pdfRows = await db.rawQuery(
      'SELECT category_id, COUNT(*) as c FROM pdfs WHERE is_deleted = 0 AND category_id IS NOT NULL GROUP BY category_id',
    );
    final qRows = await db.rawQuery(
      'SELECT category_id, COUNT(*) as c FROM quiz_questions WHERE category_id IS NOT NULL GROUP BY category_id',
    );

    final Set<int> allIds = {};
    final Map<int, List<int>> children = {};
    for (final row in catRows) {
      final id = row['id'] as int?;
      if (id == null) continue;
      allIds.add(id);
      children.putIfAbsent(id, () => []);
      final parentId = row['parent_id'] as int?;
      if (parentId != null) {
        children.putIfAbsent(parentId, () => []).add(id);
      }
    }

    final Map<int, int> directPdfs = {};
    for (final row in pdfRows) {
      final cid = row['category_id'] as int?;
      final c = (row['c'] as int?) ?? 0;
      if (cid != null) directPdfs[cid] = c;
    }

    final Map<int, int> directQuestions = {};
    for (final row in qRows) {
      final cid = row['category_id'] as int?;
      final c = (row['c'] as int?) ?? 0;
      if (cid != null) directQuestions[cid] = c;
    }

    final Map<int, CategoryStats> memo = {};
    CategoryStats compute(int id, Set<int> visiting) {
      if (memo.containsKey(id)) return memo[id]!;
      if (visiting.contains(id)) return const CategoryStats();
      visiting.add(id);

      final directSubs = children[id] ?? const <int>[];
      int totalSubs = directSubs.length;
      int pdfs = directPdfs[id] ?? 0;
      int questions = directQuestions[id] ?? 0;

      for (final childId in directSubs) {
        final childStats = compute(childId, visiting);
        totalSubs += childStats.totalSubcategoryCount;
        pdfs += childStats.pdfCount;
        questions += childStats.questionCount;
      }

      visiting.remove(id);
      final stats = CategoryStats(
        directSubcategoryCount: directSubs.length,
        totalSubcategoryCount: totalSubs,
        pdfCount: pdfs,
        questionCount: questions,
      );
      memo[id] = stats;
      return stats;
    }

    for (final id in allIds) {
      compute(id, <int>{});
    }
    return memo;
  }

  Future<List<Category>> getCategoryHierarchyPath(int categoryId) async {
    final List<Category> path = [];
    int? currentId = categoryId;
    while (currentId != null) {
      final cat = await getCategoryById(currentId);
      if (cat != null) {
        path.insert(0, cat);
        currentId = cat.parentId;
      } else {
        break;
      }
    }
    return path;
  }

  Future<int> deleteCategory(int id) async {
    final db = await dbProvider.database;
    // Recursively delete children
    final descendants = await getAllDescendantIds(id);
    final placeholders = List.filled(descendants.length, '?').join(',');
    await db.delete(
      'categories',
      where: 'id IN ($placeholders)',
      whereArgs: descendants.toList(),
    );
    return descendants.length;
  }

  Future<void> seedDefaultHierarchicalCategories(int? examId) async {
    final db = await dbProvider.database;
    final countRes = await db.rawQuery('SELECT COUNT(*) as c FROM categories');
    final total = (countRes.first['c'] as int?) ?? 0;
    if (total > 0) {
      // Check if "Computer Science" has subcategories like "Data Structures"
      final csCats = await db.query('categories', where: 'title LIKE ?', whereArgs: ['%Computer Science%']);
      if (csCats.isNotEmpty) {
        final csId = csCats.first['id'] as int;
        final subCount = await getSubcategoryCount(csId);
        if (subCount == 0) {
          await _seedCsHierarchy(csId, examId);
        }
      }
      return;
    }

    // 1. Root: Computer Science
    final csId = await insertCategory(Category(
      title: 'Computer Science',
      description: 'Core CS Subjects, Algorithms, Operating Systems & Engineering',
      color: '#2563EB',
      icon: 'computer',
      examId: examId,
    ));
    await _seedCsHierarchy(csId, examId);

    // 2. Root: Quantitative Aptitude
    final quantId = await insertCategory(Category(
      title: 'Quantitative Aptitude',
      description: 'Arithmetic, Algebra, Geometry, Data Interpretation',
      color: '#10B981',
      icon: 'calculate',
      examId: examId,
    ));
    final arithId = await insertCategory(Category(
      title: 'Arithmetic',
      description: 'Core arithmetic math problems',
      color: '#10B981',
      icon: 'calculate',
      parentId: quantId,
      examId: examId,
    ));
    await insertCategory(Category(
      title: 'Percentages & Profit Loss',
      description: 'Markup, Discount, Cost Price',
      color: '#10B981',
      icon: 'calculate',
      parentId: arithId,
      examId: examId,
    ));
    await insertCategory(Category(
      title: 'Time, Speed & Distance',
      description: 'Trains, Boats, Work and Wages',
      color: '#10B981',
      icon: 'calculate',
      parentId: arithId,
      examId: examId,
    ));

    // 3. Root: Reasoning & Logic
    final reasonId = await insertCategory(Category(
      title: 'Reasoning & Mental Ability',
      description: 'Verbal, Non-Verbal, Analytical & Logical Reasoning',
      color: '#F59E0B',
      icon: 'psychology',
      examId: examId,
    ));
    final verbalId = await insertCategory(Category(
      title: 'Verbal Reasoning',
      description: 'Series, Puzzles, Coding-Decoding',
      color: '#F59E0B',
      icon: 'psychology',
      parentId: reasonId,
      examId: examId,
    ));
    await insertCategory(Category(
      title: 'Coding-Decoding & Series',
      description: 'Letter and number series patterns',
      color: '#F59E0B',
      icon: 'psychology',
      parentId: verbalId,
      examId: examId,
    ));
    await insertCategory(Category(
      title: 'Syllogism & Deductive Logic',
      description: 'Statements and Venn diagrams',
      color: '#F59E0B',
      icon: 'psychology',
      parentId: verbalId,
      examId: examId,
    ));

    // 4. Root: General Studies & GK
    final gsId = await insertCategory(Category(
      title: 'General Studies & GK',
      description: 'Indian Polity, History, Geography & Current Affairs',
      color: '#EC4899',
      icon: 'public',
      examId: examId,
    ));
    final polityId = await insertCategory(Category(
      title: 'Indian Polity & Constitution',
      description: 'Fundamental Rights, Parliament, Articles',
      color: '#EC4899',
      icon: 'public',
      parentId: gsId,
      examId: examId,
    ));
    await insertCategory(Category(
      title: 'Fundamental Rights & Duties',
      description: 'Article 12-35, 51A',
      color: '#EC4899',
      icon: 'public',
      parentId: polityId,
      examId: examId,
    ));
  }

  Future<void> _seedCsHierarchy(int csId, int? examId) async {
    // Subcategory 1: Data Structures
    final dsId = await insertCategory(Category(
      title: 'Data Structures',
      description: 'Linear & Non-linear data structures, Algorithms & Complexity',
      color: '#2563EB',
      icon: 'folder',
      parentId: csId,
      examId: examId,
    ));

    // Topics under Data Structures: Stack, Queue, Linked List, Trees
    await insertCategory(Category(
      title: 'Stack',
      description: 'LIFO, Push/Pop, Infix to Postfix, Recursion call stack',
      color: '#3B82F6',
      icon: 'menu_book',
      parentId: dsId,
      examId: examId,
    ));
    await insertCategory(Category(
      title: 'Queue',
      description: 'FIFO, Circular Queue, Priority Queue, Deque',
      color: '#3B82F6',
      icon: 'menu_book',
      parentId: dsId,
      examId: examId,
    ));
    await insertCategory(Category(
      title: 'Linked List',
      description: 'Singly, Doubly, Circular Linked List operations',
      color: '#3B82F6',
      icon: 'menu_book',
      parentId: dsId,
      examId: examId,
    ));
    await insertCategory(Category(
      title: 'Trees & Binary Search Trees',
      description: 'Traversals (Inorder, Preorder, Postorder), AVL, Heap',
      color: '#3B82F6',
      icon: 'menu_book',
      parentId: dsId,
      examId: examId,
    ));

    // Subcategory 2: Operating Systems
    final osId = await insertCategory(Category(
      title: 'Operating Systems',
      description: 'Process Scheduling, Memory Management, Deadlocks, Paging',
      color: '#6366F1',
      icon: 'folder',
      parentId: csId,
      examId: examId,
    ));

    // Topics under Operating Systems
    await insertCategory(Category(
      title: 'Process Management & Scheduling',
      description: 'FCFS, SJF, Round Robin, Context Switch, PCB',
      color: '#6366F1',
      icon: 'menu_book',
      parentId: osId,
      examId: examId,
    ));
    await insertCategory(Category(
      title: 'Memory Management & Paging',
      description: 'Virtual Memory, Page Fault, FIFO, LRU, Segmentation',
      color: '#6366F1',
      icon: 'menu_book',
      parentId: osId,
      examId: examId,
    ));
    await insertCategory(Category(
      title: 'Deadlocks & Concurrency',
      description: 'Mutual Exclusion, Banker Algorithm, Semaphores',
      color: '#6366F1',
      icon: 'menu_book',
      parentId: osId,
      examId: examId,
    ));

    // Subcategory 3: Database Management Systems
    final dbmsId = await insertCategory(Category(
      title: 'Database Management (DBMS)',
      description: 'Relational Model, Normalization, SQL, Transactions & ACID',
      color: '#0D9488',
      icon: 'folder',
      parentId: csId,
      examId: examId,
    ));
    await insertCategory(Category(
      title: 'SQL & Relational Algebra',
      description: 'Queries, Joins, Subqueries, Constraints',
      color: '#0D9488',
      icon: 'menu_book',
      parentId: dbmsId,
      examId: examId,
    ));
    await insertCategory(Category(
      title: 'Normalization (1NF to BCNF)',
      description: 'Functional dependencies, Candidate keys, Lossless join',
      color: '#0D9488',
      icon: 'menu_book',
      parentId: dbmsId,
      examId: examId,
    ));
  }
}
