import 'package:ble_x/features/music_control/presentation/music_control_screen.dart';
import 'package:ble_x/features/phone_control.dart';
import 'package:flutter/material.dart';
import 'package:nowplaying/nowplaying.dart';
import 'package:provider/provider.dart';

import 'package:ble_x/features/peripheral/screens/peripheral_screen.dart';
import 'package:ble_x/features/peripheral/viewmodels/peripheral_viewmodel.dart';
import 'core/theme/app_theme.dart';
import 'features/ble_plus/data/repositories/flutter_blue_plus_repository.dart';
import 'features/ble_plus/presentation/screens/scan_screen.dart';
import 'features/ble_plus/presentation/viewmodels/ble_viewmodel.dart';

void main() {
  runApp(const MyApp());
  NowPlaying.instance.start();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BleViewModel(FlutterBluePlusRepository())),
        ChangeNotifierProvider(create: (_) => PeripheralViewModel()),
      ],
      child: MaterialApp(
        title: 'BLE X',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    ScanScreen(),
    PeripheralScreen(),
    MusicControlScreen(),
    PhoneConrolScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.radar), label: 'Scanner'),
          NavigationDestination(icon: Icon(Icons.broadcast_on_personal), label: 'Peripheral'),
          NavigationDestination(icon: Icon(Icons.music_note), label: 'Music'),
          NavigationDestination(icon: Icon(Icons.call), label: 'Call'),
        ],
      ),
    );
  }
}
