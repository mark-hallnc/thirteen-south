import 'package:audioplayers/audioplayers.dart';

class GameSounds {
  GameSounds({AudioPlayer? cardSelectedPlayer})
    : _cardSelectedPlayer = cardSelectedPlayer ?? AudioPlayer() {
    _selectionReady = _prepareSelection();
  }

  static const selectionPlaybackRate = 1.25;
  static const selectionPlayerMode = PlayerMode.lowLatency;
  late final Future<bool> _selectionReady;
  bool _disposed = false;
  bool _enabled = true;
  bool get enabled => _enabled;

  void setEnabled(bool enabled) => _enabled = enabled;

  final AudioPlayer _cardSelectedPlayer;
  final AudioPlayer _cardPlacedPlayer = AudioPlayer();
  final AudioPlayer _gameWinPlayer = AudioPlayer();
  final AudioPlayer _gameLostPlayer = AudioPlayer();
  final AudioPlayer _invalidPlayPlayer = AudioPlayer();

  Future<bool> _prepareSelection() async {
    try {
      await _cardSelectedPlayer.setPlayerMode(selectionPlayerMode);
      if (_disposed) return false;
      await _cardSelectedPlayer.setReleaseMode(ReleaseMode.stop);
      if (_disposed) return false;
      await _cardSelectedPlayer.setPlaybackRate(selectionPlaybackRate);
      if (_disposed) return false;
      // Short UI effects are better as WAV/OGG. Trimming leading silence from
      // this MP3 would further improve response; preload it once in the meantime.
      await _cardSelectedPlayer.setSource(
        AssetSource('audio/card_selected.mp3'),
      );
      return !_disposed;
    } catch (_) {
      return false;
    }
  }

  Future<void> playCardSelected() async {
    if (!_enabled || _disposed) return;
    if (!await _selectionReady || !_enabled || _disposed) return;
    try {
      await _cardSelectedPlayer.stop();
      if (!_enabled || _disposed) return;
      await _cardSelectedPlayer.resume();
    } catch (_) {
      // Sound effects must never interrupt gameplay.
    }
  }

  Future<void> playCardPlaced() =>
      _play(_cardPlacedPlayer, 'audio/card_placed.wav');

  Future<void> playGameWin() => _play(_gameWinPlayer, 'audio/game_win.wav');

  Future<void> playGameLost() => _play(_gameLostPlayer, 'audio/game_lost.wav');

  Future<void> playInvalidPlay() =>
      _play(_invalidPlayPlayer, 'audio/invalid_play.wav');

  Future<void> _play(AudioPlayer player, String assetPath) async {
    if (!_enabled) return;
    try {
      await player.play(AssetSource(assetPath));
    } catch (_) {
      // Sound effects must never interrupt gameplay.
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await Future.wait([
      _cardSelectedPlayer.dispose(),
      _cardPlacedPlayer.dispose(),
      _gameWinPlayer.dispose(),
      _gameLostPlayer.dispose(),
      _invalidPlayPlayer.dispose(),
    ]);
  }
}
