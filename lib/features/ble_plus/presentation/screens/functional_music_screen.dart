import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volume_controller/volume_controller.dart';
import '../viewmodels/ble_viewmodel.dart';

class FunctionalMusicScreen extends StatefulWidget {
  const FunctionalMusicScreen({super.key});

  @override
  State<FunctionalMusicScreen> createState() => _FunctionalMusicScreenState();
}

class _FunctionalMusicScreenState extends State<FunctionalMusicScreen>
    with TickerProviderStateMixin {
  bool _isPlaying = false;
  bool _isShuffle = false;
  bool _isRepeat = false;
  double _volume = 0.7;
  double _progress = 0.3;
  bool _isInfoExpanded = false;
  bool _isNext = false;
  bool _isPrevious = false;

  late AnimationController _playPauseController;
  late AnimationController _rotationController;

  // Device info
  String? _brandTag;
  String? _deviceModel;
  String? _serialNumber;
  bool _isLoadingDeviceInfo = false;

  @override
  void initState() {
    super.initState();
    _playPauseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationController = AnimationController(duration: const Duration(seconds: 10), vsync: this);

    // Load device info when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDeviceInfo();
    });
  }

  @override
  void dispose() {
    _playPauseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceInfo() async {
    final viewModel = context.read<BleViewModel>();
    if (viewModel.connectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Device not connected')));
      return;
    }

    setState(() {
      _isLoadingDeviceInfo = true;
    });

    try {
      // Look for device information in characteristics

      for (var service in viewModel.services) {
        for (var char in service.characteristics) {
          if (char.isReadable) {
            try {
              await viewModel.readCharacteristic(char);
              final value = char.valueAsString;

              // Try to identify characteristics by UUID or name
              // Update these conditions based on your device's actual UUIDs
              if (char.uuid.endsWith('100001')) {
                _brandTag = value;
              } else if (char.uuid.endsWith('100002')) {
                _deviceModel = value;
              } else if (char.uuid.endsWith('100003')) {
                _serialNumber = value;
              } else if (char.uuid.endsWith('300001')) {
                _isPlaying = value == "01";
                print("isPlaying: $value");
                viewModel.subscribeToCharacteristic(char).listen((value) {
                  viewModel.updateCharacteristicValue(char, value);

                  final int byte = (value.isNotEmpty) ? value.first : 0;
                  final bool isPlayingNow = byte == 1;

                  debugPrint('isPlaying on listen validation-->: $isPlayingNow');
                  _togglePlayPause();

                  // if (isPlayingNow) {
                  //   if (!mounted) return;
                  //   setState(() => _isPlaying = true);
                  // } else {
                  //   if (!mounted) return;
                  //   setState(() => _isPlaying = false);
                  // }

                  debugPrint('isPlaying on listen-->: $value');
                });
              } else if (char.uuid.endsWith('300002')) {
                _isNext = value == "01";
                print("isNext: $value");
              } else if (char.uuid.endsWith('300003')) {
                _isPrevious = value == "01";
                print("isPrevious: $value");
              } else if (char.uuid.endsWith('300004')) {
                _volume = double.parse(value) / 100;
                print("volume: $value");
                viewModel.subscribeToCharacteristic(char).listen((value) {
                  // Update the characteristic value in the ViewModel
                  viewModel.updateCharacteristicValue(char, value);
                  _volume = double.parse(utf8.decode(value)) / 100;
                  VolumeController.instance.setVolume(_volume);
                });
              }
            } catch (e) {
              // Ignore read errors for individual characteristics
            }
          }
        }
      }
    } catch (e) {
      // Handle error silently
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDeviceInfo = false;
        });
      }
    }
  }

  void _togglePlayPause() {
    if (!mounted) return;
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _playPauseController.forward();
        _rotationController.repeat();
      } else {
        _playPauseController.reverse();
        _rotationController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BleViewModel>();
    final isConnected = viewModel.connectedDevice != null;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              HSLColor.fromAHSL(1.0, 240, 0.6, 0.15).toColor(),
              HSLColor.fromAHSL(1.0, 280, 0.5, 0.1).toColor(),
              HSLColor.fromAHSL(1.0, 260, 0.55, 0.08).toColor(),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Music Player',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              // Device Info Bar
              _buildDeviceInfoBar(isConnected, viewModel),

              const SizedBox(height: 24),

              // Main Content
              Expanded(child: isConnected ? _buildMusicPlayer() : _buildNoConnectionView()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceInfoBar(bool isConnected, BleViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isInfoExpanded = !_isInfoExpanded;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ColorFilter.mode(Colors.white.withOpacity(0.1), BlendMode.srcOver),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                          color: isConnected ? Colors.greenAccent : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isConnected ? 'Connected' : 'Disconnected',
                          style: TextStyle(
                            color: isConnected ? Colors.greenAccent : Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (_isLoadingDeviceInfo && _isInfoExpanded)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        else if (_isInfoExpanded)
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white70),
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: isConnected ? _loadDeviceInfo : null,
                          ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: _isInfoExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 24),
                        ),
                      ],
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox(width: double.infinity),
                      secondChild: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            'Brand Tag',
                            _brandTag ?? (isConnected ? 'Reading...' : 'N/A'),
                            Icons.label_outline,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Device Model',
                            _deviceModel ?? (isConnected ? 'Reading...' : 'N/A'),
                            Icons.devices_outlined,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Serial Number',
                            _serialNumber ?? (isConnected ? 'Reading...' : 'N/A'),
                            Icons.tag,
                          ),
                          if (isConnected) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              'Device Name',
                              viewModel.connectedDevice?.name ?? 'Unknown',
                              Icons.phone_android,
                            ),
                          ],
                        ],
                      ),
                      crossFadeState: _isInfoExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoConnectionView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_disabled, size: 80, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 20),
          Text(
            'No Device Connected',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Please connect a BLE device first',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicPlayer() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Album Art
            _buildAlbumArt(),

            const SizedBox(height: 40),

            // Song Info
            const Text(
              'Current Song Title',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Artist Name',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
            ),

            const SizedBox(height: 40),

            // Progress Bar
            _buildProgressBar(),

            const SizedBox(height: 40),

            // Playback Controls
            _buildPlaybackControls(),

            const SizedBox(height: 40),

            // Volume Control
            _buildVolumeControl(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumArt() {
    return RotationTransition(
      turns: _rotationController,
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              HSLColor.fromAHSL(1.0, 280, 0.7, 0.5).toColor(),
              HSLColor.fromAHSL(1.0, 240, 0.8, 0.4).toColor(),
              HSLColor.fromAHSL(1.0, 260, 0.75, 0.3).toColor(),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: HSLColor.fromAHSL(0.4, 260, 0.7, 0.4).toColor(),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Icon(Icons.music_note, size: 100, color: Colors.white.withOpacity(0.8)),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.3),
          ),
          child: Slider(value: _progress, onChanged: (value) => setState(() => _progress = value)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(Duration(seconds: (_progress * 180).toInt())),
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
              ),
              Text(
                _formatDuration(const Duration(seconds: 180)),
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Shuffle
        _buildControlButton(
          icon: Icons.shuffle,
          isActive: _isShuffle,
          onPressed: () => setState(() => _isShuffle = !_isShuffle),
          size: 24,
        ),

        // Previous
        _buildControlButton(icon: Icons.skip_previous, onPressed: () {}, size: 40),

        // Play/Pause
        _buildPlayPauseButton(),

        // Next
        _buildControlButton(icon: Icons.skip_next, onPressed: () {}, size: 40),

        // Repeat
        _buildControlButton(
          icon: Icons.repeat,
          isActive: _isRepeat,
          onPressed: () => setState(() => _isRepeat = !_isRepeat),
          size: 24,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
    double size = 32,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: size,
          color: isActive
              ? HSLColor.fromAHSL(1.0, 280, 0.7, 0.6).toColor()
              : Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return InkWell(
      onTap: _togglePlayPause,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              HSLColor.fromAHSL(1.0, 280, 0.7, 0.5).toColor(),
              HSLColor.fromAHSL(1.0, 240, 0.8, 0.4).toColor(),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: HSLColor.fromAHSL(0.5, 260, 0.7, 0.4).toColor(),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: AnimatedIcon(
            icon: AnimatedIcons.play_pause,
            progress: _playPauseController,
            size: 40,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            _volume == 0 ? Icons.volume_off : Icons.volume_up,
            color: Colors.white.withOpacity(0.8),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: HSLColor.fromAHSL(1.0, 280, 0.7, 0.6).toColor(),
                inactiveTrackColor: Colors.white.withOpacity(0.3),
                thumbColor: HSLColor.fromAHSL(1.0, 280, 0.7, 0.6).toColor(),
                overlayColor: HSLColor.fromAHSL(0.3, 280, 0.7, 0.6).toColor(),
              ),
              child: Slider(value: _volume, onChanged: (value) => setState(() => _volume = value)),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${(_volume * 100).toInt()}%',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
