import '../models/playing_card.dart';
import 'hand_analyzer.dart';
import 'move.dart';
import 'rules/tien_len_south_rules.dart';

enum MoveValidationReason {
  invalidCombination,
  mustIncludeThreeSpades,
  doesNotBeat,
  notYourTurn,
  cardNotInHand,
  cannotPassWhileLeading,
  alreadyPassed,
  gameOver,
}

class MoveValidationResult {
  const MoveValidationResult._(this.isValid, this.reason);
  const MoveValidationResult.valid() : this._(true, null);
  const MoveValidationResult.invalid(MoveValidationReason reason)
    : this._(false, reason);

  final bool isValid;
  final MoveValidationReason? reason;
}

class MoveValidator {
  MoveValidator({HandAnalyzer? analyzer})
    : _analyzer = analyzer ?? HandAnalyzer();

  final HandAnalyzer _analyzer;

  MoveValidationResult canLead(Move move) => _canonical(move).isValid
      ? const MoveValidationResult.valid()
      : const MoveValidationResult.invalid(
          MoveValidationReason.invalidCombination,
        );

  MoveValidationResult canBeat({
    required Move candidate,
    required Move current,
  }) {
    final next = _canonical(candidate);
    final table = _canonical(current);
    if (!next.isValid) {
      return const MoveValidationResult.invalid(
        MoveValidationReason.invalidCombination,
      );
    }
    if (!table.isValid || !_beatsCanonical(next, table)) {
      return const MoveValidationResult.invalid(
        MoveValidationReason.doesNotBeat,
      );
    }
    return const MoveValidationResult.valid();
  }

  bool beats(Move candidate, Move current) =>
      canBeat(candidate: candidate, current: current).isValid;

  bool isChopAgainstTwos(Move candidate, Move current) {
    final next = _canonical(candidate);
    final table = _canonical(current);
    return next.isValid && table.isValid && _isChop(next, table);
  }

  Move _canonical(Move move) => _analyzer.analyze(move.cards);

  bool _beatsCanonical(Move candidate, Move current) {
    if (_isChop(candidate, current)) return true;
    if (candidate.type != current.type ||
        candidate.cards.length != current.cards.length) {
      return false;
    }
    return switch (candidate.type) {
      MoveType.single =>
        _highest(candidate).strength > _highest(current).strength,
      MoveType.pair || MoveType.triple => _rankThenSuit(candidate, current),
      MoveType.straight =>
        _highest(candidate).strength > _highest(current).strength,
      MoveType.fourOfAKind =>
        candidate.cards.first.rank.order > current.cards.first.rank.order,
      MoveType.consecutivePairs =>
        _highest(candidate).strength > _highest(current).strength,
      MoveType.invalid => false,
    };
  }

  bool _rankThenSuit(Move candidate, Move current) {
    final candidateRank = candidate.cards.first.rank.order;
    final currentRank = current.cards.first.rank.order;
    if (candidateRank != currentRank) return candidateRank > currentRank;
    return _highest(candidate).suit.order > _highest(current).suit.order;
  }

  PlayingCard _highest(Move move) => ([...move.cards]..sort()).last;

  bool _isChop(Move candidate, Move current) {
    if (!_isTwoGroup(current)) return false;
    final twoCount = current.cards.length;
    if (twoCount == 1 &&
        candidate.type == MoveType.fourOfAKind &&
        TienLenSouthRules.fourOfAKindChopsSingleTwo) {
      return true;
    }
    if (candidate.type != MoveType.consecutivePairs) return false;
    final pairCount = candidate.cards.length ~/ 2;
    final required = switch (twoCount) {
      1 => TienLenSouthRules.pairsToChopSingleTwo,
      2 => TienLenSouthRules.pairsToChopPairOfTwos,
      3 => TienLenSouthRules.pairsToChopTripleTwos,
      _ => 999,
    };
    return pairCount >= required;
  }

  bool _isTwoGroup(Move move) {
    if (move.type != MoveType.single &&
        move.type != MoveType.pair &&
        move.type != MoveType.triple) {
      return false;
    }
    return move.cards.every((card) => card.rank == CardRank.two);
  }
}
