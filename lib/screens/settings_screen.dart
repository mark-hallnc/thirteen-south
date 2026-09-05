import 'package:flutter/material.dart';
import 'package:tien_len/l10n/app_localizations.dart';

import '../ai/ai_difficulty.dart';
import '../locale_controller_scope.dart';
import '../preferences_scope.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final controller = LocaleControllerScope.of(context);
    final preferences = PreferencesScope.of(context);
    final selected = controller.locale?.languageCode ?? 'system';

    return Scaffold(
      appBar: AppBar(title: Text(loc.settings)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              loc.language,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Card(
              child: RadioGroup<String>(
                groupValue: selected,
                onChanged: (value) {
                  if (value == 'system') {
                    controller.setLocale(null);
                  } else if (value != null) {
                    controller.setLocale(Locale(value));
                  }
                },
                child: Column(
                  children: [
                    RadioListTile<String>(
                      key: const ValueKey('language-system'),
                      value: 'system',
                      title: Text(loc.systemDefault),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    RadioListTile<String>(
                      key: const ValueKey('language-en'),
                      value: 'en',
                      title: Text(loc.english),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    RadioListTile<String>(
                      key: const ValueKey('language-vi'),
                      value: 'vi',
                      title: Text(loc.vietnamese),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loc.difficulty,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Card(
              child: RadioGroup<AiDifficulty>(
                groupValue: preferences.difficulty,
                onChanged: (value) {
                  if (value != null) preferences.setDifficulty(value);
                },
                child: Column(
                  children: [
                    _DifficultyTile(
                      difficulty: AiDifficulty.easy,
                      title: loc.easy,
                      description: loc.easyDescription,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _DifficultyTile(
                      difficulty: AiDifficulty.normal,
                      title: loc.normal,
                      description: loc.normalDescription,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _DifficultyTile(
                      difficulty: AiDifficulty.hard,
                      title: loc.hard,
                      description: loc.hardDescription,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loc.sound,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                key: const ValueKey('sounds-enabled'),
                title: Text(loc.soundEffects),
                subtitle: Text(loc.soundEffectsDescription),
                value: preferences.soundsEnabled,
                onChanged: preferences.setSoundsEnabled,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loc.statistics,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Column(
                  children: [
                    _StatisticRow(
                      label: loc.gamesPlayed,
                      value: '${preferences.statistics.gamesPlayed}',
                    ),
                    _StatisticRow(label: loc.coinBalance, value: '${preferences.coinBalance}'),
                    _StatisticRow(label: loc.highestBalance, value: '${preferences.highestCoinBalance}'),
                    _StatisticRow(label: loc.coinsWon, value: '${preferences.coinsWon}'),
                    _StatisticRow(label: loc.coinsLost, value: '${preferences.coinsLost}'),
                    _StatisticRow(
                      label: loc.wins,
                      value: '${preferences.statistics.wins}',
                    ),
                    _StatisticRow(
                      label: loc.losses,
                      value: '${preferences.statistics.losses}',
                    ),
                    _StatisticRow(
                      label: loc.winRate,
                      value:
                          '${(preferences.statistics.winRate * 100).round()}%',
                    ),
                    _StatisticRow(
                      label: loc.currentStreak,
                      value: '${preferences.statistics.currentWinStreak}',
                    ),
                    _StatisticRow(
                      label: loc.bestStreak,
                      value: '${preferences.statistics.bestWinStreak}',
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: const ValueKey('reset-statistics-button'),
                        onPressed: () => _confirmReset(context, preferences),
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: Text(loc.resetStatistics),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    PreferencesScope preferences,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.resetStatisticsTitle),
        content: Text(loc.resetStatisticsMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.reset),
          ),
        ],
      ),
    );
    if (confirmed == true) await preferences.resetStatistics();
  }
}

class _DifficultyTile extends StatelessWidget {
  const _DifficultyTile({
    required this.difficulty,
    required this.title,
    required this.description,
  });

  final AiDifficulty difficulty;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => RadioListTile<AiDifficulty>(
    key: ValueKey('difficulty-${difficulty.name}'),
    value: difficulty,
    title: Text(title),
    subtitle: Text(description),
  );
}

class _StatisticRow extends StatelessWidget {
  const _StatisticRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
