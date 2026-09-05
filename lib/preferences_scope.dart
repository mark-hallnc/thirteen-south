import 'package:flutter/widgets.dart';

import 'ai/ai_difficulty.dart';
import 'models/game_statistics.dart';
import 'models/coin_statistics.dart';

class PreferencesScope extends InheritedWidget {
  const PreferencesScope({
    super.key,
    required this.difficulty,
    required this.soundsEnabled,
    required this.setSoundsEnabled,
    required this.statistics,
    required this.setDifficulty,
    required this.recordGameResult,
    required this.resetStatistics,
    required this.coins,
    required this.commitStake,
    required this.settleGame,
    required super.child,
  });

  final AiDifficulty difficulty;
  final CoinStatistics coins;
  int get coinBalance => coins.balance;
  int get highestCoinBalance => coins.highestBalance;
  int get coinsWon => coins.won;
  int get coinsLost => coins.lost;
  final Future<bool> Function(String gameId, int stake) commitStake;
  final Future<CoinStatistics> Function(String gameId, int stake, bool humanWon) settleGame;
  final bool soundsEnabled;
  final Future<void> Function(bool enabled) setSoundsEnabled;
  final GameStatistics statistics;
  final Future<void> Function(AiDifficulty difficulty) setDifficulty;
  final Future<void> Function(String gameId, bool humanWon) recordGameResult;
  final Future<void> Function() resetStatistics;

  static PreferencesScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PreferencesScope>()!;

  static PreferencesScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PreferencesScope>();

  @override
  bool updateShouldNotify(PreferencesScope oldWidget) =>
      coins != oldWidget.coins ||
      soundsEnabled != oldWidget.soundsEnabled ||
      difficulty != oldWidget.difficulty || statistics != oldWidget.statistics;
}
