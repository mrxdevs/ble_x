import 'ble_characteristic.dart';

class BleService {
  final String uuid;
  final String deviceId;
  final List<BleCharacteristic> characteristics;
  final Object? nativeService;

  BleService({
    required this.uuid,
    required this.deviceId,
    required this.characteristics,
    this.nativeService,
  });
}
