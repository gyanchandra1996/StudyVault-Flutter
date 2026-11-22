import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({Key? key}) : super(key: key);

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pinInput = '';
  String _errorMessage = '';

  void _onDigitPress(String digit, SettingsProvider settings) {
    if (_pinInput.length < 4) {
      final next = _pinInput + digit;
      setState(() {
        _pinInput = next;
        _errorMessage = '';
      });

      if (next.length == 4) {
        final success = settings.unlockWithPin(next);
        if (!success) {
          setState(() {
            _errorMessage = 'Incorrect PIN code. Try again.';
          });
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              setState(() => _pinInput = '');
            }
          });
        }
      }
    }
  }

  void _onDeletePress() {
    if (_pinInput.isNotEmpty) {
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
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withOpacity(0.08),
          border: Border.all(color: accent.withOpacity(0.18)),
        ),
        child: icon != null
            ? Icon(icon, size: 26, color: accent)
            : Text(
                label,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final accent = settings.activeAccentColor;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Icon Header
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.15),
                ),
                child: Icon(Icons.lock_rounded, size: 40, color: accent),
              ),
              const SizedBox(height: 20),
              const Text(
                'StudyVault Protected',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your 4-digit PIN to unlock',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 28),

              // 4 PIN Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final filled = index < _pinInput.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? accent : Colors.transparent,
                      border: Border.all(color: accent, width: 2),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),
              // Error Message
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const Spacer(),

              // Circular Keypad (3x4 Grid)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKeypadButton('1', () => _onDigitPress('1', settings), accent),
                      _buildKeypadButton('2', () => _onDigitPress('2', settings), accent),
                      _buildKeypadButton('3', () => _onDigitPress('3', settings), accent),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKeypadButton('4', () => _onDigitPress('4', settings), accent),
                      _buildKeypadButton('5', () => _onDigitPress('5', settings), accent),
                      _buildKeypadButton('6', () => _onDigitPress('6', settings), accent),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKeypadButton('7', () => _onDigitPress('7', settings), accent),
                      _buildKeypadButton('8', () => _onDigitPress('8', settings), accent),
                      _buildKeypadButton('9', () => _onDigitPress('9', settings), accent),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 72, height: 72),
                      _buildKeypadButton('0', () => _onDigitPress('0', settings), accent),
                      _buildKeypadButton('', _onDeletePress, accent, icon: Icons.backspace_outlined),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_outlined, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    'StudyVault • Developed by Gyanchandra',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
