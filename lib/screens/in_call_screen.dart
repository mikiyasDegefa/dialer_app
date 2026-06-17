import 'dart:async';
import 'package:flutter/material.dart';
import '../services/call_service.dart';

class InCallScreen extends StatefulWidget {
  final String number;
  final String? name;
  const InCallScreen({super.key, required this.number, this.name});

  @override
  State<InCallScreen> createState() => _InCallScreenState();
}

class _InCallScreenState extends State<InCallScreen> {
  bool _muted = false;
  bool _speaker = false;
  bool _held = false;
  bool _showKeypad = false;
  int _seconds = 0;
  Timer? _timer;
  String _status = 'Calling...';

  @override
  void initState() {
    super.initState();
    // Start timer after a short delay to simulate call connecting
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _status = 'On call');
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _seconds++);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _elapsed {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _hangUp() async {
    await CallService.endCall();
    if (mounted) Navigator.pop(context);
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
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 48),
              CircleAvatar(
                radius: 48,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  (widget.name ?? widget.number)[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 40,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.name ?? widget.number,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (widget.name != null)
                Text(widget.number,
                    style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(_status,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.outline)),
              if (_seconds > 0)
                Text(_elapsed,
                    style: Theme.of(context).textTheme.titleLarge),
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
                  ),
                  _controlButton(
                    icon: _speaker ? Icons.volume_up : Icons.volume_down,
                    label: 'Speaker',
                    onTap: _toggleSpeaker,
                    active: _speaker,
                  ),
                  _controlButton(
                    icon: Icons.dialpad,
                    label: 'Keypad',
                    onTap: () => setState(() => _showKeypad = !_showKeypad),
                    active: _showKeypad,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Controls row 2
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _controlButton(
                    icon: Icons.pause,
                    label: _held ? 'Unhold' : 'Hold',
                    onTap: _toggleHold,
                    active: _held,
                  ),
                  _controlButton(
                    icon: Icons.add_call,
                    label: 'Add call',
                    onTap: () => Navigator.pop(context),
                  ),
                  _controlButton(
                    icon: Icons.bluetooth,
                    label: 'Bluetooth',
                    onTap: () {},
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
                  child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
