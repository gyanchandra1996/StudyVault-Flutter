import 'dart:convert';

class EbookItem {
  final int? id;
  final String title;
  final String author;
  final String subject;
  final String mediaType; // 'pdf', 'image', 'image_book'
  final String filePath;
  final String extraPathsJson; // JSON array of image paths for multi-page image e-books
  final String coverPath;
  final int totalPages;
  final int lastPage;
  final int isFavorite;
  final String notes;
  final int createdAt;

  EbookItem({
    this.id,
    required this.title,
    this.author = '',
    this.subject = 'General',
    required this.mediaType,
    required this.filePath,
    this.extraPathsJson = '[]',
    this.coverPath = '',
    this.totalPages = 1,
    this.lastPage = 1,
    this.isFavorite = 0,
    this.notes = '',
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  bool get isPdf => mediaType == 'pdf';
  bool get isImageBased => mediaType == 'image' || mediaType == 'image_book';

  List<String> get imagePages {
    if (isPdf) return const [];
    try {
      final decoded = jsonDecode(extraPathsJson);
      if (decoded is List) {
        final paths = decoded.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
        if (paths.isNotEmpty) return paths;
      }
    } catch (_) {}
    return filePath.isNotEmpty ? [filePath] : const [];
  }

  String get mediaLabel {
    switch (mediaType) {
      case 'pdf':
        return 'PDF E-Book';
      case 'image_book':
        return 'Image Book (${imagePages.length}p)';
      case 'image':
      default:
        return 'Image E-Book';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'subject': subject,
      'media_type': mediaType,
      'file_path': filePath,
      'extra_paths_json': extraPathsJson,
      'cover_path': coverPath,
      'total_pages': totalPages,
      'last_page': lastPage,
      'is_favorite': isFavorite,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory EbookItem.fromMap(Map<String, dynamic> map) {
    return EbookItem(
      id: map['id'] as int?,
      title: (map['title'] as String?) ?? 'Untitled E-Book',
      author: (map['author'] as String?) ?? '',
      subject: (map['subject'] as String?) ?? 'General',
      mediaType: (map['media_type'] as String?) ?? 'pdf',
      filePath: (map['file_path'] as String?) ?? '',
      extraPathsJson: (map['extra_paths_json'] as String?) ?? '[]',
      coverPath: (map['cover_path'] as String?) ?? '',
      totalPages: (map['total_pages'] as int?) ?? 1,
      lastPage: (map['last_page'] as int?) ?? 1,
      isFavorite: (map['is_favorite'] as int?) ?? 0,
      notes: (map['notes'] as String?) ?? '',
      createdAt: map['created_at'] as int?,
    );
  }

  EbookItem copyWith({
    int? id,
    String? title,
    String? author,
    String? subject,
    String? mediaType,
    String? filePath,
    String? extraPathsJson,
    String? coverPath,
    int? totalPages,
    int? lastPage,
    int? isFavorite,
    String? notes,
    int? createdAt,
  }) {
    return EbookItem(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      subject: subject ?? this.subject,
      mediaType: mediaType ?? this.mediaType,
      filePath: filePath ?? this.filePath,
      extraPathsJson: extraPathsJson ?? this.extraPathsJson,
      coverPath: coverPath ?? this.coverPath,
      totalPages: totalPages ?? this.totalPages,
      lastPage: lastPage ?? this.lastPage,
      isFavorite: isFavorite ?? this.isFavorite,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
