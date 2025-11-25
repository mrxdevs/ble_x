import 'package:ble_x/features/ble_plus/presentation/screens/functional_music_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/ble_device.dart';
import '../../domain/models/ble_characteristic.dart';
import '../../../../core/utils/ble_plus/ble_utils.dart';
import '../../../../core/utils/ble_plus/uuid_helper.dart';
import '../viewmodels/ble_viewmodel.dart';

class DeviceDetailScreen extends StatelessWidget {
  final BleDevice device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BleViewModel>();
    final isConnected = viewModel.connectedDevice?.id == device.id;

    return Scaffold(
      appBar: AppBar(title: Text(device.name.isNotEmpty ? device.name : 'Unknown Device')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(context, device, isConnected),
            const SizedBox(height: 24),
            if (isConnected) ...[
              ElevatedButton(
                onPressed: () async {
                  try {
                    await viewModel.discoverServices(device);
                    await viewModel.validateDeviceName();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Found ${viewModel.services.length} services'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Discover Services'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FunctionalMusicScreen()),
                  );
                },
                child: const Text('Functionality Test'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Services & Characteristics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (viewModel.services.isEmpty)
                const Text('No services discovered yet.')
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: viewModel.services.length,
                  itemBuilder: (context, index) {
                    final service = viewModel.services[index];
                    final serviceName = UuidHelper.getDisplayName(service.uuid);
                    final hasKnownName = UuidHelper.hasKnownName(service.uuid);

                    return ExpansionTile(
                      title: Text(
                        hasKnownName ? serviceName : 'Service: $serviceName',
                        style: TextStyle(
                          fontWeight: hasKnownName ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        service.uuid,
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      children: service.characteristics.map((c) {
                        final charName = UuidHelper.getDisplayName(c.uuid);
                        final isKnownChar = UuidHelper.hasKnownName(c.uuid);

                        return ListTile(
                          title: Text(
                            isKnownChar ? charName : 'Char: $charName',
                            style: TextStyle(
                              fontWeight: isKnownChar ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isKnownChar)
                                Text(
                                  'UUID: ${c.uuid}',
                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              Text('Props: ${_getPropertiesString(c)}'),

                              // FutureBuilder(
                              //   future: c.bleCharacteristic?.read(),
                              //   builder: (context, asyncSnapshot) {
                              //     return Text('Value: ${asyncSnapshot.data} ${c.value} ');
                              //   },
                              // ),
                              if (c.value.isNotEmpty) ...[
                                Text(
                                  'Hex: ${c.valueAsString}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (c.isReadable)
                                IconButton(
                                  icon: const Icon(Icons.download),
                                  onPressed: () => viewModel.readCharacteristic(c),
                                ),
                              if (c.isWritable)
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    // Show dialog to write value
                                    _showWriteDialog(context, viewModel, c);
                                  },
                                ),
                              if (c.isNotifiable)
                                IconButton(
                                  icon: const Icon(Icons.notifications),
                                  onPressed: () {
                                    viewModel.subscribeToCharacteristic(c).listen((value) {
                                      // Update the characteristic value in the ViewModel
                                      viewModel.updateCharacteristicValue(c, value);

                                      // Decode the notification value for display
                                      final decodedValue = c.copyWith(value: value).valueAsString;
                                      // ScaffoldMessenger.of(context).showSnackBar(
                                      //   SnackBar(
                                      //     content: Text('Notification: $decodedValue'),
                                      //     backgroundColor: Colors.blue,
                                      //     duration: const Duration(seconds: 1),
                                      //   ),
                                      // );
                                    });
                                  },
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FilledButton.icon(
          onPressed: () {
            if (isConnected) {
              viewModel.disconnect();
            } else {
              viewModel.connect(device);
            }
          },
          icon: Icon(isConnected ? Icons.bluetooth_disabled : Icons.bluetooth_connected),
          label: Text(isConnected ? 'Disconnect' : 'Connect'),
          style: FilledButton.styleFrom(
            backgroundColor: isConnected ? Colors.red : null,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, BleDevice device, bool isConnected) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildRow(context, 'Device ID', device.id),
            const Divider(),
            _buildRow(context, 'RSSI', '${device.rssi} dBm'),
            const Divider(),
            _buildRow(context, 'Timestamp', device.timeStamp?.toString() ?? 'N/A'),
            const Divider(),
            _buildRow(context, 'Tx Power', device.txPowerLevel?.toString() ?? 'N/A'),
            const Divider(),
            _buildRow(context, 'Appearance', device.appearance?.toString() ?? 'N/A'),
            const Divider(),
            _buildRow(context, 'Manufacturer Data', device.manufacturerData?.toString() ?? 'N/A'),
            const Divider(),
            _buildRow(context, 'Service Data', device.serviceData?.toString() ?? 'N/A'),
            const Divider(),
            _buildRow(context, 'Service UUIDs', device.serviceUuids?.join(', ') ?? 'N/A'),
            const Divider(),
            _buildRow(
              context,
              'Est. Distance (Indoor)',
              device.txPowerLevel != null
                  ? '${BleUtils.calculateDistance(device.txPowerLevel!, device.rssi).toStringAsFixed(2)} m'
                  : 'N/A (TxPower missing)',
            ),
            const Divider(),
            _buildRow(
              context,
              'Status',
              isConnected ? 'Connected' : 'Disconnected',
              valueColor: isConnected ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  String _getPropertiesString(BleCharacteristic c) {
    final props = <String>[];
    if (c.isReadable) props.add('Read');
    if (c.isWritable) props.add('Write');
    if (c.isNotifiable) props.add('Notify');
    return props.join(', ');
  }

  void _showWriteDialog(BuildContext context, BleViewModel viewModel, BleCharacteristic c) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Write Value'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter hex (e.g. 0x12, 0x34) or string'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                // Parse input
                final input = controller.text;
                List<int> value = [];
                if (input.startsWith('0x')) {
                  // Simple hex parsing (comma separated)
                  value = input.split(',').map((s) => int.parse(s.trim())).toList();
                } else {
                  value = input.codeUnits;
                }

                viewModel.writeCharacteristic(c, value);
                Navigator.pop(context);
              },
              child: const Text('Write'),
            ),
          ],
        );
      },
    );
  }
}
