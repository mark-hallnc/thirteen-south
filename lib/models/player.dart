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

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'isHuman': isHuman,
    'hand': _hand.map((card) => card.toJson()).toList(),
  };

  factory Player.fromJson(Map<String, dynamic> json) {
    final player = Player(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      isHuman: json['isHuman'] as bool,
    );
    // Restore the recorded engine order without sorting or dealing.
    player._hand.addAll((json['hand'] as List).map(
      (card) => PlayingCard.fromJson(card as Map<String, dynamic>),
    ));
    return player;
  }
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
