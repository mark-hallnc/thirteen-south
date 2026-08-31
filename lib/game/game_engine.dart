import '../ai/ai_player.dart';
import '../ai/ai_difficulty.dart';
import '../ai/legal_move_generator.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/playing_card.dart';
import 'deck.dart';
import 'hand_analyzer.dart';
import 'move_validator.dart';

class GameEngine {
  GameEngine({
    Deck? deck,
    List<Player>? players,
    MoveValidator? validator,
    HandAnalyzer? analyzer,
    AiPlayer? ai,
    this.difficulty = AiDifficulty.normal,
  }) : deck = deck ?? Deck(),
       players = players ?? _defaultPlayers(),
       validator = validator ?? MoveValidator(),
       analyzer = analyzer ?? HandAnalyzer(),
       ai = ai ?? AiPlayer() {
    if (this.players.length != 4) {
      throw ArgumentError.value(this.players.length, 'players', 'Must be four');
    }
    _state = GameState(players: this.players);
  }

  final Deck deck;
  final List<Player> players;
  final MoveValidator validator;
  final HandAnalyzer analyzer;
  final AiPlayer ai;
  AiDifficulty difficulty;
  final LegalMoveGenerator _moveGenerator = LegalMoveGenerator();
  late GameState _state;
  late int startingPlayerIndex;
  late String gameId;
  static int _sessionSequence = 0;

  GameState get state => _state;

  void startNewGame() {
    _beginSession();
    deck.reset();
    deck.shuffle();
    final hands = deck.dealFourPlayers();
    final allCards = hands.expand((hand) => hand).toList();
    if (allCards.length != 52 || allCards.toSet().length != 52) {
      throw StateError('Deal must contain 52 unique cards.');
    }
    for (var index = 0; index < players.length; index++) {
      players[index].replaceHand(hands[index]);
    }
    startingPlayerIndex = _findStartingPlayer();
    _state = GameState(
      players: players,
      currentPlayerIndex: startingPlayerIndex,
      openingRuleActive: true,
      isActive: true,
    );
  }

  /// Starts a deterministic state for tests and future local game restoration.
  void startWithHands(
    List<List<PlayingCard>> hands, {
    int? currentPlayerIndex,
  }) {
    _beginSession();
    if (hands.length != 4) {
      throw ArgumentError('Exactly four hands are required.');
    }
    final allCards = hands.expand((hand) => hand).toList();
    if (allCards.toSet().length != allCards.length) {
      throw ArgumentError('A card cannot appear in multiple hands.');
    }
    for (var index = 0; index < 4; index++) {
      players[index].replaceHand(hands[index]);
    }
    startingPlayerIndex = currentPlayerIndex ?? _findStartingPlayer();
    _state = GameState(
      players: players,
      currentPlayerIndex: startingPlayerIndex,
      openingRuleActive: true,
      isActive: true,
    );
  }

  MoveValidationResult playCards(String playerId, List<PlayingCard> cards) {
    final turnCheck = _checkActor(playerId);
    if (!turnCheck.isValid) return turnCheck;
    final player = state.currentPlayer;
    if (!_containsCards(player.hand, cards)) {
      return const MoveValidationResult.invalid(
        MoveValidationReason.cardNotInHand,
      );
    }
    final move = analyzer.analyze(cards);
    if (!move.isValid) {
      return const MoveValidationResult.invalid(
        MoveValidationReason.invalidCombination,
      );
    }
    if (state.openingRuleActive && !move.cards.contains(_threeSpades)) {
      return const MoveValidationResult.invalid(
        MoveValidationReason.mustIncludeThreeSpades,
      );
    }
    final table = state.currentTableMove;
    final validation = table == null
        ? validator.canLead(move)
        : validator.canBeat(candidate: move, current: table);
    if (!validation.isValid) return validation;
    if (state.hasPassed(playerId) &&
        (table == null || !validator.isChopAgainstTwos(move, table))) {
      return const MoveValidationResult.invalid(
        MoveValidationReason.alreadyPassed,
      );
    }

    player.removePlayedCards(move.cards);
    state.currentTableMove = move;
    state.currentMovePlayerIndex = state.currentPlayerIndex;
    state.openingRuleActive = false;
    state.passedPlayerIds.remove(playerId);
    if (player.cardsRemaining == 0) {
      state
        ..winner = player
        ..isActive = false;
      return const MoveValidationResult.valid();
    }
    _advanceAfterAction();
    return const MoveValidationResult.valid();
  }

  MoveValidationResult pass(String playerId) {
    final turnCheck = _checkActor(playerId);
    if (!turnCheck.isValid) return turnCheck;
    if (state.currentTableMove == null) {
      return const MoveValidationResult.invalid(
        MoveValidationReason.cannotPassWhileLeading,
      );
    }
    state.passedPlayerIds.add(playerId);
    _advanceAfterAction();
    return const MoveValidationResult.valid();
  }

  MoveValidationResult performAiTurn() {
    if (!state.isActive) {
      return const MoveValidationResult.invalid(MoveValidationReason.gameOver);
    }
    final player = state.currentPlayer;
    if (player.isHuman) {
      return const MoveValidationResult.invalid(
        MoveValidationReason.notYourTurn,
      );
    }
    final table = state.currentTableMove;
    final move = ai.chooseMove(
      player,
      currentMove: table,
      mustContainThreeSpades: state.openingRuleActive,
      allowOnlyChop: state.hasPassed(player.id),
      difficulty: difficulty,
      opponentCardCounts: players
          .where((opponent) => opponent != player)
          .map((opponent) => opponent.cardsRemaining)
          .toList(),
    );
    return move == null ? pass(player.id) : playCards(player.id, move.cards);
  }

  MoveValidationResult _checkActor(String playerId) {
    if (!state.isActive) {
      return const MoveValidationResult.invalid(MoveValidationReason.gameOver);
    }
    if (state.currentPlayer.id != playerId) {
      return const MoveValidationResult.invalid(
        MoveValidationReason.notYourTurn,
      );
    }
    return const MoveValidationResult.valid();
  }

  void _advanceAfterAction() {
    final owner = state.currentMovePlayerIndex;
    if (owner != null && !_hasEligibleOpponent(owner)) {
      state
        ..currentTableMove = null
        ..currentMovePlayerIndex = null
        ..currentPlayerIndex = owner;
      state.passedPlayerIds.clear();
      return;
    }
    final next = _nextEligibleIndex(state.currentPlayerIndex);
    if (next == null) throw StateError('No eligible active player.');
    state.currentPlayerIndex = next;
  }

  bool _hasEligibleOpponent(int owner) {
    for (var index = 0; index < players.length; index++) {
      if (_isEligibleOpponent(index, owner)) return true;
    }
    return false;
  }

  int? _nextEligibleIndex(int from) {
    final owner = state.currentMovePlayerIndex;
    for (var offset = 1; offset <= players.length; offset++) {
      final index = (from + offset) % players.length;
      if (owner == null) {
        if (players[index].cardsRemaining > 0) return index;
      } else if (_isEligibleOpponent(index, owner)) {
        return index;
      }
    }
    return null;
  }

  bool _isEligibleOpponent(int playerIndex, int owner) {
    if (playerIndex == owner || players[playerIndex].cardsRemaining == 0) {
      return false;
    }
    final player = players[playerIndex];
    return !state.hasPassed(player.id) || _canChop(playerIndex);
  }

  bool _canChop(int playerIndex) {
    final table = state.currentTableMove;
    if (table == null) return false;
    return _moveGenerator
        .generate(players[playerIndex].hand)
        .any((move) => validator.isChopAgainstTwos(move, table));
  }

  bool _containsCards(List<PlayingCard> hand, List<PlayingCard> cards) {
    if (cards.isEmpty || cards.toSet().length != cards.length) return false;
    return cards.every(hand.contains);
  }

  int _findStartingPlayer() {
    for (var index = 0; index < players.length; index++) {
      if (players[index].hand.contains(_threeSpades)) return index;
    }
    throw StateError('No player holds 3♠.');
  }

  void _beginSession() {
    gameId = '${DateTime.now().microsecondsSinceEpoch}-${_sessionSequence++}';
  }

  static List<Player> _defaultPlayers() => List.generate(
    4,
    (index) => Player(
      id: 'player_$index',
      displayName: index == 0 ? 'You' : 'Player ${index + 1}',
      isHuman: index == 0,
    ),
  );

  static const PlayingCard _threeSpades = PlayingCard(
    CardRank.three,
    CardSuit.spades,
  );
}
