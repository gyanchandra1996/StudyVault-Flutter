import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/study_provider.dart';
import '../services/backup_service.dart';

class BackupRestoreModal extends StatefulWidget {
  final VoidCallback? onRestored;

  const BackupRestoreModal({Key? key, this.onRestored}) : super(key: key);

  @override
  State<BackupRestoreModal> createState() => _BackupRestoreModalState();
}

class _BackupRestoreModalState extends State<BackupRestoreModal> {
  bool _isProcessing = false;
  String? _statusMessage;
  bool _isSuccess = false;
  String? _lastExportedPath;
  List<FileSystemEntity> _existingBackups = [];

  @override
  void initState() {
    super.initState();
    _loadExistingBackups();
  }

  Future<void> _loadExistingBackups() async {
    final backups = await BackupService.listLocalBackups();
    if (mounted) {
      setState(() {
        _existingBackups = backups;
      });
    }
  }

  Future<void> _handleExport() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Creating study vault backup...';
      _isSuccess = false;
    });

    try {
      final file = await BackupService.exportBackup();
      final sizeKb = (await file.length()) / 1024;
      setState(() {
        _isProcessing = false;
        _isSuccess = true;
        _lastExportedPath = file.path;
        _statusMessage = 'Backup created successfully (${sizeKb.toStringAsFixed(1)} KB)!\nSaved to: ${file.path}';
      });
      await _loadExistingBackups();
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _statusMessage = 'Backup failed: $e';
      });
    }
  }

  Future<void> _handleRestore([String? directFilePath]) async {
    String? path = directFilePath;
    if (path == null) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result == null || result.files.single.path == null) return;
      path = result.files.single.path!;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text('Confirm Restore', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Text(
          'Restoring will import categories, question banks, flashcards, and notes from this backup file. Existing duplicate records will be updated. Proceed?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            child: const Text('Restore Data'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Restoring study data...';
      _isSuccess = false;
    });

    try {
      final counts = await BackupService.restoreBackup(path);
      int totalItems = counts.values.fold(0, (sum, count) => sum + count);

      if (mounted) {
        final studyProvider = Provider.of<StudyProvider>(context, listen: false);
        await studyProvider.loadInitialData();
        widget.onRestored?.call();

        setState(() {
          _isProcessing = false;
          _isSuccess = true;
          _statusMessage = 'Restore complete! Successfully imported $totalItems items across ${counts.length} study categories.';
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _statusMessage = 'Restore failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: settings.activeAccentColor.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: settings.activeAccentColor.withOpacity(0.2),
                    child: Icon(Icons.cloud_sync_rounded, color: settings.activeAccentColor),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1-Click Backup & Restore',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Secure & migrate all study data offline',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Status Banner
                  if (_statusMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isSuccess ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isSuccess ? Icons.check_circle : Icons.error_outline,
                                color: _isSuccess ? Colors.green : Colors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _statusMessage!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_lastExportedPath != null && _isSuccess) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                icon: const Icon(Icons.open_in_new, size: 14),
                                label: const Text('Open Backup File', style: TextStyle(fontSize: 12)),
                                onPressed: () => OpenFile.open(_lastExportedPath!),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_isProcessing) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ],

                  // Action 1: Export Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 18,
                                backgroundColor: Color(0xFFE0E7FF),
                                child: Icon(Icons.download_rounded, color: Color(0xFF4F46E5), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Export Study Vault Backup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    Text('Saves all questions, flashcards, notes, & history to a JSON file', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: settings.activeAccentColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.save_alt_rounded, size: 18),
                              label: const Text('Export Backup Now'),
                              onPressed: _isProcessing ? null : _handleExport,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action 2: Import Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 18,
                                backgroundColor: Color(0xFFD1FAE5),
                                child: Icon(Icons.upload_file_rounded, color: Color(0xFF059669), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Restore From Backup File', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    Text('Select a previously exported .json file to restore', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.folder_open_rounded, size: 18),
                              label: const Text('Choose File to Restore'),
                              onPressed: _isProcessing ? null : () => _handleRestore(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Existing Backups List
                  if (_existingBackups.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Text(
                      'Saved Backups on Device:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _existingBackups.length > 5 ? 5 : _existingBackups.length,
                      itemBuilder: (ctx, idx) {
                        final file = _existingBackups[idx];
                        final name = file.path.split(Platform.pathSeparator).last;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.withOpacity(0.15)),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.insert_drive_file_outlined, color: Colors.grey),
                            title: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            trailing: TextButton(
                              child: const Text('Restore', style: TextStyle(fontSize: 12)),
                              onPressed: _isProcessing ? null : () => _handleRestore(file.path),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
