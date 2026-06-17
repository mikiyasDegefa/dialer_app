import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CallLogEntry {
  final String? name;
  final String? number;
  final String? callType; // incoming, outgoing, missed, rejected
  final int? timestamp;
  final int? duration;

  CallLogEntry({
    this.name,
    this.number,
    this.callType,
    this.timestamp,
    this.duration,
  });

  factory CallLogEntry.fromMap(Map m) => CallLogEntry(
        name: m['name'] as String?,
        number: m['number'] as String?,
        callType: m['callType'] as String?,
        timestamp: m['timestamp'] as int?,
        duration: m['duration'] as int?,
      );
}

class CallLogProvider extends ChangeNotifier {
  static const _channel = MethodChannel('com.example.dialer_app/calls');

  List<CallLogEntry> _entries = [];
  bool _loading = false;

  List<CallLogEntry> get entries => _entries;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final raw = await _channel.invokeMethod<List>('getCallLog');
      if (raw != null) {
        _entries = raw
            .map((e) => CallLogEntry.fromMap(Map.from(e as Map)))
            .toList();
      }
    } catch (_) {
      _entries = [];
    }
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
