import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../domain/models/ble_device.dart';
import '../../domain/models/ble_service.dart';
import '../../domain/models/ble_characteristic.dart';
import '../../domain/repository/ble_repository.dart';

class BleViewModel extends ChangeNotifier {
  final BleRepository _repository;

  List<BleDevice> _scanResults = [];
  List<BleDevice> get scanResults => _scanResults;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  BleDevice? _connectedDevice;
  BleDevice? get connectedDevice => _connectedDevice;

  List<BleService> _services = [];
  List<BleService> get services => _services;

  StreamSubscription? _scanSubscription;
  StreamSubscription? _isScanningSubscription;

  BleViewModel(this._repository) {
    _isScanningSubscription = _repository.isScanning.listen((scanning) {
      _isScanning = scanning;
      notifyListeners();
    });

    _scanSubscription = _repository.scanResults.listen((results) {
      _scanResults = results;
      notifyListeners();
    });
  }

  Future<void> startScan() async {
    _scanResults.clear();
    notifyListeners();
    try {
      await _repository.startScan();
    } catch (e) {
      if (kDebugMode) {
        print("Error starting scan: $e");
      }
    }
  }

  Future<void> stopScan() async {
    await _repository.stopScan();
  }

  Future<void> connect(BleDevice device) async {
    try {
      await _repository.connect(device);
      _connectedDevice = device;
      notifyListeners();

      if (kDebugMode) {
        print("✅ Connected to ${device.name}");
      }

      // Give user option to discover services manually
      // This ensures connection is stable before discovery
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error connecting: $e");
      }
      _connectedDevice = null;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _repository.disconnect(_connectedDevice!);
      _connectedDevice = null;
      _services = [];
      notifyListeners();
    }
  }

  Future<void> discoverServices(BleDevice device) async {
    try {
      if (_connectedDevice?.id != device.id) {
        throw Exception('Device not connected. Please connect first.');
      }

      if (kDebugMode) {
        print("🔍 Discovering services for ${device.name}...");
      }

      _services = await _repository.discoverServices(device);

      if (kDebugMode) {
        print("✅ Found ${_services.length} services");
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error discovering services: $e");
      }
      rethrow;
    }
  }

  Future<List<int>> readCharacteristic(BleCharacteristic characteristic) async {
    try {
      final value = await _repository.readCharacteristic(characteristic);
      // Update the characteristic value in the UI
      _updateCharacteristicValue(characteristic, value);
      return value;
    } catch (e) {
      if (kDebugMode) {
        print("Error reading characteristic: $e");
      }
      rethrow;
    }
  }

  Future<void> writeCharacteristic(BleCharacteristic characteristic, List<int> value) async {
    try {
      await _repository.writeCharacteristic(characteristic, value);
    } catch (e) {
      if (kDebugMode) {
        print("Error writing characteristic: $e");
      }
      rethrow;
    }
  }

  Stream<List<int>> subscribeToCharacteristic(BleCharacteristic characteristic) {
    return _repository.subscribeToCharacteristic(characteristic);
  }

  /// Updates a characteristic value in the services list from a notification
  void updateCharacteristicValue(BleCharacteristic characteristic, List<int> newValue) {
    _updateCharacteristicValue(characteristic, newValue);
  }

  /// Updates a characteristic value in the services list and notifies listeners
  void _updateCharacteristicValue(BleCharacteristic characteristic, List<int> newValue) {
    // Find the service and characteristic in our list and update it
    for (int i = 0; i < _services.length; i++) {
      final service = _services[i];
      final charIndex = service.characteristics.indexWhere(
        (c) => c.uuid == characteristic.uuid && c.serviceUuid == characteristic.serviceUuid,
      );

      if (charIndex != -1) {
        // Update the characteristic with the new value
        final updatedChar = service.characteristics[charIndex].copyWith(value: newValue);
        final updatedChars = List<BleCharacteristic>.from(service.characteristics);
        updatedChars[charIndex] = updatedChar;

        _services[i] = BleService(
          uuid: service.uuid,
          deviceId: service.deviceId,
          characteristics: updatedChars,
          nativeService: service.nativeService,
        );

        notifyListeners();
        break;
      }
    }
  }

  //Validator brand and model
  bool validateDeviceName() {
    final isBrandServiceUuid = "5261a470-7465-4e48-b56f-726170100000";
    final hasBrandService = _services.any((service) => service.uuid == isBrandServiceUuid);

    if (hasBrandService) {
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _isScanningSubscription?.cancel();
    super.dispose();
  }
}
