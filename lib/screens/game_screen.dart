import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tien_len/l10n/app_localizations.dart';

import '../game/game_engine.dart';
import '../game/move_validator.dart';
import '../models/player.dart';
import '../models/playing_card.dart';
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
  int _aiRun = 0;
  Timer? _aiTimer;

  @override
  void initState() {
    super.initState();
    _engine = widget.engine ?? (GameEngine()..startNewGame());
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAiTurns());
  }

  @override
  void dispose() {
    _aiRun++;
    _aiTimer?.cancel();
    super.dispose();
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
      setState(_engine.performAiTurn);
      _runAiTurns();
    });
  }

  void _toggleCard(PlayingCard card) {
    setState(() {
      _selected.contains(card) ? _selected.remove(card) : _selected.add(card);
    });
  }

  void _play() {
    final result = _engine.playCards(
      _engine.players.first.id,
      _selected.toList(),
    );
    if (result.isValid) {
      setState(_selected.clear);
      _runAiTurns();
    } else {
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
      _engine.startNewGame();
    });
    _runAiTurns();
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
                    cards: human.hand,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final topWidth = math.max(220.0, constraints.maxWidth - 20);
          final clusterHeight = math.min(270.0, constraints.maxHeight - 8);
          final clusterTop = math.max(
            4.0,
            constraints.maxHeight - clusterHeight - 4,
          );
          final sideHeight = math.max(
            112.0,
            math.min(138.0, clusterHeight * .52),
          );
          final centerWidth = math.max(
            170.0,
            math.min(248.0, constraints.maxWidth - 136),
          );
          return Stack(
            children: [
              Positioned(
                top: clusterTop,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: topWidth,
                    height: 78,
                    child: opponent(opponents[1], OpponentPosition.top),
                  ),
                ),
              ),
              Positioned(
                left: 4,
                top: clusterTop + 68,
                child: SizedBox(
                  width: 62,
                  height: sideHeight,
                  child: opponent(opponents[0], OpponentPosition.left),
                ),
              ),
              Positioned(
                right: 4,
                top: clusterTop + 68,
                child: SizedBox(
                  width: 62,
                  height: sideHeight,
                  child: opponent(opponents[2], OpponentPosition.right),
                ),
              ),
              Positioned(
                top: clusterTop + 64,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: centerWidth,
                    child: TableMoveArea(
                      cards:
                          state.currentTableMove?.cards ??
                          const <PlayingCard>[],
                      emptyLabel: loc.leadAPlay,
                      ownerLabel: state.currentMovePlayer == null
                          ? null
                          : loc.lead(nameFor(state.currentMovePlayer!)),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
