import '../../models/playing_card.dart';

class TienLenSouthRules {
  TienLenSouthRules._();

  static const List<CardRank> rankOrder = [
    CardRank.three,
    CardRank.four,
    CardRank.five,
    CardRank.six,
    CardRank.seven,
    CardRank.eight,
    CardRank.nine,
    CardRank.ten,
    CardRank.jack,
    CardRank.queen,
    CardRank.king,
    CardRank.ace,
    CardRank.two,
  ];

  static const List<CardSuit> suitOrder = [
    CardSuit.spades,
    CardSuit.clubs,
    CardSuit.diamonds,
    CardSuit.hearts,
  ];

  static const int minimumStraightLength = 3;
  static const int minimumConsecutivePairLength = 3;

  // Default Southern chop thresholds. These are centralized because common
  // house rules vary. Bombs otherwise compare only within their own type.
  static const int pairsToChopSingleTwo = 3;
  static const int pairsToChopPairOfTwos = 4;
  static const int pairsToChopTripleTwos = 5;
  static const bool fourOfAKindChopsSingleTwo = true;

  static const PlayingCard lowestCard = PlayingCard(
    CardRank.three,
    CardSuit.spades,
  );
  static const PlayingCard highestCard = PlayingCard(
    CardRank.two,
    CardSuit.hearts,
  );

  static bool isStraightRank(CardRank rank) => rank != CardRank.two;
  static bool isAllowedConsecutivePairRank(CardRank rank) =>
      rank != CardRank.two;
}
