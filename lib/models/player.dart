import 'playing_card.dart';

class Player {
  Player({
    required this.id,
    required this.displayName,
    required this.isHuman,
    List<PlayingCard>? hand,
  }) {
    if (hand != null) {
      _hand.addAll(hand);
      sortHand();
    }
  }

  final String id;
  final String displayName;
  final bool isHuman;

  final List<PlayingCard> _hand = <PlayingCard>[];

  List<PlayingCard> get hand => List.unmodifiable(_hand);
  int get cardsRemaining => _hand.length;

  void receiveCards(Iterable<PlayingCard> cards) {
    _hand.addAll(cards);
    sortHand();
  }

  void removePlayedCards(Iterable<PlayingCard> cards) {
    for (final card in cards) {
      _hand.remove(card);
    }
  }

  void replaceHand(List<PlayingCard> cards) {
    _hand
      ..clear()
      ..addAll(cards);
    sortHand();
  }

  void sortHand() {
    _hand.sort();
  }
}
