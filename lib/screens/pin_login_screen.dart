import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'registration_screen.dart';

class PinLoginScreen extends StatefulWidget {
  final VoidCallback? onLoggedIn;

  const PinLoginScreen({Key? key, this.onLoggedIn}) : super(key: key);

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  String _pinInput = '';
  String _errorMessage = '';
  bool _isChecking = false;

  void _onDigitPress(String digit, SettingsProvider settings) async {
    if (_isChecking || _pinInput.length >= 4) return;

    final next = _pinInput + digit;
    setState(() {
      _pinInput = next;
      _errorMessage = '';
    });

    if (next.length == 4) {
      setState(() => _isChecking = true);
      final success = await settings.loginWithPin(next);
      if (mounted) {
        setState(() => _isChecking = false);
        if (success) {
          if (widget.onLoggedIn != null) {
            widget.onLoggedIn!();
          }
        } else {
          setState(() {
            _errorMessage = 'Incorrect PIN. Try again or enter Master PIN: 1996';
          });
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) setState(() => _pinInput = '');
          });
        }
      }
    }
  }

  void _onDeletePress() {
    if (_pinInput.isNotEmpty && !_isChecking) {
      setState(() {
        _pinInput = _pinInput.substring(0, _pinInput.length - 1);
        _errorMessage = '';
      });
    }
  }

  Widget _buildKeypadButton(String label, VoidCallback onTap, Color accent, {IconData? icon}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 68,
        height: 68,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: accent.withOpacity(0.18)),
        ),
        child: icon != null
            ? Icon(icon, size: 24, color: accent)
            : Text(
                label,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final user = settings.userProfile;
    const primaryBlue = Color(0xFF1E3A8A);
    const brightBlue = Color(0xFF2563EB);

    final bool hasValidPic = user.profilePicturePath.isNotEmpty &&
        !kIsWeb &&
        File(user.profilePicturePath).existsSync();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // DigiLocker Shield Emblem
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryBlue, brightBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),

              // User Profile Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: primaryBlue.withOpacity(0.12),
                backgroundImage: hasValidPic ? FileImage(File(user.profilePicturePath)) : null,
                child: !hasValidPic
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'G',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryBlue),
                      )
                    : null,
              ),
              const SizedBox(height: 12),

              Text(
                'Welcome Back, ${user.name}!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Enter your 4-digit PIN to access your study locker',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // 4 PIN Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final filled = index < _pinInput.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? primaryBlue : Colors.white,
                      border: Border.all(color: primaryBlue, width: 2),
                      boxShadow: filled
                          ? [
                              BoxShadow(
                                color: primaryBlue.withOpacity(0.35),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 12),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                )
              else
                const SizedBox(height: 16),

              const SizedBox(height: 16),

              // Keypad (3x4)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKeypadButton('1', () => _onDigitPress('1', settings), primaryBlue),
                      _buildKeypadButton('2', () => _onDigitPress('2', settings), primaryBlue),
                      _buildKeypadButton('3', () => _onDigitPress('3', settings), primaryBlue),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKeypadButton('4', () => _onDigitPress('4', settings), primaryBlue),
                      _buildKeypadButton('5', () => _onDigitPress('5', settings), primaryBlue),
                      _buildKeypadButton('6', () => _onDigitPress('6', settings), primaryBlue),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKeypadButton('7', () => _onDigitPress('7', settings), primaryBlue),
                      _buildKeypadButton('8', () => _onDigitPress('8', settings), primaryBlue),
                      _buildKeypadButton('9', () => _onDigitPress('9', settings), primaryBlue),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 68, height: 68),
                      _buildKeypadButton('0', () => _onDigitPress('0', settings), primaryBlue),
                      _buildKeypadButton('', _onDeletePress, primaryBlue, icon: Icons.backspace_outlined),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Quick Action: Use Master PIN (1996)
              TextButton.icon(
                icon: const Icon(Icons.key, size: 16, color: primaryBlue),
                label: const Text(
                  'Quick Unlock with Master PIN: 1996',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryBlue),
                ),
                onPressed: () => _onDigitPress('1', settings),
              ),

              const Divider(height: 24),

              // Switch Account / Register Afresh
              TextButton(
                onPressed: () async {
                  await settings.clearRegistration();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                    );
                  }
                },
                child: const Text(
                  'Register as New Student / Switch Profile',
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
