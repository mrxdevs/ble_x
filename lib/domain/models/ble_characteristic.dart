class BleCharacteristic {
  final String uuid;
  final String serviceUuid;
  final String deviceId;
  final bool isReadable;
  final bool isWritable;
  final bool isNotifiable;
  final List<int> value;
  final Object? nativeCharacteristic;

  BleCharacteristic({
    required this.uuid,
    required this.serviceUuid,
    required this.deviceId,
    required this.isReadable,
    required this.isWritable,
    required this.isNotifiable,
    required this.value,
    this.nativeCharacteristic,
  });

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
    );
  }
}
