import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/pdf_repo.dart';
import '../models/pdf_document.dart';
import '../providers/settings_provider.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({Key? key}) : super(key: key);

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  final PdfRepo _pdfRepo = PdfRepo();
  List<PdfDocument> _binList = [];
  bool _isLoading = true;
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    _loadBin(showLoading: true);
  }

  Future<void> _loadBin({bool showLoading = false}) async {
    if (showLoading || !_hasLoadedOnce) {
      setState(() => _isLoading = true);
    }
    final list = await _pdfRepo.getRecycleBinPdfs();
    if (!mounted) return;
    setState(() {
      _binList = list;
      _isLoading = false;
      _hasLoadedOnce = true;
    });
  }

  void _restorePdf(PdfDocument pdf) async {
    if (pdf.id != null) {
      await _pdfRepo.restoreFromBin(pdf.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restored "${pdf.title}"')),
      );
      _loadBin();
    }
  }

  void _permanentDelete(PdfDocument pdf) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete?'),
        content: Text('Are you sure you want to permanently delete "${pdf.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              if (pdf.id != null) {
                await _pdfRepo.permanentlyDelete(pdf.id!, pdf.localPath);
                Navigator.pop(ctx);
                _loadBin();
              }
            },
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  void _emptyBin() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Recycle Bin?'),
        content: const Text('All recycled documents will be permanently removed from device storage.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await _pdfRepo.emptyRecycleBin();
              Navigator.pop(ctx);
              _loadBin();
            },
            child: const Text('Empty All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin'),
        actions: [
          if (_binList.isNotEmpty && settings.canDelete)
            TextButton.icon(
              onPressed: _emptyBin,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text('Empty Bin', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _binList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'Recycle Bin is Empty',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Soft-deleted study notes will stay here safely until you restore or permanently delete them.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _binList.length,
                  itemBuilder: (ctx, index) {
                    final pdf = _binList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFEE2E2),
                          child: Icon(Icons.delete_outline, color: Colors.red),
                        ),
                        title: Text(pdf.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${(pdf.fileSize / 1024 / 1024).toStringAsFixed(1)} MB • ${pdf.totalPages} pages'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (settings.canManageFiles || settings.canEdit)
                              IconButton(
                                icon: const Icon(Icons.restore, color: Color(0xFF10B981)),
                                tooltip: 'Restore',
                                onPressed: () => _restorePdf(pdf),
                              ),
                            if (settings.canDelete)
                              IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                tooltip: 'Delete Forever',
                                onPressed: () => _permanentDelete(pdf),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
