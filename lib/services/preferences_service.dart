import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../ai/ai_difficulty.dart';
import '../models/game_statistics.dart';
import '../models/coin_statistics.dart';

class PreferencesService {
  PreferencesService(this._preferences);

  final SharedPreferences _preferences;

  // One document makes balance changes and their game-ID guards a single write.
  static const coinStateKey = 'coin_state';
  static Future<void> _coinWrites = Future<void>.value();

  Map<String, dynamic> _coinState() {
    final saved = _preferences.getString(coinStateKey);
    return saved == null
        ? <String, dynamic>{}
        : jsonDecode(saved) as Map<String, dynamic>;
  }

  CoinStatistics loadCoins() => CoinStatistics.fromJson(_coinState());

  Future<T> _coinTransaction<T>(Future<T> Function() action) {
    final operation = _coinWrites.then((_) => action());
    _coinWrites = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return operation;
  }

  bool isPracticeGame(String gameId) =>
      (_coinState()['games'] as Map?)?[gameId]?['practice'] == true;

  Future<bool> commitStake(String gameId, int stake, {bool practice = false}) =>
      _coinTransaction(() async {
        if (!CoinEconomy.stakes.contains(stake)) {
          throw ArgumentError.value(stake);
        }
        if (practice && stake != 0) throw ArgumentError.value(stake);
        final state = _coinState();
        final games = Map<String, dynamic>.from(state['games'] as Map? ?? {});
        final existing = games[gameId] as Map?;
        if (existing != null) {
          return existing['stake'] == stake &&
              (existing['practice'] == true) == practice;
        }
        final coins = CoinStatistics.fromJson(state);
        if (stake > coins.balance) return false;
        games[gameId] = {
          'stake': stake,
          'settled': false,
          if (practice) 'practice': true,
        };
        final updated = CoinStatistics(
          balance: coins.balance - stake,
          highestBalance: coins.highestBalance,
          won: coins.won,
          lost: coins.lost,
        );
        if (!await _preferences.setString(
          coinStateKey,
          jsonEncode({...updated.toJson(), 'games': games}),
        )) {
          throw StateError('Could not save coin commitment');
        }
        return true;
      });

  Future<CoinStatistics> settleGame({
    required String gameId,
    required int stake,
    required bool humanWon,
  }) => _coinTransaction(() async {
    final state = _coinState();
    final games = Map<String, dynamic>.from(state['games'] as Map? ?? {});
    final existing = games[gameId] as Map?;
    final coins = CoinStatistics.fromJson(state);
    if (existing?['settled'] == true) return coins;
    // Older saved games have no commitment metadata and are Free Play.
    if (!CoinEconomy.stakes.contains(stake) ||
        (stake != 0 && existing == null) ||
        (existing != null && existing['stake'] != stake)) {
      throw StateError('Stake was not committed for this game');
    }
    // The ledger distinguishes Practice from older zero-stake Free Play saves.
    final practice = existing?['practice'] == true;
    final balance =
        coins.balance + (practice ? 0 : CoinEconomy.payout(stake, humanWon));
    final net = practice ? 0 : CoinEconomy.netChange(stake, humanWon);
    final updated = practice
        ? coins
        : CoinStatistics(
            balance: balance,
            highestBalance: math.max(coins.highestBalance, balance),
            won: coins.won + math.max(0, net),
            lost: coins.lost + (humanWon ? 0 : stake),
          );
    games[gameId] = {
      'stake': stake,
      'settled': true,
      if (practice) 'practice': true,
    };
    if (!await _preferences.setString(
      coinStateKey,
      jsonEncode({...updated.toJson(), 'games': games}),
    )) {
      throw StateError('Could not save coin settlement');
    }
    return updated;
  });

  static const soundsEnabledKey = 'sounds_enabled';

  bool loadSoundsEnabled() => _preferences.getBool(soundsEnabledKey) ?? true;

  Future<void> saveSoundsEnabled(bool enabled) =>
      _preferences.setBool(soundsEnabledKey, enabled);

  static const difficultyKey = 'ai_difficulty';
  static const gamesPlayedKey = 'games_played';
  static const winsKey = 'wins';
  static const lossesKey = 'losses';
  static const currentWinStreakKey = 'current_win_streak';
  static const bestWinStreakKey = 'best_win_streak';
  static const lastRecordedGameKey = 'last_recorded_game';

  AiDifficulty loadDifficulty() =>
      AiDifficultyPersistence.fromSaved(_preferences.getString(difficultyKey));

  Future<void> saveDifficulty(AiDifficulty difficulty) =>
      _preferences.setString(difficultyKey, difficulty.name);

  GameStatistics loadStatistics() => GameStatistics(
    gamesPlayed: _nonNegativeInt(gamesPlayedKey),
    wins: _nonNegativeInt(winsKey),
    losses: _nonNegativeInt(lossesKey),
    currentWinStreak: _nonNegativeInt(currentWinStreakKey),
    bestWinStreak: _nonNegativeInt(bestWinStreakKey),
  );

  Future<GameStatistics> recordGameResult({
    required String gameId,
    required bool humanWon,
  }) async {
    final current = loadStatistics();
    if (_preferences.getString(lastRecordedGameKey) == gameId) return current;
    final updated = current.recordResult(humanWon: humanWon);
    await _saveStatistics(updated);
    await _preferences.setString(lastRecordedGameKey, gameId);
    return updated;
  }

  Future<GameStatistics> resetStatistics() async {
    const reset = GameStatistics();
    await _saveStatistics(reset);
    await _preferences.remove(lastRecordedGameKey);
    return reset;
  }

  int _nonNegativeInt(String key) {
    final value = _preferences.getInt(key) ?? 0;
    return value < 0 ? 0 : value;
  }

  Future<void> _saveStatistics(GameStatistics statistics) async {
    await Future.wait([
      _preferences.setInt(gamesPlayedKey, statistics.gamesPlayed),
      _preferences.setInt(winsKey, statistics.wins),
      _preferences.setInt(lossesKey, statistics.losses),
      _preferences.setInt(currentWinStreakKey, statistics.currentWinStreak),
      _preferences.setInt(bestWinStreakKey, statistics.bestWinStreak),
    ]);
  }
}
