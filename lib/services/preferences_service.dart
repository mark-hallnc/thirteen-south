import 'package:shared_preferences/shared_preferences.dart';

import '../ai/ai_difficulty.dart';
import '../models/game_statistics.dart';

class PreferencesService {
  PreferencesService(this._preferences);

  final SharedPreferences _preferences;

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
