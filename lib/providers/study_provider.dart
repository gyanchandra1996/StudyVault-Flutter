import 'package:flutter/material.dart';
import '../models/exam.dart';
import '../models/category.dart';
import '../models/pdf_document.dart';
import '../database/exam_repo.dart';
import '../database/category_repo.dart';
import '../database/pdf_repo.dart';

class StudyProvider extends ChangeNotifier {
  final ExamRepo _examRepo = ExamRepo();
  final CategoryRepo _categoryRepo = CategoryRepo();
  final PdfRepo _pdfRepo = PdfRepo();

  List<Exam> _exams = [];
  Exam? _selectedExam;
  List<Category> _categories = [];
  Map<int, int> _categoryPdfCounts = {};
  List<PdfDocument> _recentPdfs = [];
  bool _isLoading = false;

  List<Exam> get exams => _exams;
  Exam? get selectedExam => _selectedExam;
  List<Category> get categories => _categories;
  Map<int, int> get categoryPdfCounts => _categoryPdfCounts;
  List<PdfDocument> get recentPdfs => _recentPdfs;
  bool get isLoading => _isLoading;

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    _exams = await _examRepo.getAllExams();
    if (_exams.isEmpty) {
      final defaultExamId = await _examRepo.insertExam(Exam(
        title: 'General Competition & Govt Exams',
        description: 'DSSSB, SSC, EMRS, Railway & State Exams',
        color: '#6366F1',
        icon: 'school',
      ));
      final defaultExam = await _examRepo.getExamById(defaultExamId);
      if (defaultExam != null) {
        _exams = [defaultExam];
        _selectedExam = defaultExam;
      }
    } else if (_selectedExam == null) {
      _selectedExam = _exams.first;
    }

    await loadCategoriesForSelectedExam();

    if (_categories.isEmpty && _selectedExam != null) {
      final defaultCats = [
        Category(
          title: 'Computer Science & IT',
          description: 'Architecture, Networking, DBMS, Operating Systems & Programming',
          color: '#6366F1',
          icon: 'computer',
          examId: _selectedExam!.id,
        ),
        Category(
          title: 'Arithmetic & Quantitative Aptitude',
          description: 'Percentage, Profit-Loss, Time & Work, Algebra, Number System',
          color: '#10B981',
          icon: 'calculate',
          examId: _selectedExam!.id,
        ),
        Category(
          title: 'Reasoning & Mental Ability',
          description: 'Verbal & Non-Verbal Logic, Puzzles, Series, Syllogism',
          color: '#F59E0B',
          icon: 'psychology',
          examId: _selectedExam!.id,
        ),
        Category(
          title: 'General Knowledge & Current Affairs',
          description: 'History, Polity, Geography, Economy, Science & Daily News',
          color: '#EC4899',
          icon: 'public',
          examId: _selectedExam!.id,
        ),
        Category(
          title: 'General English & Grammar',
          description: 'Vocabulary, Comprehension, Idioms & Error Spotting',
          color: '#8B5CF6',
          icon: 'translate',
          examId: _selectedExam!.id,
        ),
        Category(
          title: 'Hindi Vyakaran (हिंदी व्याकरण)',
          description: 'संधि, समास, मुहावरे, पर्यायवाची, विलोम शब्द एवं अपठित गद्यांश',
          color: '#06B6D4',
          icon: 'menu_book',
          examId: _selectedExam!.id,
        ),
      ];

      for (var cat in defaultCats) {
        await _categoryRepo.insertCategory(cat);
      }
      await loadCategoriesForSelectedExam();
    }

    _recentPdfs = await _pdfRepo.getRecentPdfs();

    _isLoading = false;
    notifyListeners();
  }

  void selectExam(Exam? exam) async {
    _selectedExam = exam;
    await loadCategoriesForSelectedExam();
    notifyListeners();
  }

  Future<void> loadCategoriesForSelectedExam() async {
    _categories = await _categoryRepo.getCategoriesByExam(_selectedExam?.id);
    final Map<int, int> counts = {};
    for (final cat in _categories) {
      if (cat.id != null) {
        counts[cat.id!] = await _categoryRepo.getPdfCountForCategory(cat.id!);
      }
    }
    _categoryPdfCounts = counts;
    notifyListeners();
  }

  Future<void> addExam(Exam exam) async {
    final id = await _examRepo.insertExam(exam);
    final created = Exam(
      id: id,
      title: exam.title,
      description: exam.description,
      color: exam.color,
      icon: exam.icon,
      createdAt: exam.createdAt,
    );
    _exams.add(created);
    if (_selectedExam == null) {
      _selectedExam = created;
      await loadCategoriesForSelectedExam();
    }
    notifyListeners();
  }

  Future<void> deleteExam(int examId) async {
    await _examRepo.deleteExam(examId);
    _exams.removeWhere((e) => e.id == examId);
    if (_selectedExam?.id == examId) {
      _selectedExam = _exams.isNotEmpty ? _exams.first : null;
      await loadCategoriesForSelectedExam();
    }
    notifyListeners();
  }

  Future<void> addCategory(Category category) async {
    await _categoryRepo.insertCategory(category);
    await loadCategoriesForSelectedExam();
  }

  Future<void> deleteCategory(int catId) async {
    await _categoryRepo.deleteCategory(catId);
    await loadCategoriesForSelectedExam();
  }

  Future<void> refreshRecentPdfs() async {
    _recentPdfs = await _pdfRepo.getRecentPdfs();
    notifyListeners();
  }
}
