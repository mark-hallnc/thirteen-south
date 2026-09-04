import 'package:audioplayers/audioplayers.dart';

class GameSounds {
  final AudioPlayer _cardSelectedPlayer = AudioPlayer();
  final AudioPlayer _cardPlacedPlayer = AudioPlayer();

  Future<void> playCardSelected() =>
      _play(_cardSelectedPlayer, 'audio/card_selected.mp3');

  Future<void> playCardPlaced() =>
      _play(_cardPlacedPlayer, 'audio/card_placed.wav');

  Future<void> _play(AudioPlayer player, String assetPath) async {
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
    ]);
  }
}
