import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'main_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final VoidCallback? onRegistered;

  const RegistrationScreen({Key? key, this.onRegistered}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Gyanchandra Yadav');
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  String _selectedGender = 'Male';
  String _selectedStream = 'Computer Science & IT';
  String? _profileImagePath;
  bool _isSaving = false;

  final List<String> _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final List<String> _streams = [
    'Computer Science & IT',
    'General Competitive Exams',
    'DSSSB / Teaching Exam',
    'SSC / CGL / CHSL',
    'UPSC / State PSC',
    'Banking / IBPS / SBI',
    'Railway (RRB)',
    'GATE / Engineering',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _profileImagePath = picked.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not select image: $e')),
        );
      }
    }
  }

  void _showImagePickerModal() {
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
                'Select Profile Picture',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.camera_alt, color: Color(0xFF1E3A8A)),
                ),
                title: const Text('Take Photo from Camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.photo_library, color: Color(0xFF1E3A8A)),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_profileImagePath != null)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFEF2F2),
                    child: Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _profileImagePath = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    await settings.registerUser(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      mobile: _mobileController.text.trim(),
      gender: _selectedGender,
      profilePicturePath: _profileImagePath,
      targetExam: _selectedStream,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (widget.onRegistered != null) {
        widget.onRegistered!();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1E3A8A); // DigiLocker Royal Blue
    const brightBlue = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // DigiLocker Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 36, left: 24, right: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryBlue, brightBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // DigiLocker Style Shield Emblem
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: primaryBlue,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'DigiStudy Medhavi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Verified Digital Student Locker',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Mandatory One-Time Registration\nSave your credentials safely to start studying',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // Form Card
            Transform.translate(
              offset: const Offset(0, -16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.badge_outlined, color: primaryBlue, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Student Details',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          // Profile Picture Avatar Picker
                          Center(
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 46,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  backgroundImage: (_profileImagePath != null &&
                                          !kIsWeb &&
                                          File(_profileImagePath!).existsSync())
                                      ? FileImage(File(_profileImagePath!))
                                      : null,
                                  child: (_profileImagePath == null ||
                                          (kIsWeb || !File(_profileImagePath!).existsSync()))
                                      ? const Icon(Icons.person, size: 52, color: primaryBlue)
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: InkWell(
                                    onTap: _showImagePickerModal,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: primaryBlue,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.25),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: TextButton.icon(
                              onPressed: _showImagePickerModal,
                              icon: const Icon(Icons.add_a_photo, size: 15, color: brightBlue),
                              label: Text(
                                _profileImagePath == null
                                    ? 'Upload Profile Picture (Optional)'
                                    : 'Change Profile Picture',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: brightBlue,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Name
                          const Text(
                            'Full Name *',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: 'e.g. Gyanchandra Yadav',
                              prefixIcon: const Icon(Icons.person_outline, color: brightBlue),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email
                          const Text(
                            'Email Address *',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'e.g. student@gmail.com',
                              prefixIcon: const Icon(Icons.email_outlined, color: brightBlue),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!val.contains('@') || !val.contains('.')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Mobile Number
                          const Text(
                            'Mobile Number *',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: '10-digit mobile number',
                              prefixIcon: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.phone_android, color: brightBlue, size: 20),
                                    SizedBox(width: 4),
                                    Text('+91', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your mobile number';
                              }
                              if (val.trim().length < 10) {
                                return 'Please enter a valid 10-digit number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Gender Selection Dropdown (Fixed visibility & styling)
                          const Text(
                            'Gender *',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedGender,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, color: primaryBlue),
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Select Gender',
                              prefixIcon: const Icon(Icons.people_outline, color: brightBlue),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: brightBlue, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            items: _genders.map((g) {
                              return DropdownMenuItem<String>(
                                value: g,
                                child: Text(
                                  g,
                                  style: const TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedGender = val);
                              }
                            },
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please select your gender';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Target Exam / Stream
                          const Text(
                            'Target Stream / Exam',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStream,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, color: primaryBlue),
                                items: _streams.map((s) {
                                  return DropdownMenuItem(
                                    value: s,
                                    child: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedStream = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _isSaving ? null : _submitRegistration,
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.lock_open_rounded, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Register & Access DigiStudy',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Center(
                            child: Text(
                              '🔒 All details are securely saved in your local database',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
