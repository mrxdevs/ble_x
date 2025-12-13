import 'package:ble_x/features/ble_keyboard/data/ble_hid_service.dart';
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
  //Scan result

  _scan() async {
    await _bleHidService.scan();
    final _scannedDevices = await _bleHidService.listenScannin();
    _scannedDevices.onData((scannedList) {
      _scannedList = scannedList;

      if (mounted) setState(() {});
    });
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('BLE As Keyboard')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _scan(),
        child: Icon(Icons.search_outlined),
      ),
      body: Container(
        child: ListView.builder(
          itemCount: _scannedList.length,
          itemBuilder: (context, index) {
            final device = _scannedList[index].device;
            final advertisementData = _scannedList[index].advertisementData;
            final rssi = _scannedList[index].rssi;
            final timestamp = _scannedList[index].timeStamp;

            return Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey)),
              ),
              child: ListTile(
                leading: Icon(Icons.bluetooth),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Handling Device Data
                    Text(
                      device.advName.isEmpty ? device.platformName : device.advName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    //Time
                    Text(timestamp.toString()),
                    //Device Platform Name
                    Text(device.platformName),
                    Text(_scannedList[index].rssi.toString()),
                    //Device State
                    Text(device.isConnected ? "Connected" : "Disconnected"),
                    //Device Services
                    Text(device.remoteId.toString()),
                    //Device Id
                    Text(device.servicesList.toString()),

                    StreamBuilder(
                      stream: device.bondState.asBroadcastStream(),
                      builder: (context, asyncSnapshot) {
                        return Column(
                          children: [
                            Text(asyncSnapshot.connectionState.name),
                            Text(asyncSnapshot.data.toString()),
                          ],
                        );
                      },
                    ),

                    StreamBuilder(
                      stream: device.mtu.asBroadcastStream(),
                      builder: (context, asyncSnapshot) {
                        return Column(
                          children: [
                            Text(asyncSnapshot.connectionState.name),
                            Text(asyncSnapshot.data.toString()),
                          ],
                        );
                      },
                    ),

                    /// Handling Advertisement Data
                    Text(advertisementData.advName),
                    Text(advertisementData.txPowerLevel.toString()),
                    Text(advertisementData.connectable ? "Connectable" : "Not Connectable"),
                    Text(advertisementData.appearance.toString()),
                    Text(advertisementData.manufacturerData.entries.toList().toString()),
                    Text(advertisementData.serviceData.entries.toList().toString()),
                    Text(advertisementData.serviceUuids.toString()),
                    Text(advertisementData.msd.toString()),

                    // Text(advertisementData.),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
