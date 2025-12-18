import 'package:ble_x/features/ble_keyboard/data/ble_hid_service.dart';
import 'package:ble_x/features/ble_keyboard/data/ble_pref_service.dart';
import 'package:ble_x/features/ble_keyboard/presentation/ble_device_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleAsKeyboardScreen extends StatefulWidget {
  const BleAsKeyboardScreen({super.key});

  @override
  State<BleAsKeyboardScreen> createState() => _BleAsKeyboardScreenState();
}

class _BleAsKeyboardScreenState extends State<BleAsKeyboardScreen> {
  //BleHidService Initialization
  final BleHidService _bleHidService = BleHidService();
  List<ScanResult> _scannedList = [];

  // Current keystroke display
  String _currentKeystroke = '';
  List<String> _currentModifiers = [];

  //Check if bluetooth is enabled
  _checkBluetooth() async {
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      await FlutterBluePlus.turnOn();
    }
  }

  _scan() async {
    await _bleHidService.scan();
    final _scannedDevices = await _bleHidService.listenScannin();
    _scannedDevices.onData((scannedList) {
      _scannedList = scannedList;

      if (mounted) setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();

    // Listen to keystroke events
    _bleHidService.inputController.keystrokeStream.listen((event) {
      if (mounted) {
        setState(() {
          _currentKeystroke = event.toString();
        });
      }
    });

    // Listen to modifier state changes
    _bleHidService.inputController.modifierStateStream.listen((modifiers) {
      if (mounted) {
        setState(() {
          _currentModifiers = modifiers;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBluetooth();
      _scan();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectedDevice = _bleHidService.connectedDevice;
    final keystrokeHistory = _bleHidService.inputController.history;

    return Scaffold(
      appBar: AppBar(
        title: Text('BLE HID Keyboard Receiver'),
        actions: [
          if (keystrokeHistory.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear_all),
              tooltip: 'Clear History',
              onPressed: () {
                setState(() {
                  _bleHidService.inputController.clearHistory();
                  _currentKeystroke = '';
                });
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _scan(),
        child: Icon(Icons.search_outlined),
      ),
      body: Column(
        children: [
          // Connection Status Card
          if (connectedDevice != null)
            Card(
              margin: EdgeInsets.all(8.0),
              color: Colors.green[50],
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.keyboard, color: Colors.green, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connected to HID Keyboard',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green[800],
                            ),
                          ),
                          Text(
                            connectedDevice.platformName.isEmpty
                                ? connectedDevice.remoteId.str
                                : connectedDevice.platformName,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () async {
                        await _bleHidService.disconnect();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Current Keystroke Display
          if (connectedDevice != null)
            Card(
              margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Current Keystroke',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Text(
                        _currentKeystroke.isEmpty ? 'Waiting for input...' : _currentKeystroke,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _currentKeystroke.isEmpty ? Colors.grey : Colors.blue[900],
                        ),
                      ),
                    ),
                    if (_currentModifiers.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: _currentModifiers
                            .map(
                              (mod) => Chip(
                                label: Text(mod, style: TextStyle(fontSize: 12)),
                                backgroundColor: Colors.orange[100],
                                padding: EdgeInsets.all(2),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Keystroke History
          if (connectedDevice != null && keystrokeHistory.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(Icons.history, size: 20, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    'Keystroke History (${keystrokeHistory.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),

          // History List or Device List
          Expanded(
            child: connectedDevice != null && keystrokeHistory.isNotEmpty
                ? ListView.builder(
                    itemCount: keystrokeHistory.length,
                    itemBuilder: (context, index) {
                      final event = keystrokeHistory[index];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue[100],
                          child: Text(
                            '${keystrokeHistory.length - index}',
                            style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                          ),
                        ),
                        title: Text(
                          event.toString(),
                          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        ),
                        subtitle: Text(
                          '${event.timestamp.hour.toString().padLeft(2, '0')}:'
                          '${event.timestamp.minute.toString().padLeft(2, '0')}:'
                          '${event.timestamp.second.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                        trailing: Text(
                          'Raw: ${event.rawData.sublist(0, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.blueGrey[50],
                    child: ListView.builder(
                      itemCount: _scannedList.length,
                      itemBuilder: (context, index) {
                        final scanResult = _scannedList[index];
                        final device = scanResult.device;
                        final advertisementData = scanResult.advertisementData;

                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ExpansionTile(
                            leading: Icon(Icons.bluetooth, color: Colors.blueAccent),
                            title: Text(
                              device.advName.isEmpty ? device.platformName : device.advName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blueGrey[800],
                              ),
                            ),
                            subtitle: Text(
                              'RSSI: ${scanResult.rssi} dBm',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: TextButton(
                              onPressed: () async {
                                try {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Connecting to ${device.advName}...')),
                                  );

                                  bool success = await _bleHidService.connectAndDiscoverHid(device);

                                  if (success) {
                                    BlePrefService.instance.saveConnectedDevice(
                                      device.remoteId.str,
                                    );
                                    setState(() {});

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('HID keyboard connected! Start typing...'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('No HID service found on this device'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
                                }
                              },
                              child: Text(
                                device.isConnected ? 'CONNECTED' : 'CONNECT',
                                style: TextStyle(
                                  color: device.isConnected ? Colors.green : Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow('Device ID', device.remoteId.toString()),
                                    _buildInfoRow('Platform Name', device.platformName),
                                    _buildInfoRow(
                                      'Connection Status',
                                      device.isConnected ? "Connected" : "Disconnected",
                                      valueColor: device.isConnected ? Colors.green : Colors.red,
                                    ),
                                    _buildInfoRow(
                                      'Service UUIDs',
                                      advertisementData.serviceUuids.isNotEmpty
                                          ? advertisementData.serviceUuids
                                                .map((uuid) => uuid.str)
                                                .join(', ')
                                          : 'None',
                                    ),
                                    SizedBox(height: 10),
                                    if (device.isConnected)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () async {
                                              await _bleHidService.disconnect();
                                              setState(() {});
                                            },
                                            child: Text(
                                              "Disconnect",
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      DeviceDetailsPage(device: device),
                                                ),
                                              );
                                            },
                                            child: Icon(Icons.arrow_forward_ios),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey[700]),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor ?? Colors.blueGrey[900]),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
