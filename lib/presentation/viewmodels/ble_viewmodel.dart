import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../domain/models/ble_device.dart';
import '../../domain/repository/ble_repository.dart';

class BleViewModel extends ChangeNotifier {
  final BleRepository _repository;

  List<BleDevice> _scanResults = [];
  List<BleDevice> get scanResults => _scanResults;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  BleDevice? _connectedDevice;
  BleDevice? get connectedDevice => _connectedDevice;

  List<Object> _services = [];
  List<Object> get services => _services;

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

      // Discover services after connection
      await discoverServices(device);
    } catch (e) {
      if (kDebugMode) {
        print("Error connecting: $e");
      }
      _connectedDevice = null;
      notifyListeners();
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
      _services = await _repository.discoverServices(device);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("Error discovering services: $e");
      }
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _isScanningSubscription?.cancel();
    super.dispose();
  }
}
