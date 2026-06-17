import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/call_service.dart';

class InCallScreen extends StatefulWidget {
  final String number;
  final String? name;
  const InCallScreen({super.key, required this.number, this.name});

  @override
  State<InCallScreen> createState() => _InCallScreenState();
}

class _InCallScreenState extends State<InCallScreen> {
  static const _eventChannel =
      EventChannel('com.example.dialer_app/call_state');

  // Call state from native
  String _callState = 'dialing'; // dialing | ringing | active | holding | disconnected
  StreamSubscription? _stateSub;

  // Controls
  bool _muted = false;
  bool _speaker = false;
  bool _held = false;
  bool _showKeypad = false;

  // Timer — only runs when state == active
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _stateSub = _eventChannel
        .receiveBroadcastStream()
        .listen(_onStateChange, onError: (_) {});
  }

  void _onStateChange(dynamic event) {
    final state = event as String;
    if (!mounted) return;
    setState(() => _callState = state);

    if (state == 'active') {
      // Start the call timer only once the call is actually picked up
      _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _seconds++);
      });
    } else if (state == 'disconnected') {
      _timer?.cancel();
      // Auto-close the in-call screen
      if (mounted) Navigator.of(context).pop();
    } else {
      // Not active — stop timer if it was running (e.g. went to hold)
      if (state == 'holding') {
        _timer?.cancel();
        _timer = null;
      }
    }
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  String get _elapsed {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _statusLabel {
    switch (_callState) {
      case 'dialing':     return 'Calling…';
      case 'connecting':  return 'Connecting…';
      case 'ringing':     return 'Ringing…';
      case 'active':      return _elapsed;
      case 'holding':     return 'On hold';
      case 'disconnected':return 'Call ended';
      default:            return _callState;
    }
  }

  Future<void> _hangUp() async {
    await CallService.endCall();
  }

  Future<void> _toggleMute() async {
    setState(() => _muted = !_muted);
    await CallService.setMute(_muted);
  }

  Future<void> _toggleSpeaker() async {
    setState(() => _speaker = !_speaker);
    await CallService.setSpeaker(_speaker);
  }

  Future<void> _toggleHold() async {
    setState(() => _held = !_held);
    await CallService.setHold(_held);
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(40),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
              ),
              child: Icon(
                icon,
                color: active
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    const digits = [
      ['1', ''], ['2', 'ABC'], ['3', 'DEF'],
      ['4', 'GHI'], ['5', 'JKL'], ['6', 'MNO'],
      ['7', 'PQRS'], ['8', 'TUV'], ['9', 'WXYZ'],
      ['*', ''], ['0', '+'], ['#', ''],
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: digits.map((d) {
        return InkWell(
          onTap: () => CallService.sendDtmf(d[0]),
          borderRadius: BorderRadius.circular(40),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surfaceVariant,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(d[0], style: const TextStyle(fontSize: 22)),
                if (d[1].isNotEmpty)
                  Text(d[1], style: const TextStyle(fontSize: 9)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _callState == 'active';
    final displayName = widget.name ?? widget.number;

    return PopScope(
      canPop: false, // prevent back gesture during call
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 48),
                // Avatar
                CircleAvatar(
                  radius: 48,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    displayName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 40,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(displayName,
                    style: Theme.of(context).textTheme.headlineMedium),
                if (widget.name != null)
                  Text(widget.number,
                      style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                // Status / timer
                Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 18,
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    fontVariations: isActive
                        ? [const FontVariation('wght', 600)]
                        : [],
                  ),
                ),
                const Spacer(),
                if (_showKeypad) ...[
                  _buildKeypad(),
                  const SizedBox(height: 16),
                ],
                // Controls row 1
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _controlButton(
                      icon: _muted ? Icons.mic_off : Icons.mic,
                      label: _muted ? 'Unmute' : 'Mute',
                      onTap: _toggleMute,
                      active: _muted,
                      enabled: isActive,
                    ),
                    _controlButton(
                      icon: _speaker ? Icons.volume_up : Icons.volume_down,
                      label: 'Speaker',
                      onTap: _toggleSpeaker,
                      active: _speaker,
                      enabled: isActive,
                    ),
                    _controlButton(
                      icon: Icons.dialpad,
                      label: 'Keypad',
                      onTap: () =>
                          setState(() => _showKeypad = !_showKeypad),
                      active: _showKeypad,
                      enabled: isActive,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Controls row 2
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _controlButton(
                      icon: _held ? Icons.play_arrow : Icons.pause,
                      label: _held ? 'Unhold' : 'Hold',
                      onTap: _toggleHold,
                      active: _held,
                      enabled: isActive,
                    ),
                    _controlButton(
                      icon: Icons.add_call,
                      label: 'Add call',
                      onTap: () {},
                      enabled: isActive,
                    ),
                    _controlButton(
                      icon: Icons.bluetooth,
                      label: 'Bluetooth',
                      onTap: () {},
                      enabled: isActive,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Hang up
                GestureDetector(
                  onTap: _hangUp,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call_end,
                        color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
