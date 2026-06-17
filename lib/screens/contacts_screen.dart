import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:provider/provider.dart';
import '../providers/contacts_provider.dart';
import 'contact_detail_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ContactsProvider>().loadContacts(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              controller: _search,
              hintText: 'Search contacts',
              leading: const Icon(Icons.search),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                  ),
              ],
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: Consumer<ContactsProvider>(
              builder: (context, provider, _) {
                if (provider.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!provider.permissionGranted) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.contacts, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Contacts permission required'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => provider.loadContacts(),
                          child: const Text('Grant permission'),
                        ),
                      ],
                    ),
                  );
                }
                final contacts = provider.search(_query);
                if (contacts.isEmpty) {
                  return const Center(child: Text('No contacts found'));
                }
                return _ContactList(contacts: contacts);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactList extends StatelessWidget {
  final List<Contact> contacts;
  const _ContactList({required this.contacts});

  @override
  Widget build(BuildContext context) {
    // Build alphabetical index
    final Map<String, List<Contact>> grouped = {};
    for (final c in contacts) {
      final letter = c.displayName.isEmpty
          ? '#'
          : c.displayName[0].toUpperCase();
      grouped.putIfAbsent(letter, () => []).add(c);
    }
    final keys = grouped.keys.toList()..sort();

    return ListView.builder(
      itemCount: keys.fold(0, (sum, k) => sum + grouped[k]!.length + 1),
      itemBuilder: (context, index) {
        int running = 0;
        for (final key in keys) {
          if (index == running) {
            return _SectionHeader(letter: key);
          }
          running++;
          final group = grouped[key]!;
          if (index < running + group.length) {
            final contact = group[index - running];
            return _ContactTile(contact: contact);
          }
          running += group.length;
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String letter;
  const _SectionHeader({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        letter,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Contact contact;
  const _ContactTile({required this.contact});

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

    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          initials,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(contact.displayName),
      subtitle: contact.phones.isNotEmpty
          ? Text(contact.phones.first.number)
          : null,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ContactDetailScreen(contact: contact),
        ),
      ),
    );
  }
}
