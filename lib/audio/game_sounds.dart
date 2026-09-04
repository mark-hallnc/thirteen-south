import 'package:audioplayers/audioplayers.dart';

class GameSounds {
  bool _enabled = true;
  bool get enabled => _enabled;

  void setEnabled(bool enabled) => _enabled = enabled;

  final AudioPlayer _cardSelectedPlayer = AudioPlayer();
  final AudioPlayer _cardPlacedPlayer = AudioPlayer();
  final AudioPlayer _gameWinPlayer = AudioPlayer();
  final AudioPlayer _gameLostPlayer = AudioPlayer();
  final AudioPlayer _invalidPlayPlayer = AudioPlayer();

  Future<void> playCardSelected() =>
      _play(_cardSelectedPlayer, 'audio/card_selected.mp3');

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
    await Future.wait([
      _cardSelectedPlayer.dispose(),
      _cardPlacedPlayer.dispose(),
      _gameWinPlayer.dispose(),
      _gameLostPlayer.dispose(),
      _invalidPlayPlayer.dispose(),
    ]);
  }
}
