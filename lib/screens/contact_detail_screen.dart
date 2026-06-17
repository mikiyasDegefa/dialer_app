import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:provider/provider.dart';
import '../providers/pin_provider.dart';
import '../services/call_service.dart';
import '../widgets/pin_entry_dialog.dart';
import 'in_call_screen.dart';

class ContactDetailScreen extends StatelessWidget {
  final Contact contact;
  const ContactDetailScreen({super.key, required this.contact});

  Future<void> _call(BuildContext context, String number) async {
    final pin = context.read<PinProvider>();
    if (pin.isProtected(number)) {
      if (!pin.hasPin) return;
      final ok = await showPinEntryDialog(context);
      if (!ok) return;
    }
    await CallService.placeCall(number);
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => InCallScreen(number: number)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = contact.displayName.isEmpty
        ? '?'
        : contact.displayName
            .split(' ')
            .where((w) => w.isNotEmpty)
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join();

    return Scaffold(
      appBar: AppBar(title: Text(contact.displayName)),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              contact.displayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 24),
          if (contact.phones.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Phone numbers',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            ...contact.phones.map((phone) {
              final isProtected =
                  context.watch<PinProvider>().isProtected(phone.number);
              return ListTile(
                leading: const Icon(Icons.phone),
                title: Text(phone.number),
                subtitle: Text(phone.label.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isProtected)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.lock, size: 16, color: Colors.orange),
                      ),
                    IconButton(
                      icon: const Icon(Icons.call, color: Colors.green),
                      onPressed: () => _call(context, phone.number),
                    ),
                    Consumer<PinProvider>(
                      builder: (ctx, pin, _) => IconButton(
                        icon: Icon(
                          isProtected ? Icons.lock : Icons.lock_open,
                          size: 20,
                          color: isProtected ? Colors.orange : Colors.grey,
                        ),
                        tooltip: isProtected
                            ? 'Remove PIN protection'
                            : 'Add PIN protection',
                        onPressed: () async {
                          if (!pin.hasPin) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Set a PIN first in Settings.'),
                              ),
                            );
                            return;
                          }
                          if (isProtected) {
                            final ok = await showPinEntryDialog(ctx);
                            if (!ok) return;
                            await pin.removeProtected(phone.number);
                          } else {
                            await pin.addProtected(
                                contact.displayName, phone.number);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (contact.emails.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Emails',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            ...contact.emails.map((e) => ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: Text(e.address),
                  subtitle: Text(e.label.name),
                )),
          ],
        ],
      ),
    );
  }
}
