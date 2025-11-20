import 'dart:async';

import '../models/ble_device.dart';

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
  Future<List<Object>> discoverServices(BleDevice device); // Using Object for now, will refine

  /// Check if bluetooth is supported and on
  Future<bool> get isBluetoothOn;

  Stream<int> get adapterState;
}
