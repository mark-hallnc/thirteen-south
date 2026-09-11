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
    final theme = Theme.of(context);
    Widget option(int stake, double width) => SizedBox(
      width: width,
      child: ChoiceChip(
        key: ValueKey('stake-$stake'),
        label: Center(heightFactor: 1, child: Text(loc.freePlay)),
        labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        showCheckmark: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        selectedColor: theme.colorScheme.primaryContainer,
        side: BorderSide(
          color: _stake == stake
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: _stake == stake ? 2 : 1,
        ),
        labelStyle: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: stake > widget.balance
              ? theme.colorScheme.onSurface.withValues(alpha: .38)
              : _stake == stake
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSurface,
        ),
        selected: _stake == stake,
        onSelected: stake == 0 || stake <= widget.balance
            ? (_) => setState(() => _stake = stake)
            : null,
      ),
    );
    final dialogWidth = (MediaQuery.sizeOf(context).width - 32)
        .clamp(0.0, 380.0)
        .toDouble();
    final optionWidth = ((dialogWidth - 48 - 10) / 2)
        .clamp(0.0, 156.0)
        .toDouble();
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SizedBox(
          width: dialogWidth,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/coins/single_coin.png',
                  width: 56,
                  height: 56,
                  excludeFromSemantics: true,
                ),
                const SizedBox(height: 12),
                Text(
                  loc.playFor,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                option(0, double.infinity),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final stake in CoinEconomy.stakes.skip(1))
                      StakeCoinOption(
                        key: ValueKey('stake-$stake'),
                        stake: stake,
                        width: optionWidth,
                        selected: _stake == stake,
                        enabled: stake <= widget.balance,
                        onSelected: () => setState(() => _stake = stake),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(loc.cancel, textAlign: TextAlign.center),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const ValueKey('start-staked-game'),
                        onPressed: () => Navigator.pop(context, _stake),
                        child: Text(loc.startGame, textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StakeCoinOption extends StatelessWidget {
  const StakeCoinOption({
    super.key,
    required this.stake,
    required this.width,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final int stake;
  final double width;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final diameter = (width - 12).clamp(48.0, 76.0).toDouble();
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: AppLocalizations.of(context)!.coinAmount(stake),
      child: SizedBox(
        width: width,
        height: 88,
        child: Center(
          child: AnimatedScale(
            scale: selected ? 1.06 : 1,
            duration: const Duration(milliseconds: 140),
            child: Opacity(
              opacity: enabled ? 1 : .32,
              child: InkResponse(
                onTap: enabled ? onSelected : null,
                enableFeedback: false,
                customBorder: const CircleBorder(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: diameter,
                  height: diameter,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? colors.primary : colors.outlineVariant,
                      width: selected ? 2.5 : 1,
                    ),
                    boxShadow: [
                      if (selected)
                        BoxShadow(
                          color: colors.primary.withValues(alpha: .16),
                          blurRadius: 10,
                        ),
                    ],
                  ),
                  child: ExcludeSemantics(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: Image.asset('assets/coins/single_coin.png'),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBE4A5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$stake',
                            style: const TextStyle(
                              color: Color(0xFF382710),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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
  final committed =
      await (preferences?.commitStake(engine.gameId, stake) ??
          service.commitStake(engine.gameId, stake));
  if (!committed) return null;
  final saved = SavedGame.capture(
    engine,
    engine.players.first.hand,
    stake: stake,
  );
  await (await SavedGameService.open()).save(saved);
  return saved;
}
