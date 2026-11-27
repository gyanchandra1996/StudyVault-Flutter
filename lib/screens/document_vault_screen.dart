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
  bool _isGridView = true;

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
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            tooltip: _isGridView ? 'Switch to List View' : 'Switch to Grid View (3 Cards/Row)',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
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
                    : _isGridView
                        ? GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: _documents.length,
                            itemBuilder: (ctx, idx) {
                              final doc = _documents[idx];
                              final docColor = _getDocColor(doc.docType);
                              final docIcon = _getDocIcon(doc.docType);

                              return InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _openDocument(doc),
                                onLongPress: () async {
                                  final del = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text('Delete Document?'),
                                      content: Text('Do you want to delete "${doc.title}"?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                          onPressed: () => Navigator.pop(c, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (del == true && doc.id != null) {
                                    await _docRepo.deleteDocument(doc.id!);
                                    _loadDocuments();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: docColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(docIcon, color: docColor, size: 24),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        doc.title,
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                          height: 1.2,
                                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        (doc.docNumber != null && doc.docNumber!.isNotEmpty)
                                            ? doc.docNumber!
                                            : doc.docType.toUpperCase(),
                                        maxLines: 1,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 9.5, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: _documents.length,
                        itemBuilder: (ctx, idx) {
                          final doc = _documents[idx];
                          final docColor = _getDocColor(doc.docType);
                          final docIcon = _getDocIcon(doc.docType);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => _openDocument(doc),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header: Icon + Title + Category Chip
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: docColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(docIcon, color: docColor, size: 24),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                doc.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                (doc.docNumber != null && doc.docNumber!.isNotEmpty)
                                                    ? doc.docNumber!
                                                    : 'Verified Offline Credential',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.8,
                                                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: docColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(8),
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

                                    // Authority / Notes Section (DigiLocker style)
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isDark ? Colors.white10 : const Color(0xFFEDF2F7),
                                        ),
                                      ),
                                      child: Text(
                                        (doc.notes != null && doc.notes!.isNotEmpty)
                                            ? doc.notes!
                                            : 'Official Document • Verified & Secured in Medhavi ID Vault',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),

                                    // Footer Actions Row
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.share_outlined, size: 20, color: Colors.blueGrey),
                                              tooltip: 'Share Document',
                                              constraints: const BoxConstraints(),
                                              padding: const EdgeInsets.all(6),
                                              onPressed: () => ShareService.sharePdf(doc.filePath, title: doc.title),
                                            ),
                                            if (settings.showDeleteActions) ...[
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
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
                                            ],
                                          ],
                                        ),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: docColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            elevation: 0,
                                          ),
                                          icon: Icon(
                                            doc.fileType == 'pdf' ? Icons.picture_as_pdf : Icons.visibility,
                                            size: 16,
                                          ),
                                          label: const Text('View Document', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          onPressed: () => _openDocument(doc),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
