class PdfDocument {
  final int? id;
  final String title;
  final String localPath;
  final int fileSize;
  final int totalPages;
  final int lastPage;
  final int? categoryId;
  final int? examId;
  final int isCompleted;
  final int isFavorite;
  final int isDeleted;
  final int? deletedAt;
  final int createdAt;
  final int lastOpenedAt;

  PdfDocument({
    this.id,
    required this.title,
    required this.localPath,
    required this.fileSize,
    this.totalPages = 1,
    this.lastPage = 1,
    this.categoryId,
    this.examId,
    this.isCompleted = 0,
    this.isFavorite = 0,
    this.isDeleted = 0,
    this.deletedAt,
    int? createdAt,
    int? lastOpenedAt,
  })  : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
        lastOpenedAt = lastOpenedAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'local_path': localPath,
      'file_size': fileSize,
      'total_pages': totalPages,
      'last_page': lastPage,
      'category_id': categoryId,
      'exam_id': examId,
      'is_completed': isCompleted,
      'is_favorite': isFavorite,
      'is_deleted': isDeleted,
      'deleted_at': deletedAt,
      'created_at': createdAt,
      'last_opened_at': lastOpenedAt,
    };
  }

  factory PdfDocument.fromMap(Map<String, dynamic> map) {
    return PdfDocument(
      id: map['id'] as int?,
      title: map['title'] as String,
      localPath: map['local_path'] as String,
      fileSize: (map['file_size'] as int?) ?? 0,
      totalPages: (map['total_pages'] as int?) ?? 1,
      lastPage: (map['last_page'] as int?) ?? 1,
      categoryId: map['category_id'] as int?,
      examId: map['exam_id'] as int?,
      isCompleted: (map['is_completed'] as int?) ?? 0,
      isFavorite: (map['is_favorite'] as int?) ?? 0,
      isDeleted: (map['is_deleted'] as int?) ?? 0,
      deletedAt: map['deleted_at'] as int?,
      createdAt: map['created_at'] as int?,
      lastOpenedAt: map['last_opened_at'] as int?,
    );
  }

  PdfDocument copyWith({
    int? id,
    String? title,
    String? localPath,
    int? fileSize,
    int? totalPages,
    int? lastPage,
    int? categoryId,
    int? examId,
    int? isCompleted,
    int? isFavorite,
    int? isDeleted,
    int? deletedAt,
    int? createdAt,
    int? lastOpenedAt,
  }) {
    return PdfDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      localPath: localPath ?? this.localPath,
      fileSize: fileSize ?? this.fileSize,
      totalPages: totalPages ?? this.totalPages,
      lastPage: lastPage ?? this.lastPage,
      categoryId: categoryId ?? this.categoryId,
      examId: examId ?? this.examId,
      isCompleted: isCompleted ?? this.isCompleted,
      isFavorite: isFavorite ?? this.isFavorite,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }
}
