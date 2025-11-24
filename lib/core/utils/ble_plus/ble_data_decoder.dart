import 'dart:convert';

/// Utility class for decoding BLE characteristic data
class BleDataDecoder {
  /// Converts a list of bytes to a UTF-8 string
  /// Returns null if the data is not valid UTF-8
  static String? tryDecodeUtf8(List<int> bytes) {
    if (bytes.isEmpty) return null;

    try {
      final decoded = utf8.decode(bytes, allowMalformed: false);
      // Check if the decoded string contains only printable characters
      // This helps filter out binary data that happens to be valid UTF-8
      if (_isPrintable(decoded)) {
        return decoded;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Converts a list of bytes to a hexadecimal string
  /// Format: "0x01 0x02 0x03"
  static String toHexString(List<int> bytes) {
    if (bytes.isEmpty) return '(empty)';
    return bytes.map((b) => '0x${b.toRadixString(16).padLeft(2, '0').toUpperCase()}').join(' ');
  }

  /// Smart decoder: attempts UTF-8 first, falls back to hex
  static String decode(List<int> bytes) {
    if (bytes.isEmpty) return '(empty)';

    final utf8String = tryDecodeUtf8(bytes);
    if (utf8String != null) {
      return utf8String;
    }

    return toHexString(bytes);
  }

  /// Checks if a string contains only printable ASCII and common Unicode characters
  static bool _isPrintable(String str) {
    if (str.isEmpty) return false;

    for (int i = 0; i < str.length; i++) {
      final code = str.codeUnitAt(i);
      // Allow printable ASCII (32-126), tabs (9), newlines (10, 13)
      // and common Unicode characters (128+)
      if (code < 9 || (code > 13 && code < 32) || code == 127) {
        return false;
      }
    }
    return true;
  }

  /// Converts a string to bytes for writing to a characteristic
  static List<int> stringToBytes(String str) {
    return utf8.encode(str);
  }

  /// Converts a hex string (e.g., "0x01, 0x02" or "01 02") to bytes
  static List<int>? hexStringToBytes(String hexStr) {
    try {
      // Remove common separators and 0x prefix
      final cleaned = hexStr
          .replaceAll('0x', '')
          .replaceAll(',', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (cleaned.isEmpty) return null;

      final parts = cleaned.split(' ');
      return parts.map((part) => int.parse(part, radix: 16)).toList();
    } catch (e) {
      return null;
    }
  }
}
