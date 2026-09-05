import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tien_len/l10n/app_localizations.dart';

import '../game/game_engine.dart';
import '../models/coin_statistics.dart';
import '../preferences_scope.dart';
import '../services/preferences_service.dart';
import '../services/saved_game_service.dart';

class StakeSelector extends StatefulWidget {
  const StakeSelector({super.key, required this.balance});
  final int balance;

  @override
  State<StakeSelector> createState() => _StakeSelectorState();
}

class _StakeSelectorState extends State<StakeSelector> {
  int _stake = 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.gameStake),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.coinBalanceAmount(widget.balance)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            for (final stake in CoinEconomy.stakes)
              ChoiceChip(
                key: ValueKey('stake-$stake'),
                label: Text(stake == 0 ? loc.free : '$stake'),
                selected: _stake == stake,
                onSelected: stake == 0 || stake <= widget.balance
                    ? (_) => setState(() => _stake = stake) : null,
              ),
          ]),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.cancel)),
        FilledButton(
          key: const ValueKey('start-staked-game'),
          onPressed: () => Navigator.pop(context, _stake),
          child: Text(loc.startGame),
        ),
      ],
    );
  }
}

/// Select first, then create and commit exactly once. Cancelling has no effect.
Future<SavedGame?> selectNewGame(BuildContext context) async {
  final preferences = PreferencesScope.maybeOf(context);
  final service = PreferencesService(await SharedPreferences.getInstance());
  if (!context.mounted) return null;
  final stake = await showDialog<int>(
    context: context,
    builder: (_) => StakeSelector(balance: service.loadCoins().balance),
  );
  if (stake == null || !context.mounted) return null;
  final engine = GameEngine()..startNewGame();
  if (preferences != null) engine.difficulty = preferences.difficulty;
  final committed = await (preferences?.commitStake(engine.gameId, stake) ??
      service.commitStake(engine.gameId, stake));
  if (!committed) return null;
  final saved = SavedGame.capture(engine, engine.players.first.hand, stake: stake);
  await (await SavedGameService.open()).save(saved);
  return saved;
}
