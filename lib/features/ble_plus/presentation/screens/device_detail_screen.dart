import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/ble_device.dart';
import '../../domain/models/ble_service.dart';
import '../../domain/models/ble_characteristic.dart';
import '../../../../core/utils/ble_plus/ble_utils.dart';
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
                onPressed: () {
                  viewModel.discoverServices(device);
                },
                child: const Text('Discover Services'),
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
                    return ExpansionTile(
                      title: Text(
                        'Service: 0x${service..toString().toUpperCase().substring(4, 8)}',
                      ),
                      subtitle: Text(service.uuid.toString()),
                      children: service.characteristics.map((c) {
                        return ListTile(
                          title: Text('Char: ${c.uuid}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Props: ${_getPropertiesString(c)}'),
                              if (c.value.isNotEmpty) Text('Value: ${c.value}'),
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
                                      // Update UI or show snackbar
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Notification: $value')),
                                      );
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
