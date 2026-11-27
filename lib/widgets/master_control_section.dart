import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

/// Shared Master Edit & View Control card used in Settings and Profile screens
/// to globally control View, Edit, Delete, File, and Folder permissions.
class MasterEditViewControlSection extends StatelessWidget {
  final bool compact;

  const MasterEditViewControlSection({
    Key? key,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBlue = Color(0xFF1E3A8A);

    final isFullControl = settings.isEditMode &&
        settings.allowEditActions &&
        settings.allowFileControls &&
        settings.allowFolderControls &&
        settings.showDeleteActions;
    final isSafeEdit = settings.isEditMode &&
        settings.allowEditActions &&
        settings.allowFileControls &&
        settings.allowFolderControls &&
        !settings.showDeleteActions;

    return Card(
      elevation: compact ? 1 : 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: settings.isEditMode
              ? (settings.canDelete ? Colors.red.withOpacity(0.35) : Colors.orange.withOpacity(0.35))
              : primaryBlue.withOpacity(0.25),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (settings.isEditMode ? Colors.orange : primaryBlue).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: settings.isEditMode ? Colors.orange.shade800 : primaryBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Master Edit & View Control',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Controls View, Edit, Delete, File & Folder actions across entire app',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Live Global Status Chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildStatusBadge(
                  label: settings.isEditMode ? 'MODE: EDIT' : 'MODE: VIEW ONLY',
                  color: settings.isEditMode ? Colors.orange.shade800 : primaryBlue,
                  icon: settings.isEditMode ? Icons.edit_note : Icons.visibility_outlined,
                ),
                _buildStatusBadge(
                  label: 'Edit: ${settings.canEdit ? "ON" : "OFF"}',
                  color: settings.canEdit ? Colors.indigo : Colors.grey,
                  icon: Icons.drive_file_rename_outline,
                ),
                _buildStatusBadge(
                  label: 'Delete: ${settings.canDelete ? "ON" : "OFF"}',
                  color: settings.canDelete ? Colors.red : Colors.green.shade700,
                  icon: settings.canDelete ? Icons.delete_forever_outlined : Icons.shield_outlined,
                ),
                _buildStatusBadge(
                  label: 'Files: ${settings.canManageFiles ? "ON" : "OFF"}',
                  color: settings.canManageFiles ? Colors.teal : Colors.grey,
                  icon: Icons.upload_file_outlined,
                ),
                _buildStatusBadge(
                  label: 'Folders: ${settings.canManageFolders ? "ON" : "OFF"}',
                  color: settings.canManageFolders ? Colors.purple : Colors.grey,
                  icon: Icons.create_new_folder_outlined,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quick Mode Presets
            Row(
              children: [
                Expanded(
                  child: _buildPresetButton(
                    label: 'View Only',
                    icon: Icons.visibility_outlined,
                    selected: !settings.isEditMode,
                    color: primaryBlue,
                    onTap: () => settings.applyMasterControlPreset('view_only'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPresetButton(
                    label: 'Safe Edit',
                    icon: Icons.edit_outlined,
                    selected: isSafeEdit,
                    color: Colors.orange.shade800,
                    onTap: () => settings.applyMasterControlPreset('safe_edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPresetButton(
                    label: 'Full Admin',
                    icon: Icons.tune_rounded,
                    selected: isFullControl,
                    color: Colors.red.shade700,
                    onTap: () => _confirmEnableFullControl(context, settings),
                  ),
                ),
              ],
            ),
            const Divider(height: 22),

            // 1. Master Edit / View Mode Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: CircleAvatar(
                radius: 18,
                backgroundColor: (settings.isEditMode ? Colors.orange : primaryBlue).withOpacity(0.14),
                child: Icon(
                  settings.isEditMode ? Icons.edit_note_rounded : Icons.visibility_rounded,
                  color: settings.isEditMode ? Colors.orange.shade800 : primaryBlue,
                  size: 20,
                ),
              ),
              title: const Text(
                'Master Edit Mode',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                settings.isEditMode
                    ? 'Edit Mode ON: Individual Edit, File, Folder & Delete controls below are active.'
                    : 'View Only Mode: Entire app is safely locked to read & practice only.',
                style: const TextStyle(fontSize: 11.5),
              ),
              value: settings.isEditMode,
              activeColor: Colors.orange.shade800,
              onChanged: (val) => settings.setEditMode(val),
            ),

            if (!settings.isEditMode) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.blue.withOpacity(0.14) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primaryBlue.withOpacity(0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: primaryBlue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'View-Only lock active across all tabs. Enable Master Edit Mode to apply the controls below.',
                        style: TextStyle(fontSize: 11, color: primaryBlue, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 18),

            // 2. Edit & Rename Controls
            _buildGranularSwitch(
              isMasterOn: settings.isEditMode,
              icon: Icons.drive_file_rename_outline,
              iconColor: Colors.indigo,
              title: 'Edit & Rename Controls',
              subtitle: 'Rename subjects/folders, edit notes, flashcards, questions & exam reminders',
              value: settings.allowEditActions,
              onChanged: (val) => settings.setAllowEditActions(val),
            ),
            const Divider(height: 12),

            // 3. Delete Actions Control (Default OFF)
            _buildGranularSwitch(
              isMasterOn: settings.isEditMode,
              icon: Icons.delete_sweep_outlined,
              iconColor: settings.showDeleteActions ? Colors.red : Colors.green.shade700,
              title: 'Delete Actions (Default OFF)',
              subtitle: settings.showDeleteActions
                  ? 'Caution: Delete buttons visible across categories, PDFs, vault, notes & quizzes'
                  : 'Safe: All delete buttons hidden across the app to prevent accidental deletion',
              value: settings.showDeleteActions,
              activeColor: Colors.red,
              onChanged: (val) => settings.setShowDeleteActions(val),
            ),
            const Divider(height: 12),

            // 4. File & Import Controls
            _buildGranularSwitch(
              isMasterOn: settings.isEditMode,
              icon: Icons.upload_file_outlined,
              iconColor: Colors.teal,
              title: 'File & Import Controls',
              subtitle: 'Import PDFs, add ID Vault docs, import CSV quizzes & save PDF notes',
              value: settings.allowFileControls,
              activeColor: Colors.teal,
              onChanged: (val) => settings.setAllowFileControls(val),
            ),
            const Divider(height: 12),

            // 5. Folder & Category Controls
            _buildGranularSwitch(
              isMasterOn: settings.isEditMode,
              icon: Icons.create_new_folder_outlined,
              iconColor: Colors.purple,
              title: 'Folder & Category Controls',
              subtitle: 'Create new subjects, categories, subfolders & nested topic folders',
              value: settings.allowFolderControls,
              activeColor: Colors.purple,
              onChanged: (val) => settings.setAllowFolderControls(val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGranularSwitch({
    required bool isMasterOn,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? activeColor,
  }) {
    return Opacity(
      opacity: isMasterOn ? 1.0 : 0.65,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: CircleAvatar(
          radius: 17,
          backgroundColor: iconColor.withOpacity(0.12),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11.5)),
        value: value,
        activeColor: activeColor ?? const Color(0xFF1E3A8A),
        onChanged: onChanged,
      ),
    );
  }

  void _confirmEnableFullControl(BuildContext context, SettingsProvider settings) {
    if (settings.canDelete) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Enable Full Control?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'This will enable Edit, File, Folder, and Delete actions across the entire app. You can switch back to Safe Edit or View Only anytime.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              settings.applyMasterControlPreset('full_control');
            },
            child: const Text('Enable Full Control'),
          ),
        ],
      ),
    );
  }
}

Future<void> showMasterControlModal(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: BoxDecoration(
        color: Theme.of(ctx).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const MasterEditViewControlSection(compact: true),
            ],
          ),
        ),
      ),
    ),
  );
}
