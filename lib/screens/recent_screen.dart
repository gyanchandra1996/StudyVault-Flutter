import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/pdf_repo.dart';
import '../models/pdf_document.dart';
import 'pdf_reader_screen.dart';

class RecentScreen extends StatefulWidget {
  const RecentScreen({Key? key}) : super(key: key);

  @override
  State<RecentScreen> createState() => _RecentScreenState();
}

class _RecentScreenState extends State<RecentScreen> {
  final PdfRepo _pdfRepo = PdfRepo();
  List<PdfDocument> _recentPdfs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    setState(() => _isLoading = true);
    final list = await _pdfRepo.getRecentPdfs();
    setState(() {
      _recentPdfs = list;
      _isLoading = false;
    });
  }

  String _formatDate(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recentPdfs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'No Recent Reading History',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your recently opened PDF documents will appear here.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _recentPdfs.length,
                  itemBuilder: (ctx, index) {
                    final pdf = _recentPdfs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFF0FDF4),
                          child: Icon(Icons.history, color: Color(0xFF10B981)),
                        ),
                        title: Text(pdf.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text('Last opened: ${_formatDate(pdf.lastOpenedAt)}', style: const TextStyle(fontSize: 11)),
                            Text('Progress: Page ${pdf.lastPage} of ${pdf.totalPages}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PdfReaderScreen(pdf: pdf)),
                          ).then((_) => _loadRecent());
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
