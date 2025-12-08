# BLE X - Advanced Bluetooth Low Energy Application

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.9.2-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.9.2-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

A powerful Flutter application demonstrating advanced Bluetooth Low Energy (BLE) capabilities, system-level media control, and phone dialer integration with a premium UI/UX.

</div>

---

## 📑 Table of Contentents

- [Features](#-features)
- [Screenshots](#-screenshots)
- [Architecture](#-architecture)
- [Project Structure](#-project-structure)
- [Code Explanation](#-code-explanation)
- [Dependencies](#-dependencies)
- [Getting Started](#-getting-started)
- [Building Release APK](#-building-release-apk)
- [Permissions](#-permissions)
- [License](#-license)

---

## 🚀 Features

### 1. **BLE Scanner** 📡
Scan and analyze nearby Bluetooth Low Energy devices in real-time with advanced filtering and visualization.

**Key Features:**
- **Real-time Scanning**: Start/stop BLE device scanning with timeout (15 seconds)
- **Device Information**: 
  - Device Name (or "Unknown Device" if not advertised)
  - Device ID (MAC address)
  - RSSI Signal Strength with color-coded indicators:
    - 🟢 Green: > -60 dBm (Excellent)
    - 🟠 Orange: -60 to -80 dBm (Good)
    - 🔴 Red: < -80 dBm (Poor)
  - Connectable status indicator
- **Device Details**: Tap any device to view:
  - All GATT Services and Characteristics
  - Read/Write/Notify capabilities
  - Real-time characteristic value updates
  - Hex and UTF-8 decoded values
- **Animated UI**: Smooth fade-in animations for discovered devices
- **Empty State**: Beautiful placeholder when no devices are found

### 2. **Peripheral Mode** 📢
Transform your device into a BLE peripheral to advertise services to other devices.

**Key Features:**
- **BLE Advertising**: Toggle advertising on/off
- **Visual Status**: Real-time feedback on advertising state (Active/Stopped)
- **Configuration Display**:
  - Service UUID: `bf27cfb9-87f5-4e0d-be1d-a01196e55b55`
  - Local Name: `test`
  - Manufacturer ID: 1234
  - Manufacturer Data: Custom byte array
- **Connectable Mode**: Advertises as connectable peripheral
- **High Performance**: Uses low-latency advertising mode with high TX power

### 3. **Music Control** 🎵
A beautiful, premium music controller with system-level media playback integration.

**Key Features:**
- **Playback Control**: 
  - Play/Pause with animated icon transitions
  - Next/Previous track navigation
  - Shuffle and Repeat toggles
- **Real-time Media Info**:
  - Song Title and Artist
  - Album Artwork (with fallback icon)
  - Current position and duration
  - Playback state (playing/paused)
- **Volume Control**: 
  - System volume adjustment
  - Visual volume percentage display
  - Volume icon changes based on level
- **Premium UI**:
  - Dynamic HSL-based gradient backgrounds
  - Rotating album art animation
  - Glassmorphism effects
  - Smooth progress bar with time display
  - Responsive touch interactions
- **System Integration**:
  - Android MediaSession integration
  - Notification listener for media updates
  - Real-time metadata streaming

### 4. **Phone Control** 📞
A built-in phone dialer interface with a clean, intuitive design.

**Key Features:**
- **Numeric Keypad**: Standard 0-9, *, # layout
- **Real-time Display**: Shows dialed number as you type
- **Backspace**: Remove last digit
- **Call Button**: Initiate call (requires phone permissions)
- **Responsive Grid**: 3-column layout with circular buttons

---

## 📸 Screenshots

|               BLE Scanner               |                Peripheral Mode                 |              Music Player              |              Phone Control              |
| :-------------------------------------: | :--------------------------------------------: | :------------------------------------: | :-------------------------------------: |
| ![BLE Scanner](screenshots/scanner.png) | ![Peripheral Mode](screenshots/peripheral.png) | ![Music Player](screenshots/music.png) | ![Phone Control](screenshots/phone.png) |

> **Note**: Screenshots show the app running on Android. Please add your screenshots to the `screenshots/` directory.

---

## 🏗 Architecture

This project follows **Clean Architecture** principles with a **feature-based modular structure**, ensuring:
- ✅ Separation of concerns
- ✅ Testability
- ✅ Scalability
- ✅ Maintainability

### Architecture Layers

```
┌─────────────────────────────────────────────────┐
│           Presentation Layer (UI)               │
│  ┌──────────────┐  ┌──────────────┐            │
│  │   Screens    │  │  ViewModels  │            │
│  │   (Widgets)  │◄─┤  (Provider)  │            │
│  └──────────────┘  └──────────────┘            │
└─────────────────────────────────────────────────┘
                      ▲
                      │
┌─────────────────────────────────────────────────┐
│              Domain Layer                       │
│  ┌──────────────┐  ┌──────────────┐            │
│  │   Models     │  │ Repositories │            │
│  │  (Entities)  │  │ (Interfaces) │            │
│  └──────────────┘  └──────────────┘            │
└─────────────────────────────────────────────────┘
                      ▲
                      │
┌─────────────────────────────────────────────────┐
│               Data Layer                        │
│  ┌──────────────┐  ┌──────────────┐            │
│  │ Repositories │  │ Data Sources │            │
│  │(Impl)        │◄─┤ (BLE/Native) │            │
│  └──────────────┘  └──────────────┘            │
└─────────────────────────────────────────────────┘
```

### Key Architectural Patterns

1. **Repository Pattern**: Abstracts data sources (BLE, Native Platform)
2. **Provider Pattern**: State management using `ChangeNotifier`
3. **Dependency Injection**: ViewModels receive repositories via constructor
4. **Reactive Programming**: Streams for real-time BLE scanning and media updates
5. **Platform Channels**: Method and Event channels for native Android/iOS integration

---

## 📂 Project Structure

```
lib/
├── main.dart                      # App entry point, Provider setup, Navigation
│
├── core/                          # Shared/Core functionality
│   ├── phone_call/
│   │   └── phone_control.dart     # Phone dialer UI and logic
│   ├── theme/
│   │   └── app_theme.dart         # Light/Dark theme definitions
│   └── utils/                     # Utility classes (if any)
│
└── features/                      # Feature modules
    │
    ├── ble_plus/                  # BLE Scanner Feature
    │   ├── data/
    │   │   └── repositories/
    │   │       └── flutter_blue_plus_repository.dart  # BLE data source impl
    │   ├── domain/
    │   │   ├── models/
    │   │   │   ├── ble_device.dart           # Device entity
    │   │   │   ├── ble_service.dart          # Service entity
    │   │   │   └── ble_characteristic.dart   # Characteristic entity
    │   │   └── repository/
    │   │       └── ble_repository.dart       # Repository interface
    │   └── presentation/
    │       ├── screens/
    │       │   ├── scan_screen.dart          # Scanner UI
    │       │   └── device_detail_screen.dart # Device details UI
    │       └── viewmodels/
    │           └── ble_viewmodel.dart        # Scanner state management
    │
    ├── peripheral/                # BLE Peripheral Feature
    │   ├── screens/
    │   │   └── peripheral_screen.dart        # Peripheral UI
    │   └── viewmodels/
    │       └── peripheral_viewmodel.dart     # Peripheral state management
    │
    └── music_control/             # Music Player Feature
        ├── domain/                # (if needed)
        └── presentation/
            ├── music_control_screen.dart     # Music player UI
            ├── now_playing_screen.dart       # Now playing details
            ├── system_music_controller.dart  # Media control logic
            └── music_controller_imp.dart     # Additional controllers
```

### Folder Descriptions

| Folder              | Purpose                                                   |
| ------------------- | --------------------------------------------------------- |
| **`core/`**         | Shared utilities, themes, and cross-feature functionality |
| **`features/`**     | Feature-based modules (each feature is self-contained)    |
| **`domain/`**       | Business logic, entities, and repository interfaces       |
| **`data/`**         | Repository implementations and data sources               |
| **`presentation/`** | UI screens, widgets, and ViewModels                       |

---

## 💻 Code Explanation

### 1. BLE Scanner Implementation

#### **BleViewModel** (`ble_viewmodel.dart`)
Manages BLE scanning state and device connections using the Provider pattern.

**Key Responsibilities:**
- Listens to BLE scan results via Stream
- Manages connection state
- Discovers GATT services and characteristics
- Handles read/write/notify operations
- Updates UI via `notifyListeners()`

**Code Highlights:**
```dart
class BleViewModel extends ChangeNotifier {
  final BleRepository _repository;
  
  List<BleDevice> _scanResults = [];
  bool _isScanning = false;
  BleDevice? _connectedDevice;
  List<BleService> _services = [];
  
  // Listen to scan results stream
  BleViewModel(this._repository) {
    _scanSubscription = _repository.scanResults.listen((results) {
      _scanResults = results;
      notifyListeners(); // Update UI
    });
  }
  
  // Start scanning with error handling
  Future<void> startScan() async {
    _scanResults.clear();
    await _repository.startScan();
  }
  
  // Connect to device and discover services
  Future<void> connect(BleDevice device) async {
    await _repository.connect(device);
    _connectedDevice = device;
    notifyListeners();
  }
}
```

#### **FlutterBluePlusRepository** (`flutter_blue_plus_repository.dart`)
Implements the `BleRepository` interface using `flutter_blue_plus` package.

**Key Features:**
- Singleton pattern for single instance
- Maps native BLE objects to domain models
- Handles platform-specific Bluetooth operations
- Manages GATT operations (read/write/notify)

**Code Highlights:**
```dart
class FlutterBluePlusRepository implements BleRepository {
  @override
  Stream<List<BleDevice>> get scanResults {
    return FlutterBluePlus.scanResults.map((results) {
      return results.map((r) => BleDevice(
        id: r.device.remoteId.str,
        name: r.device.platformName,
        rssi: r.rssi,
        isConnectable: r.advertisementData.connectable,
      )).toList();
    });
  }
  
  @override
  Future<void> startScan() async {
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn(); // Request Bluetooth
    }
    await FlutterBluePlus.startScan(timeout: Duration(seconds: 15));
  }
}
```

### 2. Music Control Implementation

#### **SystemMediaController2** (`system_music_controller.dart`)
Bridges Flutter with native Android MediaSession via Platform Channels.

**Architecture:**
- **MethodChannel**: Send commands (play/pause/next/previous)
- **EventChannel**: Receive media updates (metadata, playback state)
- **StreamController**: Broadcast media info to UI

**Code Highlights:**
```dart
class SystemMediaController2 {
  static const MethodChannel _control = MethodChannel('com.example.app/media_control');
  static const EventChannel _stream = EventChannel('com.example.app/media_stream');
  
  static final StreamController<MediaInfo> _controller = StreamController.broadcast();
  static Stream<MediaInfo> get mediaStream => _controller.stream;
  
  static void init() {
    _stream.receiveBroadcastStream().listen((event) {
      final data = Map<String, dynamic>.from(event);
      
      if (data['type'] == 'metadata') {
        _cache.title = data['title'] ?? "Unknown";
        _cache.artist = data['artist'] ?? "Unknown";
        _cache.artwork = data['artwork']; // Uint8List
      } else if (data['type'] == 'state') {
        _cache.isPlaying = data['isPlaying'] ?? false;
        _cache.currentPosition = data['position'] ?? 0;
      }
      
      _controller.add(_cache); // Update UI
    });
  }
  
  static Future<void> playPause() async => 
    await _control.invokeMethod('playPause');
}
```

#### **MusicControlScreen** (`music_control_screen.dart`)
Premium UI with animations and real-time media updates.

**UI Features:**
- HSL-based gradient backgrounds
- Rotating album art (AnimationController)
- Animated play/pause icon (AnimatedIcon)
- Real-time progress bar with timer
- Glassmorphism card effects

**Code Highlights:**
```dart
class _MusicControlScreenState extends State<MusicControlScreen> 
    with TickerProviderStateMixin {
  MediaInfo _info = MediaInfo();
  late AnimationController _rotationController;
  
  @override
  void initState() {
    super.initState();
    SystemMediaController2.init();
    
    // Listen for media updates
    SystemMediaController2.mediaStream.listen((info) {
      setState(() => _info = info);
    });
    
    // Simulate smooth progress
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_info.isPlaying) {
        setState(() => _info.currentPosition += 1000);
      }
    });
    
    _rotationController = AnimationController(
      duration: Duration(seconds: 10),
      vsync: this,
    );
  }
  
  Widget _buildAlbumArt() {
    return RotationTransition(
      turns: _rotationController,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: _info.artwork != null
            ? DecorationImage(image: MemoryImage(_info.artwork!))
            : null,
        ),
      ),
    );
  }
}
```

### 3. Peripheral Mode Implementation

#### **PeripheralViewModel** (`peripheral_viewmodel.dart`)
Manages BLE peripheral advertising using `flutter_ble_peripheral`.

**Key Features:**
- Advertises with custom UUID and manufacturer data
- Connectable mode enabled
- High-performance advertising settings
- State management for advertising status

**Code Highlights:**
```dart
class PeripheralViewModel extends ChangeNotifier {
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  bool _isAdvertising = false;
  
  Future<void> startAdvertising() async {
    final advertiseData = AdvertiseData(
      serviceUuid: 'bf27cfb9-87f5-4e0d-be1d-a01196e55b55',
      localName: 'test',
      manufacturerId: 1234,
      manufacturerData: Uint8List.fromList([1, 2, 3, 4, 5, 6, 7]),
    );
    
    final advertiseSettings = AdvertiseSettings(
      advertiseMode: AdvertiseMode.advertiseModeLowLatency,
      txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
      connectable: true,
    );
    
    await _blePeripheral.start(
      advertiseData: advertiseData,
      advertiseSettings: advertiseSettings,
    );
  }
}
```

### 4. Theme System

#### **AppTheme** (`app_theme.dart`)
Centralized theme management with Material 3 design.

**Features:**
- Light and Dark themes
- Google Fonts (Poppins) integration
- Consistent color schemes
- Custom card and app bar styling

**Code Highlights:**
```dart
class AppTheme {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Color(0xFF2196F3), // Blue
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(),
  );
  
  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Color(0xFF2196F3),
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
  );
}
```

### 5. Main Application Setup

#### **main.dart**
Application entry point with Provider setup and navigation.

**Code Highlights:**
```dart
void main() {
  runApp(const MyApp());
  NowPlaying.instance.start(); // Initialize media listener
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => 
          BleViewModel(FlutterBluePlusRepository())),
        ChangeNotifierProvider(create: (_) => 
          PeripheralViewModel()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
```

---

## 📦 Dependencies

### Core Dependencies

| Package                    | Version | Purpose                          |
| -------------------------- | ------- | -------------------------------- |
| **flutter_blue_plus**      | 1.34.5  | BLE scanning and GATT operations |
| **flutter_ble_peripheral** | 2.0.0   | BLE peripheral advertising       |
| **provider**               | 6.1.5+1 | State management                 |
| **permission_handler**     | 12.0.1  | Runtime permissions              |
| **google_fonts**           | 6.3.2   | Custom typography (Poppins)      |
| **animate_do**             | 4.2.0   | UI animations                    |

### Media & System Integration

| Package                 | Version | Purpose                    |
| ----------------------- | ------- | -------------------------- |
| **nowplaying**          | 3.0.3   | Media session listener     |
| **volume_controller**   | 3.4.0   | System volume control      |
| **android_intent_plus** | 6.0.0   | Android intents            |
| **just_audio**          | 0.10.5  | Audio playback (if needed) |

### UI Dependencies

| Package             | Version | Purpose         |
| ------------------- | ------- | --------------- |
| **cupertino_icons** | 1.0.8   | iOS-style icons |

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: 3.9.2 or higher
- **Dart SDK**: 3.9.2 or higher
- **Android Studio** or **Xcode**
- **Physical Device** (BLE features don't work on emulators)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/ble_x.git
   cd ble_x
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Check Flutter setup:**
   ```bash
   flutter doctor
   ```

4. **Connect your physical device** (via USB or WiFi debugging)

5. **Run the app:**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### Android

Ensure the following permissions are in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

#### iOS

Add the following to `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to scan and connect to BLE devices</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs Bluetooth to advertise as a peripheral</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access for BLE scanning</string>
```

---

## 📱 Building Release APK

To generate a release APK for Android installation:

```bash
flutter build apk --release
```

The output file will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Build App Bundle (for Google Play)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

---

## 🔐 Permissions

This app requires the following permissions:

### Android
- ✅ **Bluetooth**: BLE scanning and connections
- ✅ **Bluetooth Admin**: Enable/disable Bluetooth
- ✅ **Bluetooth Scan**: Discover nearby devices (Android 12+)
- ✅ **Bluetooth Connect**: Connect to devices (Android 12+)
- ✅ **Bluetooth Advertise**: Peripheral mode (Android 12+)
- ✅ **Location**: Required for BLE scanning on Android
- ✅ **Notification Listener**: Media session access (Music Control)

### iOS
- ✅ **Bluetooth**: BLE operations
- ✅ **Location When In Use**: BLE scanning

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 📧 Contact

For questions or support, please open an issue on GitHub.

---

<div align="center">

**Made with ❤️ using Flutter**

</div>
