import 'package:flutter/material.dart';
import '../database/pdf_repo.dart';
import 'recycle_bin_screen.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({Key? key}) : super(key: key);

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  final PdfRepo _pdfRepo = PdfRepo();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await _pdfRepo.getStorageStats();
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  String _formatMB(int bytes) {
    return (bytes / 1024 / 1024).toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final activeBytes = (_stats['activeBytes'] as int?) ?? 0;
    final binBytes = (_stats['binBytes'] as int?) ?? 0;
    final totalBytes = (_stats['totalBytes'] as int?) ?? 0;
    final activeCount = (_stats['activeCount'] as int?) ?? 0;
    final binCount = (_stats['binCount'] as int?) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Storage Breakdown'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Total Storage Banner
                Card(
                  color: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL STUDY STORAGE',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_formatMB(totalBytes)} MB',
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${activeCount + binCount} documents saved offline on this device',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Active Documents
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEFF6FF),
                      child: Icon(Icons.picture_as_pdf, color: Color(0xFF3B82F6)),
                    ),
                    title: const Text('Active Study Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('$activeCount documents in categories'),
                    trailing: Text('${_formatMB(activeBytes)} MB', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 10),

                // Recycle Bin Storage
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFEE2E2),
                      child: Icon(Icons.delete_outline, color: Colors.red),
                    ),
                    title: const Text('Recycle Bin Waste', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('$binCount soft-deleted documents'),
                    trailing: Text('${_formatMB(binBytes)} MB', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RecycleBinScreen()),
                      ).then((_) => _loadStats());
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Clean Recommendations
                if (binBytes > 0)
                  Card(
                    color: const Color(0xFFFFFBEB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.cleaning_services, color: Color(0xFFD97706), size: 20),
                              SizedBox(width: 8),
                              Text('Quick Storage Cleanup', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You can instantly free up ${_formatMB(binBytes)} MB by emptying your recycle bin.',
                            style: const TextStyle(color: Color(0xFF78350F), fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RecycleBinScreen()),
                              ).then((_) => _loadStats());
                            },
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Manage Recycle Bin'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
