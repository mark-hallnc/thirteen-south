enum CardRank {
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace,
  two,
}

extension CardRankX on CardRank {
  int get order => index;

  String get display => switch (this) {
    CardRank.three => '3',
    CardRank.four => '4',
    CardRank.five => '5',
    CardRank.six => '6',
    CardRank.seven => '7',
    CardRank.eight => '8',
    CardRank.nine => '9',
    CardRank.ten => '10',
    CardRank.jack => 'J',
    CardRank.queen => 'Q',
    CardRank.king => 'K',
    CardRank.ace => 'A',
    CardRank.two => '2',
  };
}

enum CardSuit { spades, clubs, diamonds, hearts }

extension CardSuitX on CardSuit {
  int get order => index;

  String get symbol => switch (this) {
    CardSuit.spades => '♠',
    CardSuit.clubs => '♣',
    CardSuit.diamonds => '♦',
    CardSuit.hearts => '♥',
  };
}

extension PlayingCardAssetX on PlayingCard {
  String get assetPath {
    final rankName = switch (rank) {
      CardRank.ace => 'ace',
      CardRank.two => '2',
      CardRank.three => '3',
      CardRank.four => '4',
      CardRank.five => '5',
      CardRank.six => '6',
      CardRank.seven => '7',
      CardRank.eight => '8',
      CardRank.nine => '9',
      CardRank.ten => '10',
      CardRank.jack => 'jack',
      CardRank.queen => 'queen',
      CardRank.king => 'king',
    };
    final suitName = switch (suit) {
      CardSuit.clubs => 'clubs',
      CardSuit.diamonds => 'diamonds',
      CardSuit.hearts => 'hearts',
      CardSuit.spades => 'spades',
    };
    return 'assets/cards_png/faces/${rankName}_$suitName.png';
  }
}

class PlayingCard implements Comparable<PlayingCard> {
  const PlayingCard(this.rank, this.suit);

  final CardRank rank;
  final CardSuit suit;

  int get strength => (rank.order * CardSuit.values.length) + suit.order;
  String get rankDisplay => rank.display;
  String get suitDisplay => suit.symbol;
  String get shortName => '$rankDisplay$suitDisplay';

  @override
  int compareTo(PlayingCard other) => strength.compareTo(other.strength);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayingCard && rank == other.rank && suit == other.suit;

  @override
  int get hashCode => Object.hash(rank, suit);

  @override
  String toString() => shortName;
}
