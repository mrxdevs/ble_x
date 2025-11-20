class BleDevice {
  final String id;
  final String name;
  final int rssi;
  final bool isConnectable;
  final DateTime? timeStamp;
  final int? txPowerLevel;
  final int? appearance;
  final Map<int, List<int>>? manufacturerData;
  final Map<String, List<int>>? serviceData; // Using String for UUID to keep it generic
  final List<String>? serviceUuids;

  // We can add more fields as needed, or wrap the native device object if necessary
  // but keeping it generic is better for abstraction.
  final Object? nativeDevice; // To hold the actual library-specific device object

  BleDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.isConnectable,
    this.timeStamp,
    this.txPowerLevel,
    this.appearance,
    this.manufacturerData,
    this.serviceData,
    this.serviceUuids,
    this.nativeDevice,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleDevice && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BleDevice{id: $id, name: $name, rssi: $rssi, connectable: $isConnectable}';
  }
}
