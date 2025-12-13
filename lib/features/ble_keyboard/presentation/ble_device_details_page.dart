import 'dart:convert'; // Required for UTF-8 decoding
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// Ensure you have this import if BleHidService is in a separate file,
// otherwise comment it out if not used in this specific UI snippet.
// import 'package:ble_x/features/ble_keyboard/data/ble_hid_service.dart';

class DeviceDetailsPage extends StatefulWidget {
  final BluetoothDevice device;
  const DeviceDetailsPage({super.key, required this.device});

  @override
  State<DeviceDetailsPage> createState() => _DeviceDetailsPageState();
}

class _DeviceDetailsPageState extends State<DeviceDetailsPage> {
  // final BleHidService _bleHidService = BleHidService(); // Uncomment if used
  late BluetoothDevice device;

  @override
  void initState() {
    super.initState();
    device = widget.device;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(device.platformName)),
      body: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Icon(Icons.bluetooth, color: Colors.blueAccent, size: 40),
                Text(
                  device.platformName.isNotEmpty ? device.platformName : "Unknown Device",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blueGrey[800],
                  ),
                ),
                Text(device.remoteId.str, style: TextStyle(color: Colors.grey[600])),

                const SizedBox(height: 10),

                // --- CONNECT / DISCONNECT BUTTONS ---
                StreamBuilder<BluetoothConnectionState>(
                  stream: device.connectionState,
                  initialData: BluetoothConnectionState.disconnected,
                  builder: (context, snapshot) {
                    bool isConnected = snapshot.data == BluetoothConnectionState.connected;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!isConnected)
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Connecting to ${device.platformName}...'),
                                  ),
                                );

                                await device.connect();
                                // await _bleHidService.discoverServices(device); // Optional: if you have a service helper
                                setState(() {}); // Refresh to show services
                              } catch (e) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
                              }
                            },
                            child: const Text("CONNECT"),
                          ),
                        if (isConnected)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () async {
                              await device.disconnect();
                              setState(() {});
                            },
                            child: const Text("DISCONNECT", style: TextStyle(color: Colors.white)),
                          ),
                        if (isConnected)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: ElevatedButton(
                              onPressed: () async {
                                // Re-discover services button
                                await device.discoverServices();
                                setState(() {});
                              },
                              child: const Text("Discover Services"),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                const Divider(),

                // --- SERVICES LIST ---
                if (device.isConnected) ...[
                  if (device.servicesList.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("No Services Found. Click 'Discover Services'"),
                    )
                  else
                    ...device.servicesList.map((service) => _buildServiceTile(service)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTile(BluetoothService service) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ExpansionTile(
        title: Text(
          "Service: ${service.uuid.str}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(service.isPrimary ? "Primary" : "Secondary"),
        children: service.characteristics.map((c) => _buildCharacteristicTile(c)).toList(),
      ),
    );
  }

  Widget _buildCharacteristicTile(BluetoothCharacteristic characteristic) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Characteristic: ${characteristic.uuid.str}",
            style: TextStyle(color: Colors.purple[800], fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          // --- PROPERTIES ROW ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow("Properties", characteristic.properties.toString()),

              const SizedBox(height: 8),
              const Text("Descriptors:", style: TextStyle(fontWeight: FontWeight.w600)),

              if (characteristic.descriptors.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 10.0, top: 4.0),
                  child: Text("None", style: TextStyle(color: Colors.grey)),
                )
              else
                // Map every descriptor to our new Widget
                ...characteristic.descriptors.map((d) => _buildDescriptorTile(d)),
            ],
          ),

          // --- ACTION BUTTONS ROW ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // READ Button
              if (characteristic.properties.read)
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.blue),
                  tooltip: 'Read',
                  onPressed: () => _readValue(characteristic),
                ),

              // WRITE Button
              if (characteristic.properties.write || characteristic.properties.writeWithoutResponse)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  tooltip: 'Write',
                  onPressed: () => _showWriteDialog(context, characteristic),
                ),

              // NOTIFY / INDICATE Toggle
              if (characteristic.properties.notify || characteristic.properties.indicate)
                StreamBuilder<List<int>>(
                  stream: characteristic.onValueReceived.asBroadcastStream(),
                  builder: (context, snapshot) {
                    // Check current state
                    bool isNotifying = characteristic.isNotifying;
                    return IconButton(
                      icon: Icon(
                        isNotifying ? Icons.notifications_active : Icons.notifications_off,
                        color: isNotifying ? Colors.green : Colors.grey,
                      ),
                      tooltip: 'Notify',
                      onPressed: () => _toggleNotify(characteristic),
                    );
                  },
                ),
            ],
          ),

          const Divider(),

          // --- DATA STREAM DISPLAY ---
          // This listens to the stream of values coming from Read or Notify
          StreamBuilder<List<int>>(
            stream: characteristic.lastValueStream,
            initialData: characteristic.lastValue,
            builder: (context, snapshot) {
              final data = snapshot.data ?? [];

              String stringValue = "N/A";
              try {
                stringValue = utf8.decode(data);
              } catch (e) {
                stringValue = "(Non-text data)";
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow("Last Update", DateTime.now().toString().split('.').first),
                  _buildInfoRow("Raw Bytes", "$data"),
                  _buildInfoRow("String Value", stringValue, valueColor: Colors.purple),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // --- LOGIC METHODS ---

  Future<void> _readValue(BluetoothCharacteristic characteristic) async {
    try {
      await characteristic.read();
      // The StreamBuilder will automatically update because .read() updates .lastValueStream
      print("Read successful");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Read Error: $e")));
    }
  }

  Future<void> _toggleNotify(BluetoothCharacteristic characteristic) async {
    try {
      if (characteristic.isNotifying) {
        await characteristic.setNotifyValue(false);
        print("Notifications disabled");
      } else {
        await characteristic.setNotifyValue(true);
        print("Notifications enabled");
        // Ensure we listen if not already (FlutterBluePlus handles the stream internally usually)
        // You can explicitly listen here if you need custom logic:
        // characteristic.onValueReceived.listen((value) { print("Received: $value"); });
      }
      setState(() {}); // Update the icon state
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Notify Error: $e")));
    }
  }

  Future<void> _showWriteDialog(
    BuildContext context,
    BluetoothCharacteristic characteristic,
  ) async {
    final TextEditingController _textController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Write to Characteristic"),
          content: TextField(
            controller: _textController,
            decoration: const InputDecoration(labelText: "Enter text (UTF-8)"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                try {
                  // Convert String to Bytes
                  List<int> bytes = utf8.encode(_textController.text);

                  // Decide write type
                  bool withoutResponse = characteristic.properties.writeWithoutResponse;

                  await characteristic.write(bytes, withoutResponse: withoutResponse);

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Wrote: '${_textController.text}'")));

                  // If it's a write, we might want to perform a read immediately to verify
                  if (characteristic.properties.read) {
                    await characteristic.read();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Write Error: $e")));
                }
              },
              child: const Text("Send"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDescriptorTile(BluetoothDescriptor descriptor) {
    return Container(
      margin: const EdgeInsets.only(top: 8.0, left: 10.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Display the Descriptor UUID (2901 is the User Description)
              Text(
                "Descriptor: ${descriptor.uuid.str}",
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              // The READ Button for this specific descriptor
              IconButton(
                icon: const Icon(Icons.download, size: 20, color: Colors.blue),
                tooltip: "Read Descriptor",
                onPressed: () async {
                  try {
                    await descriptor.read();
                    // The stream builder below will auto-update
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Read Error: $e")));
                  }
                },
              ),
            ],
          ),
          // Listen to the Descriptor's value stream to update UI when read
          StreamBuilder<List<int>>(
            stream: descriptor.lastValueStream,
            initialData: descriptor.lastValue,
            builder: (context, snapshot) {
              final data = snapshot.data ?? [];
              String decoded = "";

              // Try to decode as Text (useful for 0x2901 User Description)
              try {
                decoded = utf8.decode(data);
              } catch (e) {
                decoded = "(Not text)";
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Hex: $data", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  if (data.isNotEmpty)
                    Text(
                      "String: $decoded",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              );
            },
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
              maxLines: 50,
            ),
          ),
        ],
      ),
    );
  }
}
