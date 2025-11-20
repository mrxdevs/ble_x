import 'dart:async';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../domain/models/ble_device.dart';
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
    await nativeDevice.connect();
  }

  @override
  Future<void> disconnect(BleDevice device) async {
    final nativeDevice = device.nativeDevice as BluetoothDevice;
    await nativeDevice.disconnect();
  }

  @override
  Future<List<Object>> discoverServices(BleDevice device) async {
    final nativeDevice = device.nativeDevice as BluetoothDevice;
    return await nativeDevice.discoverServices();
  }

  @override
  Future<bool> get isBluetoothOn async {
    final state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }
}
