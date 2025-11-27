import 'package:flutter/services.dart';
import 'package:volume_controller/volume_controller.dart';

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

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
    } on PlatformException catch (e) {
      print("Failed to stop: '${e.message}'.");
    }
  }

  static Future<void> setVolume(double volume) async {
    try {
      VolumeController.instance.setVolume(volume);
    } on PlatformException catch (e) {
      print("Failed to set volume: '${e.message}'.");
    }
  }

  static Future<double> getVolume() async {
    try {
      return VolumeController.instance.getVolume();
    } on PlatformException catch (e) {
      print("Failed to get volume: '${e.message}'.");
      return 0.0;
    }
  }

  static Future<void> mute() async {
    try {
      VolumeController.instance.setMute(true);
    } on PlatformException catch (e) {
      print("Failed to mute: '${e.message}'.");
    }
  }

  static Future<void> unmute() async {
    try {
      VolumeController.instance.setMute(false);
    } on PlatformException catch (e) {
      print("Failed to unmute: '${e.message}'.");
    }
  }

  static getVolumeController(Function(double) onVolumeChanged) {
    final controller = VolumeController.instance;
    controller.addListener((volume) {
      onVolumeChanged(volume);
    });
  }

  static dispose() {
    VolumeController.instance.removeListener();
  }
}
