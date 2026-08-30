import '../models/playing_card.dart';
import 'move.dart';
import 'rules/tien_len_south_rules.dart';

class HandAnalyzer {
  Move analyze(List<PlayingCard> cards) {
    final normalized = [...cards]..sort();
    if (normalized.isEmpty) {
      return Move(cards: <PlayingCard>[], type: MoveType.invalid);
    }

    if (normalized.length == 1) {
      return Move(cards: normalized, type: MoveType.single);
    }

    if (_isFourOfAKind(normalized)) {
      return Move(cards: normalized, type: MoveType.fourOfAKind);
    }

    if (_isConsecutivePairs(normalized)) {
      return Move(cards: normalized, type: MoveType.consecutivePairs);
    }

    if (_isPair(normalized)) {
      return Move(cards: normalized, type: MoveType.pair);
    }

    if (_isTriple(normalized)) {
      return Move(cards: normalized, type: MoveType.triple);
    }

    if (_isStraight(normalized)) {
      return Move(cards: normalized, type: MoveType.straight);
    }

    return Move(cards: normalized, type: MoveType.invalid);
  }

  bool _isPair(List<PlayingCard> cards) =>
      cards.length == 2 && cards[0].rank == cards[1].rank;

  bool _isTriple(List<PlayingCard> cards) =>
      cards.length == 3 &&
      cards[0].rank == cards[1].rank &&
      cards[1].rank == cards[2].rank;

  bool _isFourOfAKind(List<PlayingCard> cards) =>
      cards.length == 4 &&
      cards[0].rank == cards[1].rank &&
      cards[1].rank == cards[2].rank &&
      cards[2].rank == cards[3].rank;

  bool _isStraight(List<PlayingCard> cards) {
    if (cards.length < TienLenSouthRules.minimumStraightLength) {
      return false;
    }
    if (cards.any((card) => card.rank == CardRank.two)) {
      return false;
    }

    final uniqueRanks = cards.map((card) => card.rank).toSet().toList()
      ..sort((left, right) => left.order.compareTo(right.order));
    if (uniqueRanks.length != cards.length) {
      return false;
    }

    for (var index = 1; index < uniqueRanks.length; index++) {
      final previous = uniqueRanks[index - 1].order;
      final current = uniqueRanks[index].order;
      if (current - previous != 1) {
        return false;
      }
    }

    return true;
  }

  bool _isConsecutivePairs(List<PlayingCard> cards) {
    if (cards.length < TienLenSouthRules.minimumConsecutivePairLength * 2) {
      return false;
    }

    final pairs = <CardRank>[];
    for (var index = 0; index < cards.length; index += 2) {
      if (index + 1 >= cards.length) {
        return false;
      }
      final first = cards[index];
      final second = cards[index + 1];
      if (first.rank != second.rank) {
        return false;
      }
      if (first.rank == CardRank.two) {
        return false;
      }
      pairs.add(first.rank);
    }

    for (var index = 1; index < pairs.length; index++) {
      final previous = pairs[index - 1].order;
      final current = pairs[index].order;
      if (current - previous != 1) {
        return false;
      }
    }

    return true;
  }
}
