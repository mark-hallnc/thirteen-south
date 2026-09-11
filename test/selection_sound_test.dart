import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:tien_len/audio/game_sounds.dart';

class RecordingPlayer extends AudioPlayer {
  final calls = <String>[];
  @override
  Future<void> setPlayerMode(PlayerMode mode) async => calls.add('mode:$mode');
  @override
  Future<void> setReleaseMode(ReleaseMode mode) async =>
      calls.add('release:$mode');
  @override
  Future<void> setPlaybackRate(double rate) async => calls.add('rate:$rate');
  @override
  Future<void> setSource(Source source) async =>
      calls.add('source:${(source as AssetSource).path}');
  @override
  Future<void> stop() async => calls.add('stop');
  @override
  Future<void> resume() async => calls.add('resume');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    (_) async => null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global/events'),
    (_) async => null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (call) async {
      if (call.method == 'create') {
        final id = (call.arguments as Map)['playerId'];
        messenger.setMockMethodCallHandler(
          MethodChannel('xyz.luan/audioplayers/events/$id'),
          (_) async => null,
        );
      }
      return null;
    },
  );
  test(
    'selection is prepared once with low latency and moderate speed; mute prevents playback',
    () async {
      final player = RecordingPlayer();
      final sounds = GameSounds(cardSelectedPlayer: player);
      await sounds.playCardSelected();
      expect(player.calls, [
        'mode:${PlayerMode.lowLatency}',
        'release:${ReleaseMode.stop}',
        'rate:1.25',
        'source:audio/card_selected.mp3',
        'stop',
        'resume',
      ]);
      player.calls.clear();
      await sounds.playCardSelected();
      expect(player.calls, ['stop', 'resume']);
      player.calls.clear();
      sounds.setEnabled(false);
      await sounds.playCardSelected();
      await sounds.playCardPlaced();
      await sounds.playInvalidPlay();
      await sounds.playGameWin();
      await sounds.playGameLost();
      expect(player.calls, isEmpty);
      await sounds.dispose();
    },
  );
}
