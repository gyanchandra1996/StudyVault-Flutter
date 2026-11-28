import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;
import '../models/pdf_document.dart';

class PdfStorageService {
  static Future<int> detectPdfPageCount(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final doc = syncfusion.PdfDocument(inputBytes: bytes);
      final count = doc.pages.count;
      doc.dispose();
      return count > 0 ? count : 1;
    } catch (_) {
      return 1;
    }
  }

  /// Picks one or more PDF files and saves them inside the app's private PDFs folder.
  static Future<List<PdfDocument>> pickAndSaveMultiplePdfs({int? categoryId, int? examId}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) {
      return const [];
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(p.join(appDocDir.path, 'pdfs'));
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }

    final savedDocs = <PdfDocument>[];
    final ts = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < result.files.length; i++) {
      final file = result.files[i];
      if (file.path == null) continue;

      final originalFile = File(file.path!);
      if (!await originalFile.exists()) continue;

      final safeName = '${ts}_${i}_${file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';
      final targetPath = p.join(pdfDir.path, safeName);

      final savedFile = await originalFile.copy(targetPath);
      final size = await savedFile.length();
      final totalPages = await detectPdfPageCount(savedFile);
      final cleanTitle = p.basenameWithoutExtension(file.name).trim();

      savedDocs.add(PdfDocument(
        title: cleanTitle.isNotEmpty ? cleanTitle : 'Document ${i + 1}',
        localPath: targetPath,
        fileSize: size,
        totalPages: totalPages,
        categoryId: categoryId,
        examId: examId,
      ));
    }

    return savedDocs;
  }

  static Future<PdfDocument?> pickAndSavePdf({int? categoryId, int? examId}) async {
    final docs = await pickAndSaveMultiplePdfs(categoryId: categoryId, examId: examId);
    return docs.isNotEmpty ? docs.first : null;
  }
}
