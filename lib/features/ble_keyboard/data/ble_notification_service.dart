import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart'; // Import this specifically
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Configuration Constants ---
const String notificationChannelId = 'ble_background_channel';
const int notificationId = 888;

Future<void> initializeBleNotificationService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    'BLE Connection Service',
    description: 'Keeps connection to HMI alive',
    importance: Importance.low, // Changed to low for better stability
    playSound: false,
    enableVibration: false,
    showBadge: false,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isAndroid) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'BLE Service Active',
      initialNotificationContent: 'Monitoring connection...',
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // 1. IMMEDIATE FOREGROUND PROMOTION (Fixes the "DidNotStartInTime" crash)
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });

    // Force it to foreground immediately to satisfy Android requirements
    service.setAsForegroundService();
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  print("Background Service: Started BLE Monitoring");

  // 2. Wait for Bluetooth Adapter
  if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.off) {
    print("Background Service: Bluetooth is OFF");
  }

  // 3. Start Monitoring Loop
  Timer.periodic(const Duration(seconds: 15), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // Check if connected. If list is empty, we are disconnected.
        if (FlutterBluePlus.connectedDevices.isEmpty) {
          await _attemptReconnection();
        } else {
          print("Background Service: Device is already connected.");
        }
      }
    }
  });
}

Future<void> _attemptReconnection() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final lastDeviceId = prefs.getString('last_connected_device_id');

    if (lastDeviceId != null && lastDeviceId.isNotEmpty) {
      print("Background Service: Attempting to reconnect to $lastDeviceId");

      final device = BluetoothDevice.fromId(lastDeviceId);

      // --- CRITICAL FIX HERE ---
      // 1. Remove 'mtu'.
      // 2. Remove 'timeout' (incompatible with autoConnect usually).
      // 3. Keep 'autoConnect: true'.
      await device.connect(autoConnect: true);

      // Wait for connection to actually happen before moving on
      await device.connectionState.where((s) => s == BluetoothConnectionState.connected).first;

      print("Background Service: Reconnection Successful!");

      // OPTIONAL: Now that we are connected, you can request MTU (Android only)
      if (Platform.isAndroid) {
        try {
          await device.requestMtu(512);
        } catch (e) {
          print("MTU Request failed (not critical): $e");
        }
      }
    } else {
      print("Background Service: No saved device ID.");
    }
  } catch (e) {
    print("Background Service: Reconnection Logic Error: $e");
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}
