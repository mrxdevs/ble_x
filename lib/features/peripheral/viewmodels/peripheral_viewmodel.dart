import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

class PeripheralViewModel extends ChangeNotifier {
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();

  bool _isAdvertising = false;
  bool get isAdvertising => _isAdvertising;

  String _advertisingUuid = 'bf27cfb9-87f5-4e0d-be1d-a01196e55b55'; // Default UUID
  String get advertisingUuid => _advertisingUuid;

  String _characteristicValue = 'Hello Linux';
  String get characteristicValue => _characteristicValue;

  PeripheralViewModel() {
    _init();
  }

  void _init() {
    _blePeripheral.onPeripheralStateChanged?.listen((state) {
      _isAdvertising = state == PeripheralState.advertising;
      notifyListeners();
    });
  }

  Future<void> startAdvertising() async {
    if (_isAdvertising) return;

    // These data is from offiacial repo

    final AdvertiseData _advertiseData = AdvertiseData(
      serviceUuid: _advertisingUuid,
      serviceUuids: ['ffffffff-ffff-ffff-ffff-ffffffffffff'],
      localName: 'test',
      includeDeviceName: true,
      manufacturerId: 1234,
      manufacturerData: Uint8List.fromList([1, 2, 3, 4, 5, 6, 7]),
    );

    // final AdvertiseSetParameters advertiseSetParameters = AdvertiseSetParameters(connectable: true);

    final AdvertiseSettings advertiseSettings = AdvertiseSettings(
      advertiseMode: AdvertiseMode.advertiseModeLowLatency,
      txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
      advertiseSet: true,
      connectable: true,
      timeout: 170000,
    );

    try {
      await _blePeripheral.start(
        // advertiseData: advertiseData,
        advertiseData: _advertiseData,

        advertiseSettings: advertiseSettings,
        // advertiseSetParameters: advertiseSetParameters,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error starting advertising: $e');
      }
    }
  }

  Future<void> stopAdvertising() async {
    if (!_isAdvertising) return;
    try {
      await _blePeripheral.stop();
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping advertising: $e');
      }
    }
  }

  Future<void> updateCharacteristicValue(String value) async {
    _characteristicValue = value;
    notifyListeners();
    // Note: flutter_ble_peripheral 2.0.0 primarily supports advertising.
    // Dynamic characteristic updates for GATT server might require additional handling
    // or a different package if this one doesn't support full GATT server operations.
    // For now, we focus on the advertising part.
  }

  @override
  void dispose() {
    stopAdvertising();
    super.dispose();
  }
}
