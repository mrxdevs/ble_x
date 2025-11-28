import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:android_intent_plus/android_intent.dart'; // Add this package to pubspec.yaml

// Data Model
class MediaInfo {
  String title;
  String artist;
  int duration; // milliseconds
  Uint8List? artwork;
  bool isPlaying;
  int currentPosition;
  double playbackSpeed;

  MediaInfo({
    this.title = "Not Playing",
    this.artist = "",
    this.duration = 1,
    this.artwork,
    this.isPlaying = false,
    this.currentPosition = 0,
    this.playbackSpeed = 1.0,
  });
}

class SystemMediaController2 {
  static const MethodChannel _control = MethodChannel('com.example.app/media_control');
  static const EventChannel _stream = EventChannel('com.example.app/media_stream');

  static final StreamController<MediaInfo> _controller = StreamController<MediaInfo>.broadcast();
  static Stream<MediaInfo> get mediaStream => _controller.stream;

  static MediaInfo _cache = MediaInfo();

  static void init() {
    _stream.receiveBroadcastStream().listen((event) {
      final data = Map<String, dynamic>.from(event);

      print("Received media info: $data");

      if (data['type'] == 'metadata') {
        _cache.title = data['title'] ?? "Unknown";
        _cache.artist = data['artist'] ?? "Unknown";
        _cache.duration = data['duration'] ?? 1;
        _cache.artwork = data['artwork']; // Uint8List
      } else if (data['type'] == 'state') {
        _cache.isPlaying = data['isPlaying'] ?? false;
        _cache.currentPosition = data['position'] ?? 0;
        _cache.playbackSpeed = (data['speed'] ?? 1.0).toDouble();
      }
      _controller.add(_cache);
    });
  }

  // Commands
  static Future<void> playPause() async => await _control.invokeMethod('playPause');
  static Future<void> next() async => await _control.invokeMethod('next');
  static Future<void> previous() async => await _control.invokeMethod('previous');

  // Open Settings
  static Future<void> openNotificationSettings() async {
    const intent = AndroidIntent(action: 'android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS');
    await intent.launch();
  }
}
