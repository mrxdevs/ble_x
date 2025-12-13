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
  final BlePrefService _blePrefService = BlePrefService.instance;
  List<ScanResult> _scannedList = [];
  //Scan result

  _scan() async {
    final _lastConnectedDeviceId = _blePrefService.lastConnectedDeviceId;
    await _bleHidService.scan();
    final _scannedDevices = await _bleHidService.listenScannin();
    _scannedDevices.onData((scannedList) {
      _scannedList = scannedList;

      if (mounted) setState(() {});
    });

    //Auto connect to last connected device
    ScanResult? _sr = _scannedList.firstWhere(
      (device) => device.device.remoteId.toString() == _blePrefService.lastConnectedDeviceId,
    );
    // if (_scannedDevice != null) {
    //   _bleHidService.connect(_scannedDevice.device);
    // }
  }

  _discover() async {
    await _bleHidService.discoverServices(_scannedList[0].device);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scan();
    });
  }

  @override
  void dispose() {
    // _bleHidService.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('BLE As Keyboard')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _scan(),
        child: Icon(Icons.search_outlined),
      ),
      body: Container(
        color: Colors.blueGrey[50], // Light background for the list
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
                    // Implement connection logic here
                    // For example: await device.connect();
                    // Then update UI or navigate

                    await device.connect(
                      // timeout: const Duration(seconds: 5),
                      // autoConnect: true,
                      // mtu: 45,
                    );
                    BlePrefService.instance.saveConnectedDevice(device.remoteId.str);
                    setState(() {});

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Connecting to ${device.advName}...')));
                    await _bleHidService.discoverServices(device);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DeviceDetailsPage(device: device)),
                    );
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                          'Last Scan',
                          scanResult.timeStamp.toLocal().toString().split('.')[0],
                        ),
                        _buildInfoRow('Services Count', device.servicesList.length.toString()),
                        SizedBox(height: 10),
                        Divider(color: Colors.grey[300]),
                        Text(
                          'Advertisement Data',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        _buildInfoRow('Connectable', advertisementData.connectable ? "Yes" : "No"),
                        _buildInfoRow(
                          'Tx Power Level',
                          advertisementData.txPowerLevel?.toString() ?? 'N/A',
                        ),
                        _buildInfoRow(
                          'Appearance',
                          advertisementData.appearance?.toString() ?? 'N/A',
                        ),
                        _buildInfoRow(
                          'Service UUIDs',
                          advertisementData.serviceUuids.isNotEmpty
                              ? advertisementData.serviceUuids.map((uuid) => uuid.str).join(', ')
                              : 'None',
                        ),
                        _buildInfoRow(
                          'Manufacturer Data',
                          advertisementData.manufacturerData.isNotEmpty
                              ? advertisementData.manufacturerData.entries
                                    .map((e) => '${e.key}: ${e.value}')
                                    .join(', ')
                              : 'None',
                        ),
                        _buildInfoRow(
                          'Service Data',
                          advertisementData.serviceData.isNotEmpty
                              ? advertisementData.serviceData.entries
                                    .map((e) => '${e.key}: ${e.value}')
                                    .join(', ')
                              : 'None',
                        ),
                        SizedBox(height: 10),
                        StreamBuilder<BluetoothBondState>(
                          stream: device.bondState.asBroadcastStream(),
                          initialData: BluetoothBondState.none,
                          builder: (context, snapshot) {
                            return _buildInfoRow(
                              'Bond State',
                              snapshot.data?.name ?? 'Unknown',
                              valueColor: snapshot.data == BluetoothBondState.bonded
                                  ? Colors.green
                                  : null,
                            );
                          },
                        ),
                        StreamBuilder<int>(
                          stream: device.mtu.asBroadcastStream(),
                          initialData: 0,
                          builder: (context, snapshot) {
                            return _buildInfoRow('MTU', snapshot.data?.toString() ?? 'N/A');
                          },
                        ),
                        SizedBox(height: 10),
                        if (device.isConnected)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  await device.disconnect();
                                  setState(() {});
                                },
                                child: Text("Disconnect", style: TextStyle(color: Colors.red)),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DeviceDetailsPage(device: device),
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
