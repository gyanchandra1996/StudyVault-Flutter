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
  List<PdfDocument> _recentPdfs = [];
  bool _isLoading = false;

  List<Exam> get exams => _exams;
  Exam? get selectedExam => _selectedExam;
  List<Category> get categories => _categories;
  List<PdfDocument> get recentPdfs => _recentPdfs;
  bool get isLoading => _isLoading;

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    _exams = await _examRepo.getAllExams();
    if (_exams.isNotEmpty && _selectedExam == null) {
      _selectedExam = _exams.first;
    }
    await loadCategoriesForSelectedExam();
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
