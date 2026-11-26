class Category {
  final int? id;
  final String title;
  final String description;
  final String color;
  final String icon;
  final int? parentId;
  final int? examId;
  final int createdAt;

  Category({
    this.id,
    required this.title,
    this.description = '',
    this.color = '#6366F1',
    this.icon = 'folder',
    this.parentId,
    this.examId,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'color': color,
      'icon': icon,
      'parent_id': parentId,
      'exam_id': examId,
      'created_at': createdAt,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      color: (map['color'] as String?) ?? '#6366F1',
      icon: (map['icon'] as String?) ?? 'folder',
      parentId: map['parent_id'] as int?,
      examId: map['exam_id'] as int?,
      createdAt: map['created_at'] as int?,
    );
  }

  Category copyWith({
    int? id,
    String? title,
    String? description,
    String? color,
    String? icon,
    int? parentId,
    int? examId,
    int? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      parentId: parentId ?? this.parentId,
      examId: examId ?? this.examId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
