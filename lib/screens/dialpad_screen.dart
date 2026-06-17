import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pin_provider.dart';
import '../services/call_service.dart';
import '../widgets/pin_entry_dialog.dart';
import 'in_call_screen.dart';

class DialpadScreen extends StatefulWidget {
  const DialpadScreen({super.key});
  @override
  State<DialpadScreen> createState() => _DialpadScreenState();
}

class _DialpadScreenState extends State<DialpadScreen> {
  String _digits = '';

  void _append(String d) => setState(() => _digits += d);
  void _backspace() {
    if (_digits.isNotEmpty) setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  Future<void> _call() async {
    if (_digits.isEmpty) return;
    final pinProvider = context.read<PinProvider>();

    if (pinProvider.isProtected(_digits)) {
      if (!pinProvider.hasPin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No PIN set. Please set a PIN in Settings.')),
        );
        return;
      }
      final ok = await showPinEntryDialog(context);
      if (!ok) return;
    }

    await CallService.placeCall(_digits);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => InCallScreen(number: _digits)),
      );
    }
  }

  Widget _key(String digit, [String? sub]) {
    return InkWell(
      onTap: () => _append(digit),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceVariant,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(digit, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w400)),
            if (sub != null)
              Text(sub, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dialpad')),
      body: Column(
        children: [
          const SizedBox(height: 24),
          // Display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _digits.isEmpty ? 'Enter number' : _digits,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      color: _digits.isEmpty
                          ? Theme.of(context).colorScheme.outline
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                if (_digits.isNotEmpty)
                  IconButton(
                    onPressed: _backspace,
                    icon: const Icon(Icons.backspace_outlined),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Keypad
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _key('1', ''),
                    _key('2', 'ABC'),
                    _key('3', 'DEF'),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _key('4', 'GHI'),
                    _key('5', 'JKL'),
                    _key('6', 'MNO'),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _key('7', 'PQRS'),
                    _key('8', 'TUV'),
                    _key('9', 'WXYZ'),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _key('*', ''),
                    _key('0', '+'),
                    _key('#', ''),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    const SizedBox(width: 72),
                    // Call button
                    GestureDetector(
                      onTap: _call,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call, color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(width: 72),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
