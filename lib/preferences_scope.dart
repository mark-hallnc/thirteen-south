import 'package:flutter/widgets.dart';

import 'ai/ai_difficulty.dart';
import 'models/game_statistics.dart';

class PreferencesScope extends InheritedWidget {
  const PreferencesScope({
    super.key,
    required this.difficulty,
    required this.statistics,
    required this.setDifficulty,
    required this.recordGameResult,
    required this.resetStatistics,
    required super.child,
  });

  final AiDifficulty difficulty;
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
      difficulty != oldWidget.difficulty || statistics != oldWidget.statistics;
}
