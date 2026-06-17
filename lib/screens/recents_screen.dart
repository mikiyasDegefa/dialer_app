import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'package:provider/provider.dart';
import '../providers/call_log_provider.dart';
import '../providers/pin_provider.dart';
import '../services/call_service.dart';
import '../widgets/pin_entry_dialog.dart';
import 'in_call_screen.dart';

class RecentsScreen extends StatelessWidget {
  const RecentsScreen({super.key});

  IconData _typeIcon(CallType? type) {
    switch (type) {
      case CallType.incoming: return Icons.call_received;
      case CallType.outgoing: return Icons.call_made;
      case CallType.missed:   return Icons.call_missed;
      case CallType.rejected: return Icons.call_end;
      default:                return Icons.call;
    }
  }

  Color _typeColor(CallType? type, BuildContext context) {
    switch (type) {
      case CallType.missed:
      case CallType.rejected:
        return Colors.red;
      case CallType.incoming:
        return Colors.green;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _when(int? timestamp) {
    if (timestamp == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      return days[dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  Future<void> _callNumber(BuildContext context, String number) async {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<CallLogProvider>().load(),
          ),
        ],
      ),
      body: Consumer<CallLogProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.entries.isEmpty) {
            return const Center(child: Text('No recent calls'));
          }
          return ListView.builder(
            itemCount: provider.entries.length,
            itemBuilder: (context, i) {
              final entry = provider.entries[i];
              final number = entry.number ?? 'Unknown';
              final name = entry.name ?? number;
              final duration = provider.formatDuration(entry.duration);
              final isProtected = context.watch<PinProvider>().isProtected(number);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      _typeColor(entry.callType, context).withOpacity(0.15),
                  child: Icon(
                    _typeIcon(entry.callType),
                    color: _typeColor(entry.callType, context),
                    size: 20,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
                    if (isProtected)
                      const Icon(Icons.lock, size: 14, color: Colors.orange),
                  ],
                ),
                subtitle: Text(
                  '${number == name ? '' : '$number  ·  '}${duration.isNotEmpty ? '$duration  ·  ' : ''}${_when(entry.timestamp)}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.call_outlined),
                  onPressed: () => _callNumber(context, number),
                ),
                onTap: () => _callNumber(context, number),
              );
            },
          );
        },
      ),
    );
  }
}
