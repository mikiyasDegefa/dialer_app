import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsProvider extends ChangeNotifier {
  List<Contact> _contacts = [];
  bool _loading = false;
  bool _permissionGranted = false;

  List<Contact> get contacts => _contacts;
  bool get loading => _loading;
  bool get permissionGranted => _permissionGranted;

  Future<void> loadContacts() async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      _permissionGranted = false;
      notifyListeners();
      return;
    }
    _permissionGranted = true;
    _loading = true;
    notifyListeners();

    _contacts = await FlutterContacts.getContacts(withProperties: true);
    _loading = false;
    notifyListeners();
  }

  List<Contact> search(String query) {
    if (query.isEmpty) return _contacts;
    final q = query.toLowerCase();
    return _contacts.where((c) {
      final name = c.displayName.toLowerCase();
      final phones = c.phones.map((p) => p.number).join(' ');
      return name.contains(q) || phones.contains(q);
    }).toList();
  }
}
