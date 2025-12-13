import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleHidService {
  // 1. Scan for the Linux Keyboard

  Future<void> scan() async {
    final subscription = await FlutterBluePlus.startScan(
      // withServices: [Guid("2222")], // Filter for HID devices
      timeout: Duration(seconds: 4),
    );
  }

  // 2. Connect to the device found

  Future<StreamSubscription<List<ScanResult>>> listenScannin() async {
    return FlutterBluePlus.scanResults.listen((results) async {
      print(results);
      for (ScanResult r in results) {
        if (r.device.platformName == "MyLinuxKeyboard") {
          // Name set in Linux script
          await r.device.connect();
          await discoverServices(r.device);
        }
      }
    });
  }

  // 3. Discover services
  Future<void> discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();

    for (var service in services) {
      if (service.uuid == Guid("1812")) {
        // HID Service
        for (var characteristic in service.characteristics) {
          // We are looking for the Report Characteristic
          // Note: Sometimes there are multiple reports. You usually want the one with 'Notify' property.
          if (characteristic.uuid == Guid("2A4D")) {
            // Enable Notifications
            await characteristic.setNotifyValue(true);

            // Listen to the stream
            characteristic.lastValueStream.listen((value) {
              // 'value' is List<int> (the 8 bytes)
              handleKeystroke(value);
            });
          }
        }
      }
    }
  }

  // 4. Handle keystrokes
  void handleKeystroke(List<int> data) {
    if (data.length < 3) return;

    int modifier = data[0];
    int keycode = data[2];

    // Simple mapping example (You need a full lookup table for a real app)
    const keyMap = {
      4: 'a', 5: 'b', 6: 'c', 7: 'd', // ... etc
      40: 'Enter', 44: 'Space',
    };

    if (keycode > 0) {
      String? char = keyMap[keycode];
      print("Received Key: $char");
      // Now trigger your app logic with this input
    }
  }
}
