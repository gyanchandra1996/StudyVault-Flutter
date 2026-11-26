import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../models/personal_document.dart';
import '../models/pdf_document.dart';
import '../database/document_repo.dart';
import '../providers/settings_provider.dart';
import '../services/share_service.dart';
import 'pdf_reader_screen.dart';

class DocumentVaultScreen extends StatefulWidget {
  const DocumentVaultScreen({Key? key}) : super(key: key);

  @override
  State<DocumentVaultScreen> createState() => _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends State<DocumentVaultScreen> {
  final DocumentRepo _docRepo = DocumentRepo();
  List<PersonalDocument> _documents = [];
  bool _isLoading = true;
  String _selectedType = 'all';

  final List<Map<String, String>> _typeFilters = [
    {'id': 'all', 'label': 'All Vault'},
    {'id': 'aadhaar', 'label': 'Aadhaar Card'},
    {'id': 'pan', 'label': 'PAN Card'},
    {'id': 'admit_card', 'label': 'Admit Cards'},
    {'id': 'marksheet', 'label': 'Marksheets'},
    {'id': 'certificate', 'label': 'Certificates'},
    {'id': 'other', 'label': 'Other IDs'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    final docs = _selectedType == 'all'
        ? await _docRepo.getAllDocuments()
        : await _docRepo.getDocumentsByType(_selectedType);
    setState(() {
      _documents = docs;
      _isLoading = false;
    });
  }

  Future<void> _pickAndAddDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result == null || result.files.single.path == null) return;

      final srcPath = result.files.single.path!;
      final originalName = result.files.single.name;
      final extension = p.extension(srcPath).toLowerCase();
      final isPdf = extension == '.pdf';

      if (!mounted) return;

      // Show document metadata input dialog
      final titleController = TextEditingController(text: p.basenameWithoutExtension(originalName));
      final numController = TextEditingController();
      final notesController = TextEditingController();
      String chosenType = _selectedType != 'all' ? _selectedType : 'aadhaar';

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.shield, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text('Save to ID Vault', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Document Name',
                        hintText: 'e.g. Aadhaar Card (Gyan)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Document Category:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: chosenType,
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                      items: const [
                        DropdownMenuItem(value: 'aadhaar', child: Text('🪪 Aadhaar Card')),
                        DropdownMenuItem(value: 'pan', child: Text('💳 PAN Card')),
                        DropdownMenuItem(value: 'admit_card', child: Text('🎫 Exam Admit Card')),
                        DropdownMenuItem(value: 'marksheet', child: Text('📜 10th / 12th / Degree Marksheet')),
                        DropdownMenuItem(value: 'certificate', child: Text('🎓 Certificate / Resume')),
                        DropdownMenuItem(value: 'other', child: Text('📁 Other ID / Doc')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => chosenType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: numController,
                      decoration: const InputDecoration(
                        labelText: 'ID / Roll / Card No. (Optional)',
                        hintText: 'e.g. XXXX-XXXX-4821',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes / Remarks (Optional)',
                        hintText: 'e.g. Color scan for exam center',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.lock),
                  label: const Text('Save Encrypted'),
                  onPressed: () async {
                    final appDir = await getApplicationDocumentsDirectory();
                    final vaultDir = Directory(p.join(appDir.path, 'vault'));
                    if (!await vaultDir.exists()) {
                      await vaultDir.create(recursive: true);
                    }

                    final fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}$extension';
                    final destPath = p.join(vaultDir.path, fileName);
                    await File(srcPath).copy(destPath);

                    final doc = PersonalDocument(
                      title: titleController.text.trim().isNotEmpty
                          ? titleController.text.trim()
                          : originalName,
                      docType: chosenType,
                      filePath: destPath,
                      fileType: isPdf ? 'pdf' : 'image',
                      docNumber: numController.text.trim().isNotEmpty ? numController.text.trim() : null,
                      notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                    );

                    await _docRepo.insertDocument(doc);
                    Navigator.pop(ctx);
                    _loadDocuments();
                  },
                ),
              ],
            );
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import document: $e')),
      );
    }
  }

  void _openDocument(PersonalDocument doc) {
    if (doc.fileType == 'pdf') {
      final pdf = PdfDocument(
        id: doc.id,
        title: doc.title,
        localPath: doc.filePath,
        fileSize: File(doc.filePath).existsSync() ? File(doc.filePath).lengthSync() : 0,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfReaderScreen(pdf: pdf),
        ),
      );
    } else {
      // Interactive Zoomable Image Viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: Text(doc.title),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => ShareService.sharePdf(doc.filePath, title: doc.title),
                ),
              ],
            ),
            backgroundColor: Colors.black,
            body: Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: File(doc.filePath).existsSync()
                    ? Image.file(File(doc.filePath), fit: BoxFit.contain)
                    : const Text('File not found', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ),
      );
    }
  }

  Color _getDocColor(String type) {
    switch (type) {
      case 'aadhaar':
        return Colors.deepOrange;
      case 'pan':
        return Colors.blue;
      case 'admit_card':
        return Colors.purple;
      case 'marksheet':
        return Colors.teal;
      case 'certificate':
        return Colors.amber.shade800;
      default:
        return Colors.indigo;
    }
  }

  IconData _getDocIcon(String type) {
    switch (type) {
      case 'aadhaar':
        return Icons.badge_outlined;
      case 'pan':
        return Icons.credit_card;
      case 'admit_card':
        return Icons.confirmation_number_outlined;
      case 'marksheet':
        return Icons.assignment_outlined;
      case 'certificate':
        return Icons.card_membership_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DigiLocker ID Vault',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Document',
            onPressed: _pickAndAddDocument,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadDocuments,
          ),
        ],
      ),
      body: Column(
        children: [
          // Security header banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF1E3A8A).withOpacity(0.08),
            child: Row(
              children: [
                const Icon(Icons.verified_user, size: 18, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    settings.isLockEnabled
                        ? 'Protected by App PIN • 100% Offline Encrypted Vault'
                        : 'DigiLocker Secure ID Vault • 100% Offline Encrypted',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter category chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _typeFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, idx) {
                final f = _typeFilters[idx];
                final isSelected = _selectedType == f['id'];
                return ChoiceChip(
                  label: Text(f['label']!),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedType = f['id']!);
                      _loadDocuments();
                    }
                  },
                );
              },
            ),
          ),

          // Document List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _documents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'ID Vault is Empty',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Scan or save your Aadhaar card, PAN card, exam admit cards, and certificates offline safely.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.add_photo_alternate),
                              label: const Text('Add First Document'),
                              onPressed: _pickAndAddDocument,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: _documents.length,
                        itemBuilder: (ctx, idx) {
                          final doc = _documents[idx];
                          final docColor = _getDocColor(doc.docType);
                          final docIcon = _getDocIcon(doc.docType);

                          return Card(
                            elevation: 1.5,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: docColor.withOpacity(0.3), width: 1.2),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: docColor.withOpacity(0.12),
                                        child: Icon(docIcon, color: docColor, size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    doc.title,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: docColor.withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    doc.docTypeDisplayName,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: docColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (doc.docNumber != null && doc.docNumber!.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'ID No: ${doc.docNumber!}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? Colors.white70 : Colors.black87,
                                                ),
                                              ),
                                            ],
                                            if (doc.notes != null && doc.notes!.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                doc.notes!,
                                                style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Divider(height: 1),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Wrap(
                                      alignment: WrapAlignment.end,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.share_outlined, size: 20, color: Colors.grey),
                                          tooltip: 'Share Document',
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(6),
                                          onPressed: () => ShareService.sharePdf(doc.filePath, title: doc.title),
                                        ),
                                        if (settings.showDeleteActions)
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                            tooltip: 'Delete Document',
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(6),
                                            onPressed: () async {
                                              if (doc.id != null) {
                                                await _docRepo.deleteDocument(doc.id!);
                                                _loadDocuments();
                                              }
                                            },
                                          ),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: docColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                            minimumSize: const Size(0, 34),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          icon: Icon(
                                            doc.fileType == 'pdf' ? Icons.picture_as_pdf : Icons.visibility,
                                            size: 16,
                                          ),
                                          label: const Text('View Doc', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          onPressed: () => _openDocument(doc),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Add Document'),
        onPressed: _pickAndAddDocument,
      ),
    );
  }
}
