import '../game/hand_analyzer.dart';
import '../game/move.dart';
import '../models/playing_card.dart';

class LegalMoveGenerator {
  LegalMoveGenerator({HandAnalyzer? analyzer})
    : _analyzer = analyzer ?? HandAnalyzer();

  final HandAnalyzer _analyzer;

  List<Move> generate(List<PlayingCard> hand) {
    final sorted = [...hand]..sort();
    final byRank = <CardRank, List<PlayingCard>>{};
    for (final card in sorted) {
      byRank.putIfAbsent(card.rank, () => <PlayingCard>[]).add(card);
    }
    final moves = <Move>[];
    for (final card in sorted) {
      moves.add(_analyzer.analyze([card]));
    }
    for (final cards in byRank.values) {
      moves.addAll(_combinations(cards, 2).map(_analyzer.analyze));
      moves.addAll(_combinations(cards, 3).map(_analyzer.analyze));
      if (cards.length == 4) moves.add(_analyzer.analyze(cards));
    }
    _addStraights(byRank, moves);
    _addConsecutivePairs(byRank, moves);
    return moves.where((move) => move.isValid).toList()..sort(_compareMoves);
  }

  void _addStraights(
    Map<CardRank, List<PlayingCard>> byRank,
    List<Move> moves,
  ) {
    final ranks = CardRank.values
        .where((rank) => rank != CardRank.two && byRank.containsKey(rank))
        .toList();
    for (var start = 0; start < ranks.length; start++) {
      for (var end = start + 2; end < ranks.length; end++) {
        if (ranks[end].order - ranks[start].order != end - start) break;
        final cards = ranks
            .sublist(start, end + 1)
            .map((rank) => byRank[rank]!.first)
            .toList();
        moves.add(_analyzer.analyze(cards));
      }
    }
  }

  void _addConsecutivePairs(
    Map<CardRank, List<PlayingCard>> byRank,
    List<Move> moves,
  ) {
    final ranks = CardRank.values
        .where(
          (rank) => rank != CardRank.two && (byRank[rank]?.length ?? 0) >= 2,
        )
        .toList();
    for (var start = 0; start < ranks.length; start++) {
      for (var end = start + 2; end < ranks.length; end++) {
        if (ranks[end].order - ranks[start].order != end - start) break;
        final cards = <PlayingCard>[];
        for (final rank in ranks.sublist(start, end + 1)) {
          cards.addAll(byRank[rank]!.take(2));
        }
        moves.add(_analyzer.analyze(cards));
      }
    }
  }

  Iterable<List<PlayingCard>> _combinations(
    List<PlayingCard> cards,
    int count,
  ) sync* {
    if (cards.length < count) return;
    final selected = <PlayingCard>[];
    Iterable<List<PlayingCard>> walk(int index) sync* {
      if (selected.length == count) {
        yield [...selected];
        return;
      }
      for (var i = index; i <= cards.length - (count - selected.length); i++) {
        selected.add(cards[i]);
        yield* walk(i + 1);
        selected.removeLast();
      }
    }

    yield* walk(0);
  }

  int _compareMoves(Move left, Move right) {
    final leftBomb = left.isFourOfAKind || left.isConsecutivePairs;
    final rightBomb = right.isFourOfAKind || right.isConsecutivePairs;
    if (leftBomb != rightBomb) return leftBomb ? 1 : -1;
    final leftTwo = left.cards.any((card) => card.rank == CardRank.two);
    final rightTwo = right.cards.any((card) => card.rank == CardRank.two);
    if (leftTwo != rightTwo) return leftTwo ? 1 : -1;
    final count = right.cards.length.compareTo(left.cards.length);
    if (count != 0) return count;
    return left.cards.last.strength.compareTo(right.cards.last.strength);
  }
}
