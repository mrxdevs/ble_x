import 'dart:async';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../domain/models/ble_device.dart';
import '../../domain/models/ble_service.dart';
import '../../domain/models/ble_characteristic.dart';
import '../../domain/repository/ble_repository.dart';

class FlutterBluePlusRepository implements BleRepository {
  // Singleton instance
  static final FlutterBluePlusRepository _instance = FlutterBluePlusRepository._internal();
  factory FlutterBluePlusRepository() => _instance;
  FlutterBluePlusRepository._internal();

  @override
  Stream<List<BleDevice>> get scanResults {
    return FlutterBluePlus.scanResults.map((results) {
      return results.map((r) {
        return BleDevice(
          id: r.device.remoteId.str,
          name: r.device.platformName.isNotEmpty
              ? r.device.platformName
              : r.advertisementData.advName,
          rssi: r.rssi,
          isConnectable: r.advertisementData.connectable,
          timeStamp: r.timeStamp,
          txPowerLevel: r.advertisementData.txPowerLevel,
          appearance: r.advertisementData.appearance,
          manufacturerData: r.advertisementData.manufacturerData,
          serviceData: r.advertisementData.serviceData.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
          serviceUuids: r.advertisementData.serviceUuids.map((e) => e.toString()).toList(),
          nativeDevice: r.device,
        );
      }).toList();
    });
  }

  // ScanResult scanResult;
  // ScanResult get scanResult => scanResult;

  /*

   final BluetoothDevice device;
  final AdvertisementData advertisementData;
  final int rssi;
  final DateTime timeStamp;

    final String advName;
  final int? txPowerLevel;
  final int? appearance; // not supported on iOS / macOS
  final bool connectable;
  final Map<int, List<int>> manufacturerData; // key: manufacturerId
  final Map<Guid, List<int>> serviceData; // key: service guid
  final List<Guid> serviceUuids;


  */

  @override
  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  @override
  Stream<int> get adapterState => FlutterBluePlus.adapterState.map((s) => s.index);

  @override
  Future<void> startScan() async {
    // Check for permissions if needed, but usually handled by the app before calling this
    // or by the library.
    // On Android, we might need to turn on Bluetooth
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  @override
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  @override
  Future<void> connect(BleDevice device) async {
    final nativeDevice = device.nativeDevice as BluetoothDevice;

    // Connect and wait for connection state
    await nativeDevice.connect(timeout: const Duration(seconds: 15));

    // Wait a bit for connection to stabilize
    await Future.delayed(const Duration(milliseconds: 500));

    // Verify we're actually connected
    final connectionState = await nativeDevice.connectionState.first;
    if (connectionState != BluetoothConnectionState.connected) {
      throw Exception('Failed to establish connection');
    }
  }

  @override
  Future<void> disconnect(BleDevice device) async {
    final nativeDevice = device.nativeDevice as BluetoothDevice;
    await nativeDevice.disconnect();
  }

  @override
  Future<List<BleService>> discoverServices(BleDevice device) async {
    final nativeDevice = device.nativeDevice as BluetoothDevice;
    final services = await nativeDevice.discoverServices();
    return services.map((s) {
      return BleService(
        uuid: s.uuid.str,
        deviceId: s.deviceId.str,
        characteristics: s.characteristics.map((c) {
          return BleCharacteristic(
            uuid: c.uuid.str,
            serviceUuid: c.serviceUuid.str,
            deviceId: c.deviceId.str,
            isReadable: c.properties.read,
            isWritable: c.properties.write || c.properties.writeWithoutResponse,
            isNotifiable: c.properties.notify || c.properties.indicate,
            value: c.lastValue,
            nativeCharacteristic: c,
          );
        }).toList(),
        nativeService: s,
      );
    }).toList();
  }

  @override
  Future<List<int>> readCharacteristic(BleCharacteristic characteristic) async {
    final nativeChar = characteristic.nativeCharacteristic as BluetoothCharacteristic;
    return await nativeChar.read();
  }

  @override
  Future<void> writeCharacteristic(BleCharacteristic characteristic, List<int> value) async {
    final nativeChar = characteristic.nativeCharacteristic as BluetoothCharacteristic;

    // Determine write type based on properties
    // If writeWithoutResponse is true, we can use withoutResponse: true
    // If write is true, we should use withoutResponse: false (default)

    bool withoutResponse = false;
    if (characteristic.isWritable) {
      // Check specific properties if available in our model, or infer
      // For now, we'll default to withResponse (false) if 'write' property is true
      // If only 'writeWithoutResponse' is true, then we set it to true.
      final props = nativeChar.properties;
      if (props.writeWithoutResponse && !props.write) {
        withoutResponse = true;
      }
    }

    await nativeChar.write(value, withoutResponse: withoutResponse);
  }

  @override
  Stream<List<int>> subscribeToCharacteristic(BleCharacteristic characteristic) {
    final nativeChar = characteristic.nativeCharacteristic as BluetoothCharacteristic;
    nativeChar.setNotifyValue(true);
    return nativeChar.onValueReceived;
  }

  @override
  Future<bool> get isBluetoothOn async {
    final state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }
}
