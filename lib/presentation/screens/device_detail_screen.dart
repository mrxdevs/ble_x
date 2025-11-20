import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/ble_device.dart';
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
              Text('Services', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              if (viewModel.services.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                ...viewModel.services.map(
                  (s) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(s.toString()),
                      leading: const Icon(Icons.settings_input_component),
                    ),
                  ),
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
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }
}
