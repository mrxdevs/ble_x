import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/ble_viewmodel.dart';
import 'device_detail_screen.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BleViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Scanner'),
        actions: [
          if (viewModel.isScanning)
            FadeIn(
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: viewModel.scanResults.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bluetooth_searching,
                    size: 100,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No devices found',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tap the scan button to start',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.scanResults.length,
              itemBuilder: (context, index) {
                final device = viewModel.scanResults[index];
                return FadeInUp(
                  delay: Duration(milliseconds: index * 5),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.bluetooth,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(
                        device.name.isNotEmpty ? device.name : 'Unknown Device',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(device.id),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${device.rssi} dBm',
                            style: TextStyle(
                              color: device.rssi > -60
                                  ? Colors.green
                                  : device.rssi > -80
                                  ? Colors.orange
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (device.isConnectable)
                            const Icon(Icons.link, size: 16, color: Colors.green),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => DeviceDetailScreen(device: device)),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: viewModel.isScanning ? viewModel.stopScan : viewModel.startScan,
        icon: Icon(viewModel.isScanning ? Icons.stop : Icons.search),
        label: Text(viewModel.isScanning ? 'Stop Scan' : 'Start Scan'),
      ),
    );
  }
}
