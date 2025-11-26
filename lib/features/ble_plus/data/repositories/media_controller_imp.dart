import 'package:ble_x/features/ble_plus/domain/repository/media_controller_repository.dart';
import 'package:volume_controller/volume_controller.dart';

class MediaControllerImp implements MediaControllerRepository {
  @override
  Future<void> play() {
    return Future.value();
  }

  @override
  Future<void> pause() {
    return Future.value();
  }

  @override
  Future<void> next() {
    return Future.value();
  }

  @override
  Future<void> previous() {
    return Future.value();
  }

  @override
  Future<void> setVolume(double volume) async {
    // Get current volume
    await VolumeController.instance.setVolume(volume);
  }

  @override
  Future<void> setShuffle(bool shuffle) {
    return Future.value();
  }

  @override
  Future<void> setRepeat(bool repeat) {
    return Future.value();
  }
}
