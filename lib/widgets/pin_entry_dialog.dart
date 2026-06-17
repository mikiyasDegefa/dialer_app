import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/pin_provider.dart';

Future<bool> showPinEntryDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _PinEntryDialog(),
  );
  return result ?? false;
}

class _PinEntryDialog extends StatefulWidget {
  const _PinEntryDialog();
  @override
  State<_PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<_PinEntryDialog> {
  final _ctrl = TextEditingController();
  String? _error;
  int _attempts = 0;
  static const _max = 3;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await context.read<PinProvider>().verifyPin(_ctrl.text);
    if (ok) {
      if (mounted) Navigator.pop(context, true);
      return;
    }
    _attempts++;
    if (_attempts >= _max) {
      if (mounted) Navigator.pop(context, false);
      return;
    }
    setState(() {
      _error = 'Wrong PIN — ${_max - _attempts} attempt(s) left';
      _ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.lock, color: Colors.orange),
      title: const Text('PIN required'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('This number is PIN-protected.\nEnter your PIN to continue.'),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 8,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'PIN',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
