import 'package:flutter/material.dart';

class BleAsKeyboardScreen extends StatefulWidget {
  const BleAsKeyboardScreen({super.key});

  @override
  State<BleAsKeyboardScreen> createState() => _BleAsKeyboardScreenState();
}

class _BleAsKeyboardScreenState extends State<BleAsKeyboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('BLE As Keyboard')));
  }
}
