import 'dart:math';

class BleUtils {
  /// Calculates the estimated distance in meters from Tx Power and RSSI values.
  ///
  /// [txPower]: The manufacturer-reported RSSI value at 1 meter distance (e.g., -7 dBm).
  /// [rssi]: The current measured RSSI value in dBm (a fluctuating negative number).
  /// [environmentFactor]: The path-loss exponent (n).
  ///   Use 2.0 for open space, 3.0-4.0 for indoor environments.
  static double calculateDistance(int txPower, int rssi, {double environmentFactor = 3.0}) {
    if (rssi == 0) {
      return -1.0; // Handle the case where RSSI is invalid or unavailable
    }

    // The formula is d = 10 ^ ((TxPowerAt1m - RSSI) / (10 * n))

    double txPowerAt1m = txPower.toDouble();

    // Heuristic:
    // If txPower is "strong" (>= -20 dBm), it's likely the conducted transmit power.
    // We need to subtract path loss at 1m (approx 41 dB for 2.4GHz) to get RSSI @ 1m.
    // If txPower is "weak" (< -20 dBm), it's likely already the measured RSSI at 1m (e.g. iBeacon style).
    if (txPower >= -20) {
      txPowerAt1m = txPower - 41.0;
    }

    double distance = pow(10.0, (txPowerAt1m - rssi) / (10 * environmentFactor)).toDouble();

    return distance;
  }
}
