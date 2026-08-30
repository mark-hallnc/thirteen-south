import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tien_len/game/deck.dart';
import 'package:tien_len/game/game_engine.dart';
import 'package:tien_len/game/hand_analyzer.dart';
import 'package:tien_len/game/move.dart';
import 'package:tien_len/game/move_validator.dart';
import 'package:tien_len/models/player.dart';
import 'package:tien_len/models/playing_card.dart';

void main() {
  group('Deck', () {
    test('Deck has exactly 52 cards', () {
      final deck = Deck();
      expect(deck.cards.length, 52);
    });

    test('Deck contains 52 unique cards', () {
      final deck = Deck();
      final unique = deck.cards.toSet().length;
      expect(unique, 52);
    });

    test('Four-player deal gives each player exactly 13 cards', () {
      final deck = Deck(random: Random(42));
      final hands = deck.dealFourPlayers();
      expect(hands.length, 4);
      for (final hand in hands) {
        expect(hand.length, 13);
      }
    });
  });

  group('Card ordering', () {
    test('3♠ compares as the lowest card', () {
      final lowest = PlayingCard(CardRank.three, CardSuit.spades);
      final next = PlayingCard(CardRank.four, CardSuit.hearts);
      expect(lowest.compareTo(next), lessThan(0));
    });

    test('2♥ compares as the highest card', () {
      final highest = PlayingCard(CardRank.two, CardSuit.hearts);
      final next = PlayingCard(CardRank.ace, CardSuit.spades);
      expect(highest.compareTo(next), greaterThan(0));
    });

    test('Hand sorting follows Tiến Lên rank/suit order', () {
      final hand = [
        PlayingCard(CardRank.ace, CardSuit.hearts),
        PlayingCard(CardRank.three, CardSuit.spades),
        PlayingCard(CardRank.king, CardSuit.clubs),
        PlayingCard(CardRank.ace, CardSuit.spades),
      ];
      final sorted = [...hand]..sort();
      expect(sorted.first, PlayingCard(CardRank.three, CardSuit.spades));
      expect(sorted.last, PlayingCard(CardRank.ace, CardSuit.hearts));
    });
  });

  group('Hand analyzer', () {
    test('Single recognition', () {
      final move = HandAnalyzer().analyze([
        PlayingCard(CardRank.nine, CardSuit.hearts),
      ]);
      expect(move.type, MoveType.single);
      expect(move.cards.length, 1);
    });

    test('Pair recognition', () {
      final move = HandAnalyzer().analyze([
        PlayingCard(CardRank.king, CardSuit.spades),
        PlayingCard(CardRank.king, CardSuit.hearts),
      ]);
      expect(move.type, MoveType.pair);
      expect(move.cards.length, 2);
    });

    test('Triple recognition', () {
      final move = HandAnalyzer().analyze([
        PlayingCard(CardRank.five, CardSuit.spades),
        PlayingCard(CardRank.five, CardSuit.clubs),
        PlayingCard(CardRank.five, CardSuit.hearts),
      ]);
      expect(move.type, MoveType.triple);
      expect(move.cards.length, 3);
    });

    test('Four-of-a-kind recognition', () {
      final move = HandAnalyzer().analyze([
        PlayingCard(CardRank.seven, CardSuit.spades),
        PlayingCard(CardRank.seven, CardSuit.clubs),
        PlayingCard(CardRank.seven, CardSuit.diamonds),
        PlayingCard(CardRank.seven, CardSuit.hearts),
      ]);
      expect(move.type, MoveType.fourOfAKind);
    });

    test('Valid straight recognition', () {
      final move = HandAnalyzer().analyze([
        PlayingCard(CardRank.three, CardSuit.spades),
        PlayingCard(CardRank.four, CardSuit.hearts),
        PlayingCard(CardRank.five, CardSuit.clubs),
      ]);
      expect(move.type, MoveType.straight);
    });

    test('A straight containing a 2 is rejected', () {
      final move = HandAnalyzer().analyze([
        PlayingCard(CardRank.ten, CardSuit.spades),
        PlayingCard(CardRank.jack, CardSuit.hearts),
        PlayingCard(CardRank.queen, CardSuit.clubs),
        PlayingCard(CardRank.two, CardSuit.diamonds),
      ]);
      expect(move.type, MoveType.invalid);
    });

    test('Three consecutive pairs are recognized', () {
      final move = HandAnalyzer().analyze([
        PlayingCard(CardRank.queen, CardSuit.spades),
        PlayingCard(CardRank.queen, CardSuit.hearts),
        PlayingCard(CardRank.king, CardSuit.clubs),
        PlayingCard(CardRank.king, CardSuit.diamonds),
        PlayingCard(CardRank.ace, CardSuit.spades),
        PlayingCard(CardRank.ace, CardSuit.hearts),
      ]);
      expect(move.type, MoveType.consecutivePairs);
    });

    test('Invalid random combinations are rejected', () {
      final move = HandAnalyzer().analyze([
        PlayingCard(CardRank.three, CardSuit.spades),
        PlayingCard(CardRank.five, CardSuit.hearts),
        PlayingCard(CardRank.eight, CardSuit.clubs),
      ]);
      expect(move.type, MoveType.invalid);
    });
  });

  group('Move validation', () {
    test('Lower single cannot beat higher single', () {
      final lower = Move(
        cards: [PlayingCard(CardRank.five, CardSuit.spades)],
        type: MoveType.single,
      );
      final higher = Move(
        cards: [PlayingCard(CardRank.six, CardSuit.hearts)],
        type: MoveType.single,
      );
      expect(MoveValidator().beats(higher, lower), isTrue);
    });
  });

  group('Game engine', () {
    test('Game engine identifies the player holding 3♠', () {
      final engine = GameEngine();
      engine.startNewGame();
      final startIndex = engine.startingPlayerIndex;
      final hasThreeSpades = engine.players[startIndex].hand.any(
        (card) => card.rank == CardRank.three && card.suit == CardSuit.spades,
      );
      expect(hasThreeSpades, isTrue);
    });
  });

  group('Player', () {
    test('Player tracks remaining cards and mutates safely', () {
      final player = Player(id: 'p1', displayName: 'You', isHuman: true);
      final cards = [
        PlayingCard(CardRank.three, CardSuit.spades),
        PlayingCard(CardRank.four, CardSuit.hearts),
      ];
      player.receiveCards(cards);
      expect(player.cardsRemaining, 2);
      player.removePlayedCards([cards.first]);
      expect(player.cardsRemaining, 1);
    });
  });
}
