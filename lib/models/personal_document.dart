class PersonalDocument {
  final int? id;
  final String title;
  final String docType; // 'aadhaar', 'pan', 'admit_card', 'marksheet', 'certificate', 'other'
  final String filePath;
  final String fileType; // 'image', 'pdf'
  final String? docNumber;
  final String? notes;
  final bool isLocked;
  final int createdAt;

  PersonalDocument({
    this.id,
    required this.title,
    required this.docType,
    required this.filePath,
    required this.fileType,
    this.docNumber,
    this.notes,
    this.isLocked = true,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  String get docTypeDisplayName {
    switch (docType) {
      case 'aadhaar':
        return 'Aadhaar Card';
      case 'pan':
        return 'PAN Card';
      case 'admit_card':
        return 'Exam Admit Card';
      case 'marksheet':
        return 'Marksheet';
      case 'certificate':
        return 'Certificate / Degree';
      case 'other':
      default:
        return 'Personal Document';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'doc_type': docType,
      'file_path': filePath,
      'file_type': fileType,
      'doc_number': docNumber,
      'notes': notes,
      'is_locked': isLocked ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory PersonalDocument.fromMap(Map<String, dynamic> map) {
    return PersonalDocument(
      id: map['id'] as int?,
      title: map['title'] as String,
      docType: map['doc_type'] as String,
      filePath: map['file_path'] as String,
      fileType: map['file_type'] as String,
      docNumber: map['doc_number'] as String?,
      notes: map['notes'] as String?,
      isLocked: (map['is_locked'] as int?) == 1,
      createdAt: map['created_at'] as int?,
    );
  }
}
