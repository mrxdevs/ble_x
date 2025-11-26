abstract class MediaControllerRepository {
  // Media control methods
  Future<void> play();
  Future<void> pause();
  Future<void> next();
  Future<void> previous();
  Future<void> setVolume(double volume);
  Future<void> setShuffle(bool shuffle);
  Future<void> setRepeat(bool repeat);
}
