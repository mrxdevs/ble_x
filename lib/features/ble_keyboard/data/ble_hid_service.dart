import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'keyboard_input_controller.dart';

/// BLE HID Service for receiving keyboard input from HID devices
class BleHidService {
  static final BleHidService _instance = BleHidService._internal();
  factory BleHidService() => _instance;
  BleHidService._internal();

  final KeyboardInputController _inputController = KeyboardInputController();
  BluetoothDevice? _connectedDevice;
  StreamSubscription<List<int>>? _keystrokeSubscription;

  // HID Service and Characteristic UUIDs
  static final Guid hidServiceUuid = Guid("1812"); // HID Service
  static final Guid reportCharacteristicUuid = Guid("2A4D"); // HID Report

  // Getters
  BluetoothDevice? get connectedDevice => _connectedDevice;
  KeyboardInputController get inputController => _inputController;

  /// Scan for BLE devices
  Future<void> scan({Duration timeout = const Duration(seconds: 4)}) async {
    await FlutterBluePlus.startScan(timeout: timeout);
  }

  /// Stop scanning
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  /// Listen to scan results
  Future<StreamSubscription<List<ScanResult>>> listenScannin() async {
    return FlutterBluePlus.scanResults.listen((results) async {
      print("Scan results: ${results.length} devices found");
    });
  }

  /// Connect to a device and discover HID services
  Future<bool> connectAndDiscoverHid(BluetoothDevice device) async {
    try {
      _connectedDevice = device;

      if (!device.isConnected) {
        await device.connect();
      }

      bool hidFound = await discoverServices(device);
      return hidFound;
    } catch (e) {
      print("Error connecting to device: $e");
      _connectedDevice = null;
      return false;
    }
  }

  /// Discover HID services and enable keyboard input
  Future<bool> discoverServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      bool hidServiceFound = false;

      for (var service in services) {
        print("Found service: ${service.uuid}");

        if (service.uuid == hidServiceUuid) {
          hidServiceFound = true;
          print("HID Service found!");

          for (var characteristic in service.characteristics) {
            print(
              "  Characteristic: ${characteristic.uuid}, Properties: ${characteristic.properties}",
            );

            // Look for HID Report characteristic with Notify property
            if (characteristic.uuid == reportCharacteristicUuid) {
              if (characteristic.properties.notify) {
                print("  Enabling notifications for HID Report...");
                await characteristic.setNotifyValue(true);

                // Cancel previous subscription if any
                await _keystrokeSubscription?.cancel();

                // Listen to the keystroke stream
                _keystrokeSubscription = characteristic.lastValueStream.listen(
                  (value) {
                    handleKeystroke(value);
                  },
                  onError: (error) {
                    print("Error in keystroke stream: $error");
                  },
                );

                print("  HID keyboard input enabled!");
              }
            }
          }
        }
      }

      return hidServiceFound;
    } catch (e) {
      print("Error discovering services: $e");
      return false;
    }
  }

  /// Disconnect from the current device
  Future<void> disconnect() async {
    await _keystrokeSubscription?.cancel();
    _keystrokeSubscription = null;

    if (_connectedDevice != null && _connectedDevice!.isConnected) {
      await _connectedDevice!.disconnect();
    }

    _connectedDevice = null;
  }

  /// Handle incoming HID keyboard report
  void handleKeystroke(List<int> data) {
    if (data.length < 8) {
      print("Invalid HID report length: ${data.length}");
      return;
    }

    // HID Keyboard Report Structure (8 bytes):
    // Byte 0: Modifier keys
    // Byte 1: Reserved
    // Byte 2-7: Up to 6 simultaneous key presses

    int modifierByte = data[0];
    List<String> modifiers = _parseModifiers(modifierByte);

    // Process key presses (bytes 2-7)
    for (int i = 2; i < 8; i++) {
      int keycode = data[i];

      if (keycode > 0) {
        String? key = _keycodeToString(keycode, modifiers.contains('Shift'));

        if (key != null) {
          // Create keystroke event
          KeystrokeEvent event = KeystrokeEvent(
            key: key,
            modifiers: modifiers,
            timestamp: DateTime.now(),
            rawData: data,
          );

          // Add to controller
          _inputController.addKeystroke(event);

          print("Keystroke: ${event.toString()}");
        }
      }
    }

    // Update modifier state even if no keys pressed
    if (data.sublist(2, 8).every((byte) => byte == 0)) {
      _inputController.updateModifiers(modifiers);
    }
  }

  /// Parse modifier byte into list of modifier key names
  List<String> _parseModifiers(int modifierByte) {
    List<String> modifiers = [];

    if (modifierByte & 0x01 != 0) modifiers.add('LCtrl');
    if (modifierByte & 0x02 != 0) modifiers.add('Shift');
    if (modifierByte & 0x04 != 0) modifiers.add('LAlt');
    if (modifierByte & 0x08 != 0) modifiers.add('LWin');
    if (modifierByte & 0x10 != 0) modifiers.add('RCtrl');
    if (modifierByte & 0x20 != 0) modifiers.add('RShift');
    if (modifierByte & 0x40 != 0) modifiers.add('RAlt');
    if (modifierByte & 0x80 != 0) modifiers.add('RWin');

    return modifiers;
  }

  /// Convert HID keycode to string representation
  String? _keycodeToString(int keycode, bool shiftPressed) {
    // Letters (a-z)
    if (keycode >= 0x04 && keycode <= 0x1D) {
      String letter = String.fromCharCode(0x61 + (keycode - 0x04)); // a-z
      return shiftPressed ? letter.toUpperCase() : letter;
    }

    // Numbers and special characters
    if (keycode >= 0x1E && keycode <= 0x27) {
      const numbers = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
      const shifted = ['!', '@', '#', '\$', '%', '^', '&', '*', '(', ')'];
      int index = keycode - 0x1E;
      return shiftPressed ? shifted[index] : numbers[index];
    }

    // Special keys and symbols
    const Map<int, List<String>> specialKeys = {
      0x28: ['Enter', 'Enter'],
      0x29: ['Escape', 'Escape'],
      0x2A: ['Backspace', 'Backspace'],
      0x2B: ['Tab', 'Tab'],
      0x2C: ['Space', 'Space'],
      0x2D: ['-', '_'],
      0x2E: ['=', '+'],
      0x2F: ['[', '{'],
      0x30: [']', '}'],
      0x31: ['\\', '|'],
      0x33: [';', ':'],
      0x34: ['\'', '"'],
      0x35: ['`', '~'],
      0x36: [',', '<'],
      0x37: ['.', '>'],
      0x38: ['/', '?'],
      0x39: ['CapsLock', 'CapsLock'],
    };

    if (specialKeys.containsKey(keycode)) {
      return shiftPressed ? specialKeys[keycode]![1] : specialKeys[keycode]![0];
    }

    // Function keys (F1-F12)
    if (keycode >= 0x3A && keycode <= 0x45) {
      return 'F${keycode - 0x39}';
    }

    // System keys
    const Map<int, String> systemKeys = {
      0x46: 'PrintScreen',
      0x47: 'ScrollLock',
      0x48: 'Pause',
      0x49: 'Insert',
      0x4A: 'Home',
      0x4B: 'PageUp',
      0x4C: 'Delete',
      0x4D: 'End',
      0x4E: 'PageDown',
      0x4F: 'RightArrow',
      0x50: 'LeftArrow',
      0x51: 'DownArrow',
      0x52: 'UpArrow',
    };

    if (systemKeys.containsKey(keycode)) {
      return systemKeys[keycode];
    }

    // Keypad keys
    if (keycode >= 0x53 && keycode <= 0x63) {
      const Map<int, String> keypadKeys = {
        0x53: 'NumLock',
        0x54: 'KP/',
        0x55: 'KP*',
        0x56: 'KP-',
        0x57: 'KP+',
        0x58: 'KPEnter',
        0x59: 'KP1',
        0x5A: 'KP2',
        0x5B: 'KP3',
        0x5C: 'KP4',
        0x5D: 'KP5',
        0x5E: 'KP6',
        0x5F: 'KP7',
        0x60: 'KP8',
        0x61: 'KP9',
        0x62: 'KP0',
        0x63: 'KP.',
      };
      return keypadKeys[keycode];
    }

    // Application and menu keys
    const Map<int, String> applicationKeys = {
      0x65: 'Application',
      0x68: 'F13',
      0x69: 'F14',
      0x6A: 'F15',
      0x6B: 'F16',
      0x6C: 'F17',
      0x6D: 'F18',
      0x6E: 'F19',
      0x6F: 'F20',
      0x70: 'F21',
      0x71: 'F22',
      0x72: 'F23',
      0x73: 'F24',
    };

    if (applicationKeys.containsKey(keycode)) {
      return applicationKeys[keycode];
    }

    // Unknown keycode
    return 'Unknown(0x${keycode.toRadixString(16)})';
  }
}
