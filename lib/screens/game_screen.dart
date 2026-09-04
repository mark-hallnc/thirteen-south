import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tien_len/l10n/app_localizations.dart';

import '../game/game_engine.dart';
import '../game/move_validator.dart';
import '../audio/game_sounds.dart';
import '../models/player.dart';
import '../models/playing_card.dart';
import '../preferences_scope.dart';
import '../widgets/game_table_widgets.dart';
import '../widgets/player_hand.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.engine,
    this.aiDelay = const Duration(milliseconds: 550),
  });

  final GameEngine? engine;
  final Duration aiDelay;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameEngine _engine;
  final Set<PlayingCard> _selected = <PlayingCard>{};
  final GameSounds _sounds = GameSounds();
  List<PlayingCard> _humanCardOrder = [];
  int _aiRun = 0;
  Timer? _aiTimer;
  bool _resultRecorded = false;
  bool _resultSoundPlayed = false;

  @override
  void initState() {
    super.initState();
    _engine = widget.engine ?? (GameEngine()..startNewGame());
    _humanCardOrder = List.of(_engine.players.first.hand);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAiTurns());
  }

  @override
  void dispose() {
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
    if (preferences != null) _engine.difficulty = preferences.difficulty;
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
      _runAiTurns();
    } else {
      _showError(result.reason);
    }
  }

  void _newGame() {
    _aiRun++;
    _aiTimer?.cancel();
    _aiTimer = null;
    setState(() {
      _selected.clear();
      _resultRecorded = false;
      _resultSoundPlayed = false;
      _engine.startNewGame();
      _humanCardOrder = List.of(_engine.players.first.hand);
    });
    _runAiTurns();
  }

  void _recordResult() {
    final winner = _engine.state.winner;
    if (winner == null || _resultRecorded) return;
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final state = _engine.state;
    final human = _engine.players.first;
    final humanTurn = state.isActive && state.currentPlayer == human;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.appTitle),
        actions: [
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
                              : loc.playerTurn(_name(state.currentPlayer, loc)),
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
                  onNewGame: _newGame,
                ),
              ),
          ],
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
        color: Color(0xFF194A3B),
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
    required this.onNewGame,
  });

  final String title;
  final String message;
  final String buttonLabel;
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
