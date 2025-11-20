import 'dart:async';

import '../models/ble_device.dart';
import '../models/ble_service.dart';
import '../models/ble_characteristic.dart';

abstract class BleRepository {
  /// Stream of scan results
  Stream<List<BleDevice>> get scanResults;

  /// Stream of the current scanning state
  Stream<bool> get isScanning;

  /// Start scanning for devices
  Future<void> startScan();

  /// Stop scanning
  Future<void> stopScan();

  /// Connect to a device
  Future<void> connect(BleDevice device);

  /// Disconnect from a device
  Future<void> disconnect(BleDevice device);

  /// Discover services for a device
  Future<List<BleService>> discoverServices(BleDevice device);

  /// Read characteristic value
  Future<List<int>> readCharacteristic(BleCharacteristic characteristic);

  /// Write characteristic value
  Future<void> writeCharacteristic(BleCharacteristic characteristic, List<int> value);

  /// Subscribe to characteristic notifications
  Stream<List<int>> subscribeToCharacteristic(BleCharacteristic characteristic);

  /// Check if bluetooth is supported and on
  Future<bool> get isBluetoothOn;

  Stream<int> get adapterState;
}
