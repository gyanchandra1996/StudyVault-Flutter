import 'dart:io';
import 'package:flutter/material.dart' show Color, Rect, Offset, Size;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/pdf_document.dart' as model;
import '../database/pdf_repo.dart';

class PdfToolsService {
  static final PdfRepo _pdfRepo = PdfRepo();

  static Future<Directory> _getPdfDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(p.join(appDocDir.path, 'pdfs'));
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }
    return pdfDir;
  }

  /// 1. Converts images to a standardized multi-page PDF and adds to vault
  static Future<model.PdfDocument> convertImagesToPdf(
    List<String> imagePaths,
    String title, {
    int? categoryId,
    int? examId,
  }) async {
    if (imagePaths.isEmpty) {
      throw Exception('No images selected for conversion.');
    }

    final document = PdfDocument();

    for (final imgPath in imagePaths) {
      final file = File(imgPath);
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      final bitmap = PdfBitmap(bytes);
      final page = document.pages.add();
      final pageSize = page.getClientSize();

      // Fit image proportionally inside the page
      double imgWidth = bitmap.width.toDouble();
      double imgHeight = bitmap.height.toDouble();
      final scale = (pageSize.width / imgWidth).clamp(0.01, pageSize.height / imgHeight);
      final drawWidth = imgWidth * scale;
      final drawHeight = imgHeight * scale;
      final x = (pageSize.width - drawWidth) / 2;
      final y = (pageSize.height - drawHeight) / 2;

      page.graphics.drawImage(bitmap, Rect.fromLTWH(x, y, drawWidth, drawHeight));
    }

    final pdfBytes = await document.save();
    final pageCount = document.pages.count;
    document.dispose();

    final dir = await _getPdfDirectory();
    final safeTitle = title.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final filename = '${DateTime.now().millisecondsSinceEpoch}_$safeTitle.pdf';
    final targetPath = p.join(dir.path, filename);

    final targetFile = File(targetPath);
    await targetFile.writeAsBytes(pdfBytes);
    final size = await targetFile.length();

    final pdfDoc = model.PdfDocument(
      title: title.trim().isNotEmpty ? title.trim() : 'Image Notes',
      localPath: targetPath,
      fileSize: size,
      totalPages: pageCount > 0 ? pageCount : 1,
      categoryId: categoryId,
      examId: examId,
    );

    final id = await _pdfRepo.insertPdf(pdfDoc);
    return pdfDoc.copyWith(id: id);
  }

  /// 2. Merges multiple PDFs into a single master document
  static Future<model.PdfDocument> mergeMultiplePdfs(
    List<String> pdfPaths,
    String title, {
    int? categoryId,
    int? examId,
  }) async {
    if (pdfPaths.length < 2) {
      throw Exception('Select at least 2 PDFs to merge.');
    }

    final destination = PdfDocument();

    for (final pdfPath in pdfPaths) {
      final file = File(pdfPath);
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      final source = PdfDocument(inputBytes: bytes);

      for (int i = 0; i < source.pages.count; i++) {
        final template = source.pages[i].createTemplate();
        final newPage = destination.pages.add();
        newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));
      }
      source.dispose();
    }

    final mergedBytes = await destination.save();
    final totalPages = destination.pages.count;
    destination.dispose();

    final dir = await _getPdfDirectory();
    final safeTitle = title.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final filename = '${DateTime.now().millisecondsSinceEpoch}_$safeTitle.pdf';
    final targetPath = p.join(dir.path, filename);

    final targetFile = File(targetPath);
    await targetFile.writeAsBytes(mergedBytes);
    final size = await targetFile.length();

    final pdfDoc = model.PdfDocument(
      title: title.trim().isNotEmpty ? title.trim() : 'Merged Document',
      localPath: targetPath,
      fileSize: size,
      totalPages: totalPages > 0 ? totalPages : 1,
      categoryId: categoryId,
      examId: examId,
    );

    final id = await _pdfRepo.insertPdf(pdfDoc);
    return pdfDoc.copyWith(id: id);
  }

  /// 3. Edits a PDF by keeping only selected pages
  static Future<model.PdfDocument> editPdfDocumentPages(
    String sourcePdfPath,
    List<int> pagesToKeep,
    String title, {
    int? categoryId,
    int? examId,
  }) async {
    final file = File(sourcePdfPath);
    if (!await file.exists()) {
      throw Exception('Source PDF not found.');
    }
    if (pagesToKeep.isEmpty) {
      throw Exception('Select at least 1 page to retain.');
    }

    final bytes = await file.readAsBytes();
    final source = PdfDocument(inputBytes: bytes);
    final destination = PdfDocument();

    for (final pageNum in pagesToKeep) {
      if (pageNum >= 1 && pageNum <= source.pages.count) {
        final template = source.pages[pageNum - 1].createTemplate();
        final newPage = destination.pages.add();
        newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));
      }
    }

    source.dispose();
    final newBytes = await destination.save();
    final totalPages = destination.pages.count;
    destination.dispose();

    final dir = await _getPdfDirectory();
    final safeTitle = title.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final filename = '${DateTime.now().millisecondsSinceEpoch}_$safeTitle.pdf';
    final targetPath = p.join(dir.path, filename);

    final targetFile = File(targetPath);
    await targetFile.writeAsBytes(newBytes);
    final size = await targetFile.length();

    final pdfDoc = model.PdfDocument(
      title: title.trim().isNotEmpty ? title.trim() : 'Edited Document',
      localPath: targetPath,
      fileSize: size,
      totalPages: totalPages > 0 ? totalPages : 1,
      categoryId: categoryId,
      examId: examId,
    );

    final id = await _pdfRepo.insertPdf(pdfDoc);
    return pdfDoc.copyWith(id: id);
  }

  /// 4. Generates a formatted PDF from AI Study Notes and saves to vault
  static Future<model.PdfDocument> generateAiNotesPdf({
    required String title,
    required String topic,
    required Map<String, dynamic> notesData,
    int? categoryId,
    int? examId,
  }) async {
    final document = PdfDocument();
    document.pageSettings.margins.all = 36; // 0.5 inch margins

    final headerFont = PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
    final subHeaderFont = PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold);
    final sectionHeaderFont = PdfStandardFont(PdfFontFamily.helvetica, 13, style: PdfFontStyle.bold);
    final bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 10);

    final primaryColor = PdfColor(99, 102, 241);
    final darkTextColor = PdfColor(30, 41, 59);
    final textBrush = PdfSolidBrush(darkTextColor);
    final primaryBrush = PdfSolidBrush(primaryColor);
    final greyBrush = PdfSolidBrush(PdfColor(100, 116, 139));

    // Page 1
    PdfPage page = document.pages.add();
    final pageSize = page.getClientSize();
    double y = 0;

    // Header Title Banner
    page.graphics.drawString(
      title.toUpperCase(),
      headerFont,
      brush: primaryBrush,
      bounds: Rect.fromLTWH(0, y, pageSize.width, 24),
    );
    y += 26;

    page.graphics.drawString(
      'StudyVault AI Notes • Topic: $topic • ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      subHeaderFont,
      brush: greyBrush,
      bounds: Rect.fromLTWH(0, y, pageSize.width, 16),
    );
    y += 20;

    // Divider Line
    page.graphics.drawLine(
      PdfPen(PdfColor(226, 232, 240), width: 1.5),
      Offset(0, y),
      Offset(pageSize.width, y),
    );
    y += 14;

    void checkPageBreak(double neededHeight) {
      if (y + neededHeight > pageSize.height - 30) {
        page = document.pages.add();
        y = 20;
      }
    }

    void drawSectionHeader(String heading, PdfColor color) {
      checkPageBreak(36);
      page.graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(241, 245, 249)),
        bounds: Rect.fromLTWH(0, y, pageSize.width, 22),
      );
      page.graphics.drawString(
        heading,
        sectionHeaderFont,
        brush: PdfSolidBrush(color),
        bounds: Rect.fromLTWH(8, y + 3, pageSize.width - 16, 20),
      );
      y += 28;
    }

    void drawTextBlock(String text) {
      final textElement = PdfTextElement(
        text: text,
        font: bodyFont,
        brush: textBrush,
        format: PdfStringFormat(lineSpacing: 3),
      );
      final layoutResult = textElement.draw(
        page: page,
        bounds: Rect.fromLTWH(0, y, pageSize.width, pageSize.height - y),
      );
      if (layoutResult != null) {
        page = layoutResult.page;
        y = layoutResult.bounds.bottom + 14;
      } else {
        y += 20;
      }
    }

    // Section 1: Overview
    final overview = notesData['overview']?.toString() ?? '';
    if (overview.isNotEmpty) {
      drawSectionHeader('1. EXECUTIVE STUDY OVERVIEW', primaryColor);
      drawTextBlock(overview);
    }

    // Section 2: Key Concepts
    final keyConcepts = notesData['keyConcepts'] as List<dynamic>?;
    if (keyConcepts != null && keyConcepts.isNotEmpty) {
      drawSectionHeader('2. CORE KEY CONCEPTS', PdfColor(16, 185, 129));
      for (final concept in keyConcepts) {
        checkPageBreak(25);
        final conceptText = '• ${concept.toString()}';
        drawTextBlock(conceptText);
      }
    }

    // Section 3: Deep Dive
    final deepDive = notesData['deepDive']?.toString() ?? '';
    if (deepDive.isNotEmpty) {
      drawSectionHeader('3. IN-DEPTH ANALYSIS & MECHANISMS', PdfColor(139, 92, 246));
      drawTextBlock(deepDive);
    }

    // Section 4: Exam Takeaways
    final takeaways = notesData['examTakeaways']?.toString() ?? '';
    if (takeaways.isNotEmpty) {
      drawSectionHeader('4. EXAM TAKEAWAYS & REVISION CHECKLIST', PdfColor(245, 158, 11));
      drawTextBlock(takeaways);
    }

    // Save PDF
    final pdfBytes = await document.save();
    final totalPages = document.pages.count;
    document.dispose();

    final dir = await _getPdfDirectory();
    final safeTitle = title.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final filename = 'AI_Notes_${DateTime.now().millisecondsSinceEpoch}_$safeTitle.pdf';
    final targetPath = p.join(dir.path, filename);

    final targetFile = File(targetPath);
    await targetFile.writeAsBytes(pdfBytes);
    final size = await targetFile.length();

    final pdfDoc = model.PdfDocument(
      title: title.trim().isNotEmpty ? title.trim() : 'AI Study Notes - $topic',
      localPath: targetPath,
      fileSize: size,
      totalPages: totalPages > 0 ? totalPages : 1,
      categoryId: categoryId,
      examId: examId,
    );

    final id = await _pdfRepo.insertPdf(pdfDoc);
    return pdfDoc.copyWith(id: id);
  }

  /// 5. Compresses and optimizes PDF document structure and stream objects
  static Future<model.PdfDocument> compressPdfDocument(
    String sourcePdfPath,
    String title, {
    int? categoryId,
    int? examId,
  }) async {
    final file = File(sourcePdfPath);
    if (!await file.exists()) throw Exception('Source PDF not found.');

    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    document.compressionLevel = PdfCompressionLevel.best;
    document.fileStructure.crossReferenceType = PdfCrossReferenceType.crossReferenceStream;

    final compressedBytes = await document.save();
    final totalPages = document.pages.count;
    document.dispose();

    final dir = await _getPdfDirectory();
    final safeTitle = title.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final filename = '${DateTime.now().millisecondsSinceEpoch}_compressed_$safeTitle.pdf';
    final targetPath = p.join(dir.path, filename);

    final targetFile = File(targetPath);
    await targetFile.writeAsBytes(compressedBytes);
    final size = await targetFile.length();

    final pdfDoc = model.PdfDocument(
      title: title.trim().isNotEmpty ? title.trim() : 'Compressed Document',
      localPath: targetPath,
      fileSize: size,
      totalPages: totalPages > 0 ? totalPages : 1,
      categoryId: categoryId,
      examId: examId,
    );

    final id = await _pdfRepo.insertPdf(pdfDoc);
    return pdfDoc.copyWith(id: id);
  }
}
