import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/pdf_document.dart';

class PdfStorageService {
  static Future<PdfDocument?> pickAndSavePdf({int? categoryId, int? examId}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;
    if (file.path == null) return null;

    final appDocDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(p.join(appDocDir.path, 'pdfs'));
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }

    final safeName = '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';
    final targetPath = p.join(pdfDir.path, safeName);

    final originalFile = File(file.path!);
    final savedFile = await originalFile.copy(targetPath);
    final size = await savedFile.length();

    return PdfDocument(
      title: file.name.replaceAll('.pdf', ''),
      localPath: targetPath,
      fileSize: size,
      categoryId: categoryId,
      examId: examId,
    );
  }
}
