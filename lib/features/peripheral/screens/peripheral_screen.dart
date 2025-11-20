import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/peripheral_viewmodel.dart';

class PeripheralScreen extends StatelessWidget {
  const PeripheralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PeripheralViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Peripheral Mode')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Advertising Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Icon(
                      viewModel.isAdvertising ? Icons.bluetooth_audio : Icons.bluetooth_disabled,
                      size: 64,
                      color: viewModel.isAdvertising ? Colors.blue : Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      viewModel.isAdvertising ? 'Advertising...' : 'Stopped',
                      style: TextStyle(
                        fontSize: 24,
                        color: viewModel.isAdvertising ? Colors.blue : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuration',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('Service UUID:', style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      viewModel.advertisingUuid,
                      style: const TextStyle(fontFamily: 'Monospace', fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text('Local Name:', style: Theme.of(context).textTheme.bodyMedium),
                    const Text('MyFlutterApp', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () {
                if (viewModel.isAdvertising) {
                  viewModel.stopAdvertising();
                } else {
                  viewModel.startAdvertising();
                }
              },
              icon: Icon(viewModel.isAdvertising ? Icons.stop : Icons.play_arrow),
              label: Text(viewModel.isAdvertising ? 'Stop Advertising' : 'Start Advertising'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: viewModel.isAdvertising ? Colors.red : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
