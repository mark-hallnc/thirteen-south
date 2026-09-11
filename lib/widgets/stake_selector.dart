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
  bool _finished = false;

  void _choose(int? stake) {
    // Ignore a second tap while the dialog's closing transition is running.
    if (_finished) return;
    _finished = true;
    Navigator.pop(context, stake);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
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
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    key: const ValueKey('close-wager'),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => _choose(null),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
                Image.asset(
                  'assets/coins/single_coin.png',
                  width: 56,
                  height: 56,
                  excludeFromSemantics: true,
                ),
                const SizedBox(height: 12),
                Text(
                  loc.wager,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                if (widget.balance < 10) ...[
                  Text(
                    loc.notEnoughCoins,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    key: const ValueKey('earn-coins'),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (context) => Dialog(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(loc.comingSoon),
                              const SizedBox(height: 12),
                              IconButton(
                                key: const ValueKey('close-coming-soon'),
                                tooltip: MaterialLocalizations.of(
                                  context,
                                ).closeButtonTooltip,
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    child: Text(loc.earnCoins),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const ValueKey('practice-game'),
                    onPressed: () => _choose(0),
                    child: Text(loc.practice),
                  ),
                ] else
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
                          selected: false,
                          enabled: stake <= widget.balance,
                          onSelected: () => _choose(stake),
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
  final committed = await (stake == 0
      ? service.commitStake(engine.gameId, 0, practice: true)
      : preferences?.commitStake(engine.gameId, stake) ??
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
