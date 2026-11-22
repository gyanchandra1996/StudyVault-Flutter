class Exam {
  final int? id;
  final String title;
  final String description;
  final String color;
  final String icon;
  final int createdAt;

  Exam({
    this.id,
    required this.title,
    this.description = '',
    this.color = '#6366F1',
    this.icon = 'school',
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'color': color,
      'icon': icon,
      'created_at': createdAt,
    };
  }

  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      color: (map['color'] as String?) ?? '#6366F1',
      icon: (map['icon'] as String?) ?? 'school',
      createdAt: map['created_at'] as int?,
    );
  }
}
