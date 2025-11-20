import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/flutter_blue_plus_repository.dart';
import 'presentation/screens/scan_screen.dart';
import 'presentation/viewmodels/ble_viewmodel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => BleViewModel(FlutterBluePlusRepository()))],
      child: MaterialApp(
        title: 'Ble X',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const ScanScreen(),
      ),
    );
  }
}
