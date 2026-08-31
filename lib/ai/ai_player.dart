import 'ai_difficulty.dart';
import '../game/move.dart';
import '../game/move_validator.dart';
import '../models/player.dart';
import '../models/playing_card.dart';
import 'legal_move_generator.dart';

class AiPlayer {
  AiPlayer({LegalMoveGenerator? generator, MoveValidator? validator})
    : _generator = generator ?? LegalMoveGenerator(),
      _validator = validator ?? MoveValidator();

  final LegalMoveGenerator _generator;
  final MoveValidator _validator;

  Move? chooseMove(
    Player player, {
    Move? currentMove,
    bool mustContainThreeSpades = false,
    bool allowOnlyChop = false,
    AiDifficulty difficulty = AiDifficulty.normal,
    List<int> opponentCardCounts = const [],
  }) {
    final moves = _generator.generate(player.hand).where((move) {
      if (mustContainThreeSpades && !move.cards.contains(_threeSpades)) {
        return false;
      }
      if (currentMove == null) return _validator.canLead(move).isValid;
      if (allowOnlyChop && !_validator.isChopAgainstTwos(move, currentMove)) {
        return false;
      }
      return _validator.canBeat(candidate: move, current: currentMove).isValid;
    }).toList();
    if (moves.isEmpty) return null;
    return switch (difficulty) {
      AiDifficulty.easy => _chooseLowestScored(
        moves,
        (move) => _scoreEasyMove(move),
      ),
      AiDifficulty.normal => _chooseNormalMove(
        moves,
        isLeading: currentMove == null,
        opponentCardCounts: opponentCardCounts,
      ),
      AiDifficulty.hard => _chooseLowestScored(
        moves,
        (move) => _scoreHardMove(
          move,
          player.hand,
          isLeading: currentMove == null,
          opponentCardCounts: opponentCardCounts,
        ),
      ),
    };
  }

  Move _chooseLowestScored(List<Move> moves, double Function(Move move) score) {
    return moves.reduce(
      (best, candidate) => score(candidate) < score(best) ? candidate : best,
    );
  }

  double _scoreEasyMove(Move move) =>
      move.cards.last.strength + move.cards.length * 3;

  Move _chooseNormalMove(
    List<Move> moves, {
    required bool isLeading,
    required List<int> opponentCardCounts,
  }) {
    if (isLeading && opponentCardCounts.any((count) => count <= 2)) {
      return moves.firstWhere(
        (move) =>
            move.cards.length > 1 &&
            !move.isFourOfAKind &&
            !move.isConsecutivePairs &&
            !move.cards.any((card) => card.rank == CardRank.two),
        orElse: () => moves.first,
      );
    }
    // Preserve the established behavior: the generator sheds useful
    // combinations first and ranks 2s and bombs last.
    return moves.first;
  }

  double _scoreHardMove(
    Move move,
    List<PlayingCard> hand, {
    required bool isLeading,
    required List<int> opponentCardCounts,
  }) {
    final remaining = [...hand]..removeWhere(move.cards.toSet().contains);
    if (remaining.isEmpty) return -10000;

    final isBomb = move.isFourOfAKind || move.isConsecutivePairs;
    final usesTwo = move.cards.any((card) => card.rank == CardRank.two);
    final opponentUnderPressure = opponentCardCounts.any((count) => count <= 2);
    var score = move.cards.last.strength.toDouble();
    if (isBomb) score += 500;
    if (usesTwo) score += 180;

    if (move.isSingle && _rankCount(hand, move.cards.single.rank) > 1) {
      score += 90;
    }

    final usefulRemainder = _generator
        .generate(remaining)
        .where((candidate) => candidate.cards.length > 1)
        .fold<int>(
          0,
          (best, candidate) =>
              candidate.cards.length > best ? candidate.cards.length : best,
        );
    score -= usefulRemainder * 12;

    if (hand.length <= 5) score -= move.cards.length * 100;
    if (isLeading) score -= move.cards.length * 24;
    if (isLeading && opponentUnderPressure) {
      if (move.isSingle) {
        score += 120 - move.cards.last.strength * 2;
      } else {
        score -= 45;
      }
    }
    return score;
  }

  int _rankCount(List<PlayingCard> cards, CardRank rank) =>
      cards.where((card) => card.rank == rank).length;

  static const PlayingCard _threeSpades = PlayingCard(
    CardRank.three,
    CardSuit.spades,
  );
}
