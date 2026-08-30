import '../models/playing_card.dart';

enum MoveType {
  single,
  pair,
  triple,
  straight,
  fourOfAKind,
  consecutivePairs,
  invalid,
}

class Move {
  Move({required this.cards, required this.type})
    : assert(cards.isNotEmpty || type == MoveType.invalid);

  final List<PlayingCard> cards;
  final MoveType type;

  bool get isValid => type != MoveType.invalid;

  bool get isSingle => type == MoveType.single;
  bool get isPair => type == MoveType.pair;
  bool get isTriple => type == MoveType.triple;
  bool get isStraight => type == MoveType.straight;
  bool get isFourOfAKind => type == MoveType.fourOfAKind;
  bool get isConsecutivePairs => type == MoveType.consecutivePairs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Move && type == other.type && _sameCards(cards, other.cards);

  @override
  int get hashCode => Object.hash(type, Object.hashAll(cards));

  @override
  String toString() => '${type.name}: ${cards.join(', ')}';

  static bool _sameCards(List<PlayingCard> left, List<PlayingCard> right) {
    if (left.length != right.length) {
      return false;
    }
    final first = [...left]..sort();
    final second = [...right]..sort();
    return listEquals(first, second);
  }

  static bool listEquals(List<PlayingCard> left, List<PlayingCard> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }
}
