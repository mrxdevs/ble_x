/// Helper class for making UUIDs human-readable
class UuidHelper {
  /// Known UUID names (add your custom UUIDs here)
  static final Map<String, String> _knownUuids = {
    // Your MacBook HMI UUIDs
    'bf27cfb9-87f5-4e0d-be1d-a01196e55b55': 'MacBook HMI Service',
    'bf27cfb9-87f5-4e0d-be1d-a01196e55b56': 'Music Title',

    // Standard Bluetooth SIG UUIDs
    '00001800-0000-1000-8000-00805f9b34fb': 'Generic Access',
    '00001801-0000-1000-8000-00805f9b34fb': 'Generic Attribute',
    '0000180a-0000-1000-8000-00805f9b34fb': 'Device Information',
    '0000180f-0000-1000-8000-00805f9b34fb': 'Battery Service',

    // Standard Characteristics
    '00002a00-0000-1000-8000-00805f9b34fb': 'Device Name',
    '00002a01-0000-1000-8000-00805f9b34fb': 'Appearance',
    '00002a19-0000-1000-8000-00805f9b34fb': 'Battery Level',
    '00002a29-0000-1000-8000-00805f9b34fb': 'Manufacturer Name',
    '00002a24-0000-1000-8000-00805f9b34fb': 'Model Number',
  };

  /// Get human-readable name for a UUID
  static String getName(String uuid) {
    final lowerUuid = uuid.toLowerCase();
    return _knownUuids[lowerUuid] ?? 'Unknown';
  }

  /// Check if UUID has a known name
  static bool hasKnownName(String uuid) {
    return _knownUuids.containsKey(uuid.toLowerCase());
  }

  /// Get short UUID (first 8 characters)
  static String getShortUuid(String uuid) {
    if (uuid.length >= 8) {
      return uuid.substring(0, 8).toUpperCase();
    }
    return uuid.toUpperCase();
  }

  /// Get formatted display with name if available
  static String getDisplayName(String uuid) {
    final name = getName(uuid);
    if (name != 'Unknown') {
      return name;
    }
    return getShortUuid(uuid);
  }

  /// Get full display with both name and UUID
  static String getFullDisplay(String uuid) {
    final name = getName(uuid);
    if (name != 'Unknown') {
      return '$name\n${getShortUuid(uuid)}';
    }
    return uuid;
  }
}
