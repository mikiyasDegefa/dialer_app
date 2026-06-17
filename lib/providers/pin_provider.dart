import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinProvider extends ChangeNotifier {
  static const _pinKey = 'pin_hash';
  static const _protectedKey = 'protected_numbers';

  bool _hasPin = false;
  List<Map<String, String>> _protectedNumbers = [];

  bool get hasPin => _hasPin;
  List<Map<String, String>> get protectedNumbers => _protectedNumbers;

  PinProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _hasPin = prefs.containsKey(_pinKey);
    final raw = prefs.getStringList(_protectedKey) ?? [];
    _protectedNumbers = raw
        .map((s) => Map<String, String>.from(jsonDecode(s)))
        .toList();
    notifyListeners();
  }

  static String _hash(String pin) =>
      sha256.convert(utf8.encode(pin)).toString();

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, _hash(pin));
    _hasPin = true;
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_pinKey);
    return stored != null && stored == _hash(pin);
  }

  Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    _hasPin = false;
    notifyListeners();
  }

  bool isProtected(String number) {
    final normalized = _normalize(number);
    return _protectedNumbers
        .any((n) => _normalize(n['number'] ?? '') == normalized);
  }

  Future<void> addProtected(String displayName, String number) async {
    if (isProtected(number)) return;
    _protectedNumbers.add({'displayName': displayName, 'number': number});
    await _saveProtected();
    notifyListeners();
  }

  Future<void> removeProtected(String number) async {
    final normalized = _normalize(number);
    _protectedNumbers
        .removeWhere((n) => _normalize(n['number'] ?? '') == normalized);
    await _saveProtected();
    notifyListeners();
  }

  Future<void> _saveProtected() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _protectedKey,
      _protectedNumbers.map((n) => jsonEncode(n)).toList(),
    );
  }

  static String _normalize(String number) =>
      number.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
}
