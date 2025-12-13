import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;

class BlePrefService {
  static final BlePrefService instance = BlePrefService._();

  BlePrefService._();
  late SharedPreferences _prefs;

  _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveConnectedDevice(String remoteId) async {
    await _init();
    await _prefs.setString('last_connected_device_id', remoteId);
    print("Saved device ID: $remoteId");
  }

  // 2. Clear the Device ID on disconnect (Optional, if you want them to manually connect next time)
  Future<void> clearConnectedDevice() async {
    await _init();
    await _prefs.remove('last_connected_device_id');
  }

  // 3. The Auto-Connect Logic
  Future<void> tryAutoConnect(
    BluetoothDevice device,
    Function(BluetoothDevice device) onConnect,
  ) async {
    await _init();
    final String? savedId = _prefs.getString('last_connected_device_id');

    // Check if we have a saved ID and if it matches the current widget's device
    // (In a real app, you might create the device object from the string ID directly)
    if (savedId == device.remoteId.toString()) {
      onConnect(device);
    }
  }

  //4. Get last connected device id
  String get lastConnectedDeviceId => _prefs.getString('last_connected_device_id') ?? '';
}
