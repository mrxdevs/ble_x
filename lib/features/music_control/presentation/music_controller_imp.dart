import 'package:flutter/services.dart';

class SystemMediaController {
  // Define a unique channel name
  static const MethodChannel _channel = MethodChannel('com.example.app/media_control');

  /// Toggles Play/Pause on the active media player
  static Future<void> playPause() async {
    print("playPause: ${DateTime.now()}");
    try {
      await _channel.invokeMethod('playPause');
    } on PlatformException catch (e) {
      print("Failed to play/pause: '${e.message}'.");
    }
  }

  /// Skips to the next track
  static Future<void> next() async {
    try {
      await _channel.invokeMethod('next');
    } on PlatformException catch (e) {
      print("Failed to skip: '${e.message}'.");
    }
  }

  /// Skips to the previous track
  static Future<void> previous() async {
    try {
      await _channel.invokeMethod('previous');
    } on PlatformException catch (e) {
      print("Failed to go back: '${e.message}'.");
    }
  }
}
