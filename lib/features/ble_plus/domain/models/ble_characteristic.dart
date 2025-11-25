import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../../core/utils/ble_plus/ble_data_decoder.dart';

class BleCharacteristic {
  final String uuid;
  final String serviceUuid;
  final String deviceId;
  final bool isReadable;
  final bool isWritable;
  final bool isNotifiable;
  final List<int> value;
  final Object? nativeCharacteristic;
  final BluetoothCharacteristic? bleCharacteristic;

  BleCharacteristic({
    required this.uuid,
    required this.serviceUuid,
    required this.deviceId,
    required this.isReadable,
    required this.isWritable,
    required this.isNotifiable,
    required this.value,
    this.nativeCharacteristic,
    this.bleCharacteristic,
  });

  /// Returns the value decoded as a string (UTF-8 if valid, otherwise hex)
  String get valueAsString => BleDataDecoder.decode(value);

  /// Returns the value as a hex string
  String get valueAsHex => BleDataDecoder.toHexString(value);

  /// Returns the value as UTF-8 string, or null if not valid UTF-8
  String? get valueAsUtf8 => BleDataDecoder.tryDecodeUtf8(value);

  BleCharacteristic copyWith({List<int>? value}) {
    return BleCharacteristic(
      uuid: uuid,
      serviceUuid: serviceUuid,
      deviceId: deviceId,
      isReadable: isReadable,
      isWritable: isWritable,
      isNotifiable: isNotifiable,
      value: value ?? this.value,
      nativeCharacteristic: nativeCharacteristic,
      bleCharacteristic: bleCharacteristic,
    );
  }
}
