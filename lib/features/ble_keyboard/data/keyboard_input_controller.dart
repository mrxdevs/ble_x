import 'dart:async';

/// Represents a single keystroke event
class KeystrokeEvent {
  final String key;
  final List<String> modifiers;
  final DateTime timestamp;
  final List<int> rawData;

  KeystrokeEvent({
    required this.key,
    required this.modifiers,
    required this.timestamp,
    required this.rawData,
  });

  @override
  String toString() {
    String modifierStr = modifiers.isNotEmpty ? '${modifiers.join('+')}+' : '';
    return '$modifierStr$key';
  }
}

/// Controller for managing keyboard input state and history
class KeyboardInputController {
  static final KeyboardInputController _instance = KeyboardInputController._internal();
  factory KeyboardInputController() => _instance;
  KeyboardInputController._internal();

  // Stream controllers
  final _keystrokeController = StreamController<KeystrokeEvent>.broadcast();
  final _modifierStateController = StreamController<List<String>>.broadcast();

  // Keystroke history
  final List<KeystrokeEvent> _history = [];
  int maxHistorySize = 100;

  // Current state
  List<String> _currentModifiers = [];

  // Getters
  Stream<KeystrokeEvent> get keystrokeStream => _keystrokeController.stream;
  Stream<List<String>> get modifierStateStream => _modifierStateController.stream;
  List<KeystrokeEvent> get history => List.unmodifiable(_history);
  List<String> get currentModifiers => List.unmodifiable(_currentModifiers);

  /// Add a new keystroke event
  void addKeystroke(KeystrokeEvent event) {
    // Add to history
    _history.insert(0, event);

    // Limit history size
    if (_history.length > maxHistorySize) {
      _history.removeLast();
    }

    // Update current modifiers
    _currentModifiers = event.modifiers;

    // Emit events
    _keystrokeController.add(event);
    _modifierStateController.add(_currentModifiers);
  }

  /// Clear keystroke history
  void clearHistory() {
    _history.clear();
  }

  /// Update modifier state without adding a keystroke
  void updateModifiers(List<String> modifiers) {
    _currentModifiers = modifiers;
    _modifierStateController.add(_currentModifiers);
  }

  /// Dispose resources
  void dispose() {
    _keystrokeController.close();
    _modifierStateController.close();
  }
}
