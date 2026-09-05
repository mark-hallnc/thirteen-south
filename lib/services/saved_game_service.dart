import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_engine.dart';
import '../models/playing_card.dart';

class SavedGame {
  SavedGame({required this.engine, required List<PlayingCard> humanCardOrder})
    : humanCardOrder = List.unmodifiable(humanCardOrder);

  final GameEngine engine;
  final List<PlayingCard> humanCardOrder;

  factory SavedGame.capture(GameEngine engine, List<PlayingCard> order) =>
      SavedGame(
        engine: GameEngine.fromJson(engine.toJson()),
        humanCardOrder: order,
      );

  Map<String, dynamic> toJson() => {
    'version': 1,
    'engine': engine.toJson(),
    'humanCardOrder': humanCardOrder.map((card) => card.toJson()).toList(),
  };

  factory SavedGame.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) throw const FormatException('Unknown save version');
    final engine = GameEngine.fromJson(json['engine'] as Map<String, dynamic>);
    final order = (json['humanCardOrder'] as List)
        .map((card) => PlayingCard.fromJson(card as Map<String, dynamic>))
        .toList();
    final hand = engine.players.first.hand;
    if (order.length != hand.length || order.toSet().length != order.length ||
        !order.every(hand.contains)) {
      throw const FormatException('Invalid saved display order');
    }
    return SavedGame(engine: engine, humanCardOrder: order);
  }
}

class SavedGameService {
  SavedGameService(this._preferences);

  static const saveKey = 'active_game_state';
  final SharedPreferences _preferences;

  // Serialize writes across service instances. A late older write must never
  // replace a newer game or recreate a save cleared after a win.
  static Future<void> _pending = Future<void>.value();

  static Future<SavedGameService> open() async {
    await _pending;
    return SavedGameService(await SharedPreferences.getInstance());
  }

  Future<void> save(SavedGame game) {
    if (!game.engine.state.isActive || game.engine.state.winner != null) {
      return clear();
    }
    // Snapshot synchronously before the engine can advance again.
    final encoded = jsonEncode(game.toJson());
    return _enqueue(() async {
      await _preferences.setString(saveKey, encoded);
    });
  }

  SavedGame? load() {
    final encoded = _preferences.getString(saveKey);
    if (encoded == null) return null;
    try {
      final saved = SavedGame.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
      return saved.engine.state.isActive && saved.engine.state.winner == null
          ? saved : null;
    } on Object {
      // Corrupt or incompatible saves must not prevent opening Home.
      return null;
    }
  }

  bool hasSavedGame() => load() != null;

  Future<void> clear() => _enqueue(() async {
    await _preferences.remove(saveKey);
  });

  Future<void> _enqueue(Future<void> Function() write) {
    final operation = _pending.then((_) => write());
    _pending = operation.catchError((Object _) {});
    return operation;
  }
}
