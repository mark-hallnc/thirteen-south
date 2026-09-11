import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tien_len/l10n/app_localizations.dart';

import '../game/game_engine.dart';
import '../ai/ai_difficulty.dart';
import '../game/move_validator.dart';
import '../audio/game_sounds.dart';
import '../models/player.dart';
import '../models/playing_card.dart';
import '../preferences_scope.dart';
import '../services/saved_game_service.dart';
import '../services/preferences_service.dart';
import '../models/coin_statistics.dart';
import '../widgets/stake_selector.dart';
import '../widgets/wallet_pill.dart';
import '../widgets/stake_pill.dart';
import '../widgets/game_table_widgets.dart';
import '../widgets/player_hand.dart';
import 'settings_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.engine,
    this.initialHumanCardOrder,
    this.stake = 0,
    this.stakeCommitted = true,
    this.aiDelay = const Duration(milliseconds: 550),
  });

  final GameEngine? engine;
  final int stake;
  final bool stakeCommitted;
  final List<PlayingCard>? initialHumanCardOrder;
  final Duration aiDelay;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  final Future<SavedGameService> _saveService = SavedGameService.open();
  AiDifficulty? _lastPreferenceDifficulty;
  late int _stake;
  late bool _stakeCommitted;
  CoinStatistics? _resultCoins;

  Future<void> _saveGame() async {
    final snapshot = SavedGame.capture(
      _engine,
      _humanCardOrder,
      stake: _stake,
      stakeCommitted: _stakeCommitted,
    );
    final winner = snapshot.engine.state.winner;
    if (winner != null) {
      final preferences = mounted ? PreferencesScope.maybeOf(context) : null;
      final coins = preferences != null
          ? await preferences.settleGame(
              snapshot.engine.gameId,
              snapshot.stake,
              winner.isHuman,
            )
          : await (PreferencesService(
              await SharedPreferences.getInstance(),
            )).settleGame(
              gameId: snapshot.engine.gameId,
              stake: snapshot.stake,
              humanWon: winner.isHuman,
            );
      if (mounted && _engine.gameId == snapshot.engine.gameId) {
        setState(() => _resultCoins = coins);
      }
    }
    await (await _saveService).save(snapshot);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(_saveGame());
    }
  }

  late GameEngine _engine;
  final Set<PlayingCard> _selected = <PlayingCard>{};
  final GameSounds _sounds = GameSounds();
  bool _leaveDialogOpen = false;
  bool _newGameDialogOpen = false;

  Future<void> _confirmLeave() async {
    if (_leaveDialogOpen) return;
    _leaveDialogOpen = true;
    final loc = AppLocalizations.of(context)!;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(loc.leaveGameTitle),
          content: Text(loc.leaveGameMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(loc.leave),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      await _saveGame();
      if (!mounted) return;
      // The dialog has closed. Pop this route directly, bypassing maybePop's
      // active-game veto; the successful callback returns without prompting.
      if (ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pop();
      }
    } finally {
      _leaveDialogOpen = false;
    }
  }

  List<PlayingCard> _humanCardOrder = [];
  int _aiRun = 0;
  Timer? _aiTimer;
  bool _resultRecorded = false;
  bool _resultSoundPlayed = false;

  @override
  void initState() {
    super.initState();
    _engine = widget.engine ?? (GameEngine()..startNewGame());
    _stake = widget.stake;
    _stakeCommitted = widget.stakeCommitted;
    _humanCardOrder =
        (widget.initialHumanCardOrder ?? _engine.players.first.hand)
            .toSet()
            .toList();
    _syncHumanCardOrder();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_saveGame());
      _runAiTurns();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _aiRun++;
    _aiTimer?.cancel();
    unawaited(_sounds.dispose());
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final preferences = PreferencesScope.maybeOf(context);
    _sounds.setEnabled(preferences?.soundsEnabled ?? true);
    if (preferences != null) {
      final preserveRestoredDifficulty =
          _lastPreferenceDifficulty == null &&
          widget.initialHumanCardOrder != null;
      if (!preserveRestoredDifficulty &&
          _lastPreferenceDifficulty != preferences.difficulty &&
          _engine.difficulty != preferences.difficulty) {
        _engine.difficulty = preferences.difficulty;
        unawaited(_saveGame());
      }
      _lastPreferenceDifficulty = preferences.difficulty;
    }
    if (_engine.state.winner != null && !_resultRecorded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _recordResult());
    }
  }

  void _runAiTurns() {
    if (_aiTimer?.isActive ?? false) return;
    if (!mounted ||
        !_engine.state.isActive ||
        _engine.state.currentPlayer.isHuman) {
      return;
    }
    final run = ++_aiRun;
    _aiTimer = Timer(widget.aiDelay, () {
      _aiTimer = null;
      if (!mounted || run != _aiRun || !_engine.state.isActive) return;
      final aiPlayer = _engine.state.currentPlayer;
      final cardsBefore = aiPlayer.cardsRemaining;
      MoveValidationResult? result;
      setState(() => result = _engine.performAiTurn());
      if (result!.isValid) unawaited(_saveGame());
      if (result!.isValid && aiPlayer.cardsRemaining < cardsBefore) {
        unawaited(_sounds.playCardPlaced());
      }
      _recordResult();
      _runAiTurns();
    });
  }

  void _toggleCard(PlayingCard card) {
    setState(() {
      _selected.contains(card) ? _selected.remove(card) : _selected.add(card);
    });
    unawaited(_sounds.playCardSelected());
  }

  void _syncHumanCardOrder() {
    final hand = _engine.players.first.hand;
    _humanCardOrder.removeWhere((card) => !hand.contains(card));
    for (final card in hand) {
      if (!_humanCardOrder.contains(card)) _humanCardOrder.add(card);
    }
  }

  // newIndex is the final index after removing the dragged card.
  void _reorderHand(int oldIndex, int newIndex) {
    setState(() {
      final card = _humanCardOrder.removeAt(oldIndex);
      _humanCardOrder.insert(newIndex, card);
    });
    unawaited(_saveGame());
  }

  void _play() {
    final result = _engine.playCards(
      _engine.players.first.id,
      _selected.toList(),
    );
    if (result.isValid) {
      unawaited(_sounds.playCardPlaced());
      setState(() {
        _selected.clear();
        _syncHumanCardOrder();
      });
      unawaited(_saveGame());
      _recordResult();
      _runAiTurns();
    } else {
      if (_selected.isNotEmpty) unawaited(_sounds.playInvalidPlay());
      _showError(result.reason);
    }
  }

  void _pass() {
    final result = _engine.pass(_engine.players.first.id);
    if (result.isValid) {
      setState(_selected.clear);
      unawaited(_saveGame());
      _runAiTurns();
    } else {
      _showError(result.reason);
    }
  }

  Future<void> _newGame() async {
    if (_newGameDialogOpen) return;
    if (_engine.state.isActive) {
      _newGameDialogOpen = true;
      final loc = AppLocalizations.of(context)!;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(loc.startNewGameTitle),
          content: Text(loc.replaceSavedGameMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(loc.startNewGame),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) {
        _newGameDialogOpen = false;
        return;
      }
    }
    _newGameDialogOpen = true;
    final game = await selectNewGame(context);
    _newGameDialogOpen = false;
    if (!mounted || game == null) return;
    _aiRun++;
    _aiTimer?.cancel();
    _aiTimer = null;
    setState(() {
      _selected.clear();
      _resultRecorded = false;
      _resultSoundPlayed = false;
      _engine = game.engine;
      _stake = game.stake;
      _stakeCommitted = game.stakeCommitted;
      _resultCoins = null;
      _humanCardOrder = List.of(_engine.players.first.hand);
    });
    unawaited(_saveGame());
    _runAiTurns();
  }

  void _recordResult() {
    final winner = _engine.state.winner;
    if (winner == null || _resultRecorded) return;
    unawaited(_saveGame());
    if (!_resultSoundPlayed) {
      _resultSoundPlayed = true;
      unawaited(
        winner.isHuman ? _sounds.playGameWin() : _sounds.playGameLost(),
      );
    }
    _resultRecorded = true;
    final preferences = PreferencesScope.maybeOf(context);
    if (preferences != null) {
      unawaited(preferences.recordGameResult(_engine.gameId, winner.isHuman));
    }
  }

  void _showError(MoveValidationReason? reason) {
    final loc = AppLocalizations.of(context)!;
    final message = switch (reason) {
      MoveValidationReason.mustIncludeThreeSpades => loc.mustIncludeThreeSpades,
      MoveValidationReason.doesNotBeat => loc.moveDoesNotBeat,
      MoveValidationReason.cannotPassWhileLeading => loc.cannotPassWhileLeading,
      MoveValidationReason.notYourTurn => loc.notYourTurn,
      MoveValidationReason.cardNotInHand => loc.cardNotInHand,
      _ => loc.invalidMove,
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _name(Player player, AppLocalizations loc) {
    if (player.isHuman) return loc.you;
    return loc.computer(_engine.players.indexOf(player));
  }

  String? _coinResultText(AppLocalizations loc, bool humanWon) {
    if (!humanWon) return null;
    final coins = _resultCoins;
    if (coins == null) return null;
    final net = CoinEconomy.netChange(_stake, humanWon);
    final outcome = net == 0
        ? loc.noCoinChange
        : loc.coinAmount('${net > 0 ? '+' : ''}$net');
    return '$outcome\n${loc.coinBalanceAmount(coins.balance)}';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final state = _engine.state;
    final human = _engine.players.first;
    final humanTurn = state.isActive && state.currentPlayer == human;

    return PopScope<void>(
      canPop: !state.isActive,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_confirmLeave());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.appTitle),
          bottom: WalletStatusRow(
            trailing: StakePill(
              key: const ValueKey('game-stake'),
              stake: _stake,
            ),
          ),
          actions: [
            IconButton(
              tooltip: loc.settings,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              ),
              icon: const Icon(Icons.tune_rounded),
            ),
            IconButton(
              tooltip: loc.newGame,
              onPressed: _newGame,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: _TableSurface(
                      engine: _engine,
                      nameFor: (player) => _name(player, loc),
                    ),
                  ),
                  Container(
                    color: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: humanTurn
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            humanTurn
                                ? loc.yourTurn
                                : loc.playerTurn(
                                    _name(state.currentPlayer, loc),
                                  ),
                            key: const ValueKey('turn-label'),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: humanTurn
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                key: const ValueKey('pass-button'),
                                onPressed:
                                    humanTurn && state.currentTableMove != null
                                    ? _pass
                                    : null,
                                child: Text(loc.pass),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                key: const ValueKey('play-button'),
                                onPressed: humanTurn && _selected.isNotEmpty
                                    ? _play
                                    : null,
                                child: Text(loc.play),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 3),
                    child: PlayerHand(
                      cards: _humanCardOrder,
                      onReorder: state.isActive ? _reorderHand : null,
                      selectedCards: _selected,
                      onCardTap: _toggleCard,
                      enabled: humanTurn,
                    ),
                  ),
                ],
              ),
              if (state.winner != null)
                Positioned.fill(
                  child: _GameOverOverlay(
                    title: loc.gameOver,
                    message: state.winner!.isHuman
                        ? loc.youWin
                        : loc.playerWins(_name(state.winner!, loc)),
                    buttonLabel: loc.newGame,
                    coinResult: _coinResultText(loc, state.winner!.isHuman),
                    onNewGame: _newGame,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableSurface extends StatelessWidget {
  const _TableSurface({required this.engine, required this.nameFor});

  final GameEngine engine;
  final String Function(Player player) nameFor;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final state = engine.state;
    final opponents = engine.players.skip(1).toList();

    OpponentPanel opponent(Player player, OpponentPosition position) {
      return OpponentPanel(
        key: ValueKey('opponent-${player.id}-${position.name}'),
        opponentId: player.id,
        name: nameFor(player),
        cardCount: player.cardsRemaining,
        cardsLabel: loc.cards,
        passedLabel: loc.passed,
        isPassed: state.hasPassed(player.id),
        isActive: state.isActive && state.currentPlayer == player,
        position: position,
      );
    }

    return Container(
      key: const ValueKey('game-table'),
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF12382D), Color(0xFF194A3B), Color(0xFF103127)],
          stops: [0, .48, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -.1),
                    radius: .9,
                    colors: [Color(0x242F8062), Color(0x002F8062)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: SizedBox(
              height: 145,
              child: opponent(opponents[1], OpponentPosition.top),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: SizedBox(
                width: 80,
                height: 225,
                child: opponent(opponents[0], OpponentPosition.left),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: FractionallySizedBox(
              widthFactor: .60,
              child: TableMoveArea(
                cards: state.currentTableMove?.cards ?? const <PlayingCard>[],
                emptyLabel: loc.leadAPlay,
                ownerLabel: state.currentMovePlayer == null
                    ? null
                    : loc.lead(nameFor(state.currentMovePlayer!)),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 80,
                height: 225,
                child: opponent(opponents[2], OpponentPosition.right),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.title,
    required this.message,
    required this.buttonLabel,
    this.coinResult,
    required this.onNewGame,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final String? coinResult;
  final VoidCallback onNewGame;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: .55),
      child: Center(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 220),
          tween: Tween(begin: .96, end: 1),
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Card(
            margin: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.style_rounded,
                      size: 38,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (coinResult != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        coinResult!,
                        key: const ValueKey('coin-result'),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onNewGame,
                        child: Text(buttonLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
