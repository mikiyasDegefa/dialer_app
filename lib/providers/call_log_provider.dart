import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';

class CallLogProvider extends ChangeNotifier {
  List<CallLogEntry> _entries = [];
  bool _loading = false;

  List<CallLogEntry> get entries => _entries;
  bool get loading => _loading;

  Future<void> load() async {
    final status = await Permission.phone.request();
    if (!status.isGranted) return;

    _loading = true;
    notifyListeners();

    final entries = await CallLog.get();
    _entries = entries.toList();
    _loading = false;
    notifyListeners();
  }

  String formatDuration(int? seconds) {
    if (seconds == null || seconds == 0) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }
}
