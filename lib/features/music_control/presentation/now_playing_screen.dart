import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nowplaying/nowplaying.dart';
import 'package:nowplaying/nowplaying_spotify_controller.dart';
import 'package:nowplaying/nowplaying_track.dart';
import 'package:provider/provider.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  NowPlayingTrack? _mediaInfo = NowPlayingTrack();
  StreamSubscription<NowPlayingTrack>? _subscription;

  @override
  void initState() {
    super.initState();
    // Listen to media stream

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print("Now Playing: initState: Music player");
      NowPlaying.instance.isEnabled().then((isEnabled) async {
        if (!isEnabled) {
          final shown = await NowPlaying.instance.requestPermissions();
          print('MANAGED TO SHOW PERMS PAGE: $shown');
        }

        if (NowPlaying.spotify.isEnabled && NowPlaying.spotify.isUnconnected) {
          NowPlaying.spotify.signIn(context);
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                HSLColor.fromAHSL(1.0, 240, 0.6, 0.15).toColor(),
                HSLColor.fromAHSL(1.0, 280, 0.5, 0.1).toColor(),
              ],
            ),
          ),
        ),
      ),
      body: StreamProvider<NowPlayingTrack>.value(
        initialData: NowPlayingTrack.loading,
        value: NowPlaying.instance.stream,
        child: Consumer<NowPlayingTrack>(
          builder: (context, track, _) {
            // if (track == NowPlayingTrack.loading) return Container();
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (track.isStopped) Center(child: Text('nothing playing')),
                if (!track.isStopped) ...[
                  if (track.title != null) Text(track.title!.trim()),
                  if (track.artist != null) Text(track.artist!.trim()),
                  if (track.album != null) Text(track.album!.trim()),
                  Text(track.duration.toString()),
                  TrackProgressIndicator(track),
                  Text(track.state.toString()),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                        width: 200,
                        height: 200,
                        alignment: Alignment.center,
                        color: Colors.grey,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: _imageFrom(track),
                        ),
                      ),
                      Positioned(bottom: 0, right: 0, child: _iconFrom(track)),
                      Positioned(bottom: 0, left: 8, child: Text(track.source!.trim())),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _imageFrom(NowPlayingTrack track) {
    if (track.hasImage)
      return Image(
        key: Key(track.id),
        image: track.image!,
        width: 200,
        height: 200,
        fit: BoxFit.contain,
      );

    if (track.isResolvingImage) {
      return SizedBox(
        width: 50.0,
        height: 50.0,
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
      );
    }

    return Text(
      'NO\nARTWORK\nFOUND',
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 24, color: Colors.white),
    );
  }

  Widget _iconFrom(NowPlayingTrack track) {
    if (track.hasIcon) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [const BoxShadow(blurRadius: 5, color: Colors.black)],
          shape: BoxShape.circle,
        ),
        child: Image(
          image: track.icon!,
          width: 25,
          height: 25,
          fit: BoxFit.contain,
          color: _fgColorFor(track),
          colorBlendMode: BlendMode.srcIn,
        ),
      );
    }
    return Container();
  }

  Color _fgColorFor(NowPlayingTrack track) {
    switch (track.source) {
      case "com.apple.music":
        return Colors.blue;
      case "com.hughesmedia.big_finish":
        return Colors.red;
      case "com.spotify.music":
        return Colors.green;
      default:
        return Colors.purpleAccent;
    }
  }

  Widget _buildContent() {
    // if (_mediaInfo.title == "Not Playing") {
    //   return Center(
    //     child: Column(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: [
    //         Icon(Icons.music_off, size: 80, color: Colors.white.withOpacity(0.5)),
    //         const SizedBox(height: 24),
    //         Text(
    //           'Nothing Playing',
    //           style: TextStyle(
    //             color: Colors.white.withOpacity(0.7),
    //             fontSize: 20,
    //             fontWeight: FontWeight.w500,
    //           ),
    //         ),
    //         const SizedBox(height: 16),
    //         Text(
    //           'Start playing music to see it here',
    //           style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
    //         ),
    //       ],
    //     ),
    //   );
    // }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Album Artwork
            _buildArtwork(),

            const SizedBox(height: 40),

            // Track Info
            _buildTrackInfo(),

            const SizedBox(height: 32),

            // Progress Bar
            _buildProgressBar(),

            const SizedBox(height: 32),

            // Playback State
            _buildPlaybackState(),

            const SizedBox(height: 24),

            // Duration Info
            _buildDurationInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildArtwork() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: HSLColor.fromAHSL(0.4, 260, 0.7, 0.4).toColor(),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _mediaInfo?.album != null
            ? Container(
                decoration: BoxDecoration(
                  image: DecorationImage(image: _mediaInfo!.image!, fit: BoxFit.cover),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      HSLColor.fromAHSL(1.0, 280, 0.7, 0.5).toColor(),
                      HSLColor.fromAHSL(1.0, 240, 0.8, 0.4).toColor(),
                    ],
                  ),
                ),
                child: const Center(child: Icon(Icons.music_note, size: 100, color: Colors.white)),
              ),
      ),
    );
  }

  Widget _buildTrackInfo() {
    return Column(
      children: [
        Text(
          _mediaInfo?.title ?? "",
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          _mediaInfo?.artist ?? "",
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final progress = _mediaInfo!.duration.inSeconds > 0
        ? (_mediaInfo!.progress.inSeconds / _mediaInfo!.duration.inSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        Container(
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.white.withOpacity(0.3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_mediaInfo!.progress.inSeconds),
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
              ),
              Text(
                _formatDuration(_mediaInfo!.duration.inSeconds),
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _mediaInfo?.isPlaying ?? false ? Icons.play_arrow : Icons.pause,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            _mediaInfo?.isPlaying ?? false ? 'Playing' : 'Paused',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            'Duration',
            _formatDuration(_mediaInfo!.duration.inSeconds),
            Icons.timer_outlined,
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
          _buildInfoItem(
            'Speed',
            '${(_mediaInfo!.progress.inSeconds / _mediaInfo!.duration.inSeconds).toStringAsFixed(1)}x',
            Icons.speed,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.6), size: 20),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class TrackProgressIndicator extends StatefulWidget {
  final NowPlayingTrack track;

  TrackProgressIndicator(this.track);

  @override
  _TrackProgressIndicatorState createState() => _TrackProgressIndicatorState();
}

class _TrackProgressIndicatorState extends State<TrackProgressIndicator> {
  late Timer _timer;

  @override
  void initState() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.track.progress.toString();
    final countdown = widget.track.duration - widget.track.progress + const Duration(seconds: 1);
    return Column(children: [Text(progress), Text(countdown.toString())]);
  }
}
