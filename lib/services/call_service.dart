import 'package:flutter/services.dart';

class CallService {
  static const _channel = MethodChannel('com.example.dialer_app/calls');

  /// Place an outgoing call via native Android TelecomManager.
  static Future<void> placeCall(String number) async {
    await _channel.invokeMethod('placeCall', {'number': number});
  }

  /// End the current active call.
  static Future<void> endCall() async {
    await _channel.invokeMethod('endCall');
  }

  /// Mute / unmute the microphone during a call.
  static Future<void> setMute(bool muted) async {
    await _channel.invokeMethod('setMute', {'muted': muted});
  }

  /// Toggle the speaker (loudspeaker) on/off.
  static Future<void> setSpeaker(bool on) async {
    await _channel.invokeMethod('setSpeaker', {'on': on});
  }

  /// Send a DTMF digit during a call (keypad tones).
  static Future<void> sendDtmf(String digit) async {
    await _channel.invokeMethod('sendDtmf', {'digit': digit});
  }

  /// Hold / unhold the current call.
  static Future<void> setHold(bool hold) async {
    await _channel.invokeMethod('setHold', {'hold': hold});
  }

  /// Request the user to set this app as the default phone/dialer app.
  static Future<void> requestDefaultDialer() async {
    await _channel.invokeMethod('requestDefaultDialer');
  }

  /// Returns true if this app is currently the default dialer.
  static Future<bool> isDefaultDialer() async {
    final result = await _channel.invokeMethod<bool>('isDefaultDialer');
    return result ?? false;
  }
}
