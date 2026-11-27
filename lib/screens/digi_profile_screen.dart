import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/user_profile.dart';
import '../widgets/backup_restore_modal.dart';
import 'settings_screen.dart';
import 'favorites_screen.dart';

class DigiProfileScreen extends StatelessWidget {
  const DigiProfileScreen({Key? key}) : super(key: key);

  Future<void> _saveAndSetProfilePic(String srcPath, SettingsProvider settings, BuildContext context) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final ext = p.extension(srcPath);
      final destPath = p.join(appDir.path, 'profile_${DateTime.now().millisecondsSinceEpoch}$ext');
      await File(srcPath).copy(destPath);
      await settings.updateProfilePicture(destPath);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Profile picture updated!'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (_) {
      await settings.updateProfilePicture(srcPath);
    }
  }

  Future<void> _pickAndSetProfilePicture(BuildContext context, SettingsProvider settings) async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Change Profile Picture',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.camera_alt, color: Color(0xFF1E3A8A)),
                ),
                title: const Text('Take Photo with Camera'),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final picked = await picker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 85,
                    );
                    if (picked != null) {
                      await _saveAndSetProfilePic(picked.path, settings, context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Camera error: $e')),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.photo_library, color: Color(0xFF1E3A8A)),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 85,
                    );
                    if (picked != null) {
                      await _saveAndSetProfilePic(picked.path, settings, context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gallery error: $e')),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.folder_open, color: Color(0xFF1E3A8A)),
                ),
                title: const Text('Choose from Device Files'),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final res = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
                    );
                    if (res != null && res.files.single.path != null) {
                      await _saveAndSetProfilePic(res.files.single.path!, settings, context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('File picker error: $e')),
                      );
                    }
                  }
                },
              ),
              if (settings.userProfile.profilePicturePath.isNotEmpty)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFEF2F2),
                    child: Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: const Text('Remove Profile Picture', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await settings.updateProfilePicture('');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Confirm Logout',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out from Medhavi?\n\nYour study records, tests, and vault items remain securely saved on this device. You will be redirected to the student registration/login screen.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);
              await settings.logout();
            },
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, SettingsProvider settings) {
    final profile = settings.userProfile;
    final nameCtrl = TextEditingController(text: profile.name);
    final emailCtrl = TextEditingController(text: profile.email);
    final mobileCtrl = TextEditingController(text: profile.mobile);
    String selectedGender = profile.gender;
    final genders = ['Male', 'Female', 'Other', 'Prefer not to say'];
    if (!genders.contains(selectedGender)) {
      selectedGender = 'Male';
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Edit Student Profile', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: mobileCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),
                  const Text('Gender', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: genders.map((g) {
                      return DropdownMenuItem<String>(
                        value: g,
                        child: Text(g),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedGender = val);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (nameCtrl.text.trim().isNotEmpty) {
                    await settings.registerUser(
                      name: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      mobile: mobileCtrl.text.trim(),
                      gender: selectedGender,
                    );
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Save Details'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = settings.userProfile;

    const primaryBlue = Color(0xFF1E3A8A);
    const brightBlue = Color(0xFF2563EB);

    final bool hasValidPic = profile.profilePicturePath.isNotEmpty &&
        !kIsWeb &&
        File(profile.profilePicturePath).existsSync();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Medhavi Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 48, bottom: 24, left: 16, right: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryBlue, brightBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  // Top Navigation Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (Navigator.canPop(context))
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                          tooltip: 'Back',
                          onPressed: () => Navigator.pop(context),
                        )
                      else
                        const SizedBox(width: 40),
                      const Text(
                        'Student Profile',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                        tooltip: 'Edit Profile',
                        onPressed: () => _showEditProfileDialog(context, settings),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Profile Avatar with Change Option
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.white,
                        foregroundImage: hasValidPic ? FileImage(File(profile.profilePicturePath)) : null,
                        child: !hasValidPic
                            ? Text(
                                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'M',
                                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: primaryBlue),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: () => _pickAndSetProfilePicture(context, settings),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt, color: primaryBlue, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.name.isNotEmpty ? profile.name : 'Gyanchandra Yadav',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.email.isNotEmpty ? profile.email : 'student@medhavi.vault',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                  ),
                  if (profile.mobile.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '+91 ${profile.mobile} • ${profile.gender}',
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Verified Medhavi Student',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Edit Profile Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        side: const BorderSide(color: Color(0xFF1E3A8A)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.edit, size: 16, color: Color(0xFF1E3A8A)),
                      label: const Text(
                        'Update Profile',
                        style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _showEditProfileDialog(context, settings),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(120, 44),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_a_photo, size: 16, color: Color(0xFF2563EB)),
                    label: const Text(
                      'Photo',
                      style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _pickAndSetProfilePicture(context, settings),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Mode & Security Settings Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Study & Access Modes',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                      ),
                      const Divider(height: 20),

                      // Edit Mode Switch
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Edit / Creator Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          settings.isEditMode
                              ? 'Enabled: You can create, edit and delete quizzes, folders, and notes.'
                              : 'Disabled: View & Read only mode. Content cannot be accidentally changed.',
                          style: const TextStyle(fontSize: 12),
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: settings.isEditMode ? Colors.orange.withOpacity(0.15) : Colors.blue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            settings.isEditMode ? Icons.edit_note : Icons.visibility,
                            color: settings.isEditMode ? Colors.orange : Colors.blue,
                          ),
                        ),
                        value: settings.isEditMode,
                        activeColor: const Color(0xFF1E3A8A),
                        onChanged: (val) => settings.setEditMode(val),
                      ),

                      const Divider(height: 16),

                      // Dark Mode Switch
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Dark Mode Theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Comfortable night reading style', style: TextStyle(fontSize: 12)),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.dark_mode, color: Colors.indigo),
                        ),
                        value: settings.isDarkMode,
                        activeColor: const Color(0xFF1E3A8A),
                        onChanged: (val) => settings.toggleDarkMode(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // More Options List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.star, color: Colors.amber),
                      title: const Text('Favorite Documents & Bookmarks', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.backup, color: Colors.blue),
                      title: const Text('Backup & Restore Local Data', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => const BackupRestoreModal(),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.settings, color: Colors.blueGrey),
                      title: const Text('Advanced Settings & AI Key', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Clearly Visible Logout Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 1.5,
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.red.withOpacity(0.3), width: 1.2),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.logout_rounded, color: Colors.red, size: 22),
                  ),
                  title: const Text(
                    'Log Out from DigiStudy',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: const Text(
                    'Securely end session and return to registration screen',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.red, size: 16),
                  onTap: () => _showLogoutConfirmation(context, settings),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
