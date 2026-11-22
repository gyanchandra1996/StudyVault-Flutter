class PersonalNote {
  final int? id;
  final int? pdfId;
  final int pageNumber;
  final String noteText;
  final String? pdfTitle;
  final int createdAt;
  final int updatedAt;

  PersonalNote({
    this.id,
    this.pdfId,
    this.pageNumber = 1,
    required this.noteText,
    this.pdfTitle,
    int? createdAt,
    int? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pdf_id': pdfId,
      'page_number': pageNumber,
      'note_text': noteText,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory PersonalNote.fromMap(Map<String, dynamic> map) {
    return PersonalNote(
      id: map['id'] as int?,
      pdfId: map['pdf_id'] as int?,
      pageNumber: (map['page_number'] as int?) ?? 1,
      noteText: (map['note_text'] as String?) ?? '',
      pdfTitle: map['pdf_title'] as String?,
      createdAt: map['created_at'] as int?,
      updatedAt: map['updated_at'] as int?,
    );
  }
}
