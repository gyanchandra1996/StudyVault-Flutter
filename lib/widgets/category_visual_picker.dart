import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/category.dart';

class CategoryIconPreset {
  final String id;
  final String label;
  final IconData icon;
  final String colorHex;

  const CategoryIconPreset({
    required this.id,
    required this.label,
    required this.icon,
    required this.colorHex,
  });
}

const List<CategoryIconPreset> kCategoryIconPresets = [
  CategoryIconPreset(id: 'computer', label: 'CS / Tech', icon: Icons.laptop_mac_rounded, colorHex: '#2563EB'),
  CategoryIconPreset(id: 'calculate', label: 'Math', icon: Icons.calculate_rounded, colorHex: '#1D4ED8'),
  CategoryIconPreset(id: 'physics', label: 'Physics', icon: Icons.hub_rounded, colorHex: '#1E40AF'),
  CategoryIconPreset(id: 'science', label: 'Chemistry', icon: Icons.science_rounded, colorHex: '#10B981'),
  CategoryIconPreset(id: 'menu_book', label: 'GK / Study', icon: Icons.menu_book_rounded, colorHex: '#0284C7'),
  CategoryIconPreset(id: 'trophy', label: 'Current / Top', icon: Icons.emoji_events_rounded, colorHex: '#D97706'),
  CategoryIconPreset(id: 'psychology', label: 'Reasoning', icon: Icons.psychology_rounded, colorHex: '#7C3AED'),
  CategoryIconPreset(id: 'public', label: 'Geography', icon: Icons.public_rounded, colorHex: '#0D9488'),
  CategoryIconPreset(id: 'translate', label: 'Language', icon: Icons.translate_rounded, colorHex: '#EA580C'),
  CategoryIconPreset(id: 'history', label: 'History', icon: Icons.history_edu_rounded, colorHex: '#B45309'),
  CategoryIconPreset(id: 'storage', label: 'Data / DB', icon: Icons.storage_rounded, colorHex: '#E11D48'),
  CategoryIconPreset(id: 'lan', label: 'Networks', icon: Icons.lan_rounded, colorHex: '#059669'),
  CategoryIconPreset(id: 'code', label: 'Coding', icon: Icons.code_rounded, colorHex: '#D97706'),
  CategoryIconPreset(id: 'memory', label: 'Systems', icon: Icons.memory_rounded, colorHex: '#4F46E5'),
  CategoryIconPreset(id: 'gavel', label: 'Polity / Law', icon: Icons.account_balance_rounded, colorHex: '#1E3A8A'),
  CategoryIconPreset(id: 'folder', label: 'Folder', icon: Icons.folder_rounded, colorHex: '#6366F1'),
];

const List<String> kCategoryColorHexes = [
  '#2563EB',
  '#4F46E5',
  '#7C3AED',
  '#0284C7',
  '#0D9488',
  '#10B981',
  '#D97706',
  '#EA580C',
  '#E11D48',
  '#1E3A8A',
];

Color parseCategoryColor(String hex, {Color fallback = const Color(0xFF2563EB)}) {
  try {
    final clean = hex.trim().replaceAll('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
    if (clean.length == 8) {
      return Color(int.parse(clean, radix: 16));
    }
  } catch (_) {}
  return fallback;
}

IconData getCategoryIconData(String iconName) {
  for (final preset in kCategoryIconPresets) {
    if (preset.id == iconName) return preset.icon;
  }
  switch (iconName) {
    case 'school':
      return Icons.school_rounded;
    case 'biotech':
      return Icons.biotech_rounded;
    default:
      return Icons.folder_rounded;
  }
}

/// Renders either the category's custom uploaded image or its pre-data icon badge.
class CategoryVisualBadge extends StatelessWidget {
  final Category category;
  final double size;
  final double borderRadius;
  final bool circular;
  final Color? overrideColor;

  const CategoryVisualBadge({
    Key? key,
    required this.category,
    this.size = 46,
    this.borderRadius = 13,
    this.circular = false,
    this.overrideColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = overrideColor ?? parseCategoryColor(category.color);
    final hasImage = category.imagePath.isNotEmpty &&
        !kIsWeb &&
        File(category.imagePath).existsSync();

    if (hasImage) {
      final img = Image.file(
        File(category.imagePath),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * 2.5).round(),
        errorBuilder: (_, __, ___) => _buildIconBox(color),
      );
      return circular
          ? ClipOval(child: img)
          : ClipRRect(borderRadius: BorderRadius.circular(borderRadius), child: img);
    }

    return _buildIconBox(color);
  }

  Widget _buildIconBox(Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Icon(
        getCategoryIconData(category.icon),
        color: color,
        size: size * 0.54,
      ),
    );
  }
}

Future<String?> _persistCategoryImage(String srcPath) async {
  try {
    final appDir = await getApplicationDocumentsDirectory();
    final imgDir = Directory(p.join(appDir.path, 'category_images'));
    if (!await imgDir.exists()) {
      await imgDir.create(recursive: true);
    }
    final ext = p.extension(srcPath).isNotEmpty ? p.extension(srcPath) : '.jpg';
    final destPath = p.join(imgDir.path, 'cat_${DateTime.now().millisecondsSinceEpoch}$ext');
    final copied = await File(srcPath).copy(destPath);
    return copied.path;
  } catch (_) {
    return srcPath;
  }
}

/// Reusable dialog to add or edit a Category or Subcategory, with full support
/// for choosing either a pre-data icon + color OR a custom image.
Future<void> showCategoryEditorDialog({
  required BuildContext context,
  Category? existing,
  String? parentTitle,
  int? parentId,
  int? examId,
  required Future<void> Function(Category category) onSave,
}) async {
  final isEditing = existing != null;
  final isSubcategory = parentId != null || (existing?.parentId != null);

  final titleController = TextEditingController(text: existing?.title ?? '');
  final descController = TextEditingController(text: existing?.description ?? '');

  String selectedIcon = existing?.icon.isNotEmpty == true
      ? existing!.icon
      : (isSubcategory ? 'folder' : 'computer');
  String selectedColor = existing?.color.isNotEmpty == true
      ? existing!.color
      : '#2563EB';
  String selectedImagePath = existing?.imagePath ?? '';
  bool useCustomImage = selectedImagePath.isNotEmpty;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        final accentColor = parseCategoryColor(selectedColor);
        final hasValidImg = selectedImagePath.isNotEmpty &&
            !kIsWeb &&
            File(selectedImagePath).existsSync();

        Future<void> pickFromGalleryOrCamera(ImageSource source) async {
          try {
            final picker = ImagePicker();
            final picked = await picker.pickImage(
              source: source,
              maxWidth: 640,
              maxHeight: 640,
              imageQuality: 85,
            );
            if (picked != null) {
              final savedPath = await _persistCategoryImage(picked.path);
              if (savedPath != null && ctx.mounted) {
                setDialogState(() {
                  selectedImagePath = savedPath;
                  useCustomImage = true;
                });
              }
            }
          } catch (e) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('Could not pick image: $e')),
              );
            }
          }
        }

        Future<void> pickFromFiles() async {
          try {
            final res = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
            );
            if (res != null && res.files.single.path != null) {
              final savedPath = await _persistCategoryImage(res.files.single.path!);
              if (savedPath != null && ctx.mounted) {
                setDialogState(() {
                  selectedImagePath = savedPath;
                  useCustomImage = true;
                });
              }
            }
          } catch (e) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('File picker error: $e')),
              );
            }
          }
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: (useCustomImage && hasValidImg)
                    ? Image.file(File(selectedImagePath), fit: BoxFit.cover)
                    : Icon(getCategoryIconData(selectedIcon), color: accentColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing
                          ? (isSubcategory ? 'Edit Subcategory' : 'Edit Category')
                          : (isSubcategory ? 'Add Subcategory' : 'Add Category'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    if (parentTitle != null && parentTitle.isNotEmpty)
                      Text(
                        'Inside: $parentTitle',
                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.normal),
                      ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: !isEditing,
                    decoration: InputDecoration(
                      labelText: isSubcategory ? 'Subcategory / Topic Name *' : 'Category Name *',
                      hintText: isSubcategory
                          ? 'e.g. Data Structure, Operating System'
                          : 'e.g. Mathematics, Physics, Computer Science',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Category Icon or Image',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                  const SizedBox(height: 8),

                  // Toggle: Pre-data Icon vs Custom Image
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setDialogState(() => useCustomImage = false),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: !useCustomImage ? const Color(0xFF1E3A8A) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: !useCustomImage ? const Color(0xFF1E3A8A) : Colors.grey.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.apps_rounded,
                                  size: 16,
                                  color: !useCustomImage ? Colors.white : Colors.grey.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Pre-data Icon',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: !useCustomImage ? Colors.white : Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => setDialogState(() => useCustomImage = true),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: useCustomImage ? const Color(0xFF1E3A8A) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: useCustomImage ? const Color(0xFF1E3A8A) : Colors.grey.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 16,
                                  color: useCustomImage ? Colors.white : Colors.grey.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Custom Image',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: useCustomImage ? Colors.white : Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (!useCustomImage) ...[
                    // Pre-data Icons Grid
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kCategoryIconPresets.map((preset) {
                        final isSelected = selectedIcon == preset.id;
                        final pColor = parseCategoryColor(preset.colorHex);
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = preset.id;
                              selectedColor = preset.colorHex;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 62,
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? pColor.withOpacity(0.16) : Colors.grey.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? pColor : Colors.grey.withOpacity(0.22),
                                width: isSelected ? 1.6 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(preset.icon, color: pColor, size: 22),
                                const SizedBox(height: 3),
                                Text(
                                  preset.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Text('Badge Color:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kCategoryColorHexes.map((hex) {
                        final c = parseCategoryColor(hex);
                        final isSel = selectedColor.toUpperCase() == hex.toUpperCase();
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = hex),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel ? Colors.black87 : Colors.white,
                                width: isSel ? 2.5 : 1.5,
                              ),
                              boxShadow: [
                                if (isSel) BoxShadow(color: c.withOpacity(0.45), blurRadius: 5),
                              ],
                            ),
                            child: isSel ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    // Custom Image Picker Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.withOpacity(0.24)),
                      ),
                      child: Column(
                        children: [
                          if (hasValidImg)
                            Stack(
                              alignment: Alignment.topRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    File(selectedImagePath),
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                InkWell(
                                  onTap: () => setDialogState(() => selectedImagePath = ''),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 42, color: Colors.grey.shade500),
                                const SizedBox(height: 6),
                                const Text(
                                  'Choose an image for this category',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.photo_library_outlined, size: 16),
                                label: const Text('Gallery', style: TextStyle(fontSize: 12)),
                                onPressed: () => pickFromGalleryOrCamera(ImageSource.gallery),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.camera_alt_outlined, size: 16),
                                label: const Text('Camera', style: TextStyle(fontSize: 12)),
                                onPressed: () => pickFromGalleryOrCamera(ImageSource.camera),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.folder_open_outlined, size: 16),
                                label: const Text('Files', style: TextStyle(fontSize: 12)),
                                onPressed: pickFromFiles,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please enter a category name.')),
                  );
                  return;
                }
                final effectiveImagePath = useCustomImage ? selectedImagePath : '';
                final cat = existing != null
                    ? existing.copyWith(
                        title: title,
                        description: descController.text.trim(),
                        icon: selectedIcon,
                        color: selectedColor,
                        imagePath: effectiveImagePath,
                      )
                    : Category(
                        title: title,
                        description: descController.text.trim(),
                        icon: selectedIcon,
                        color: selectedColor,
                        imagePath: effectiveImagePath,
                        parentId: parentId,
                        examId: examId,
                      );
                if (ctx.mounted) Navigator.pop(ctx);
                await onSave(cat);
              },
              child: Text(isEditing ? 'Save Changes' : 'Create'),
            ),
          ],
        );
      },
    ),
  );
}
