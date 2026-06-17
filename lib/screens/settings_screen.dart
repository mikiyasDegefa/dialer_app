import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/pin_provider.dart';
import '../services/call_service.dart';
import '../widgets/pin_entry_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    _checkDefault();
  }

  Future<void> _checkDefault() async {
    final v = await CallService.isDefaultDialer();
    if (mounted) setState(() => _isDefault = v);
  }

  Future<void> _setPin(PinProvider pin) async {
    if (pin.hasPin) {
      final ok = await showPinEntryDialog(context);
      if (!ok) return;
    }
    final ctrl1 = TextEditingController();
    final ctrl2 = TextEditingController();
    String? err;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(pin.hasPin ? 'Change PIN' : 'Set PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl1,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'New PIN (4–8 digits)'),
              ),
              TextField(
                controller: ctrl2,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Confirm PIN'),
              ),
              if (err != null)
                Text(err!, style: const TextStyle(color: Colors.red)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (ctrl1.text.length < 4) {
                  setS(() => err = 'Minimum 4 digits');
                  return;
                }
                if (ctrl1.text != ctrl2.text) {
                  setS(() => err = 'PINs do not match');
                  return;
                }
                await pin.setPin(ctrl1.text);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearPin(PinProvider pin) async {
    final ok = await showPinEntryDialog(context);
    if (!ok) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove PIN?'),
        content: const Text(
            'All protected numbers will stay in the list but the PIN gate will be inactive until you set a new PIN.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await pin.clearPin();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pin = context.watch<PinProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Default dialer section
          _SectionHeader(title: 'Default dialer'),
          ListTile(
            leading: Icon(
              _isDefault ? Icons.check_circle : Icons.phone_outlined,
              color: _isDefault ? Colors.green : null,
            ),
            title: Text(_isDefault ? 'This is your default dialer' : 'Not set as default dialer'),
            subtitle: Text(_isDefault
                ? 'All calls go through this app'
                : 'Set as default to protect calls from any dialer'),
            trailing: _isDefault
                ? null
                : FilledButton(
                    onPressed: () async {
                      await CallService.requestDefaultDialer();
                      await Future.delayed(const Duration(seconds: 1));
                      _checkDefault();
                    },
                    child: const Text('Set default'),
                  ),
          ),

          const Divider(),
          _SectionHeader(title: 'PIN protection'),
          ListTile(
            leading: Icon(
              pin.hasPin ? Icons.lock : Icons.lock_open,
              color: pin.hasPin ? Colors.orange : null,
            ),
            title: Text(pin.hasPin ? 'PIN is set' : 'No PIN set'),
            subtitle: Text(pin.hasPin
                ? 'Protected numbers require this PIN before calling'
                : 'Set a PIN to start protecting numbers'),
            trailing: FilledButton(
              onPressed: () => _setPin(pin),
              child: Text(pin.hasPin ? 'Change PIN' : 'Set PIN'),
            ),
          ),
          if (pin.hasPin)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove PIN'),
              onTap: () => _clearPin(pin),
            ),

          const Divider(),
          _SectionHeader(title: 'Protected numbers (${pin.protectedNumbers.length})'),
          if (pin.protectedNumbers.isEmpty)
            const ListTile(
              title: Text('No protected numbers yet'),
              subtitle: Text('Open a contact and tap the lock icon to protect a number'),
            ),
          ...pin.protectedNumbers.map((n) => ListTile(
                leading: const Icon(Icons.lock, color: Colors.orange),
                title: Text(n['displayName'] ?? n['number'] ?? ''),
                subtitle: Text(n['number'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final ok = await showPinEntryDialog(context);
                    if (!ok) return;
                    await pin.removeProtected(n['number'] ?? '');
                  },
                ),
              )),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          fontSize: 13,
        ),
      ),
    );
  }
}
