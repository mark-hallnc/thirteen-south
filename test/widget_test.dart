import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tien_len/game/deck.dart';
import 'package:tien_len/game/game_engine.dart';
import 'package:tien_len/game/hand_analyzer.dart';
import 'package:tien_len/game/move.dart';
import 'package:tien_len/game/move_validator.dart';
import 'package:tien_len/models/player.dart';
import 'package:tien_len/models/playing_card.dart';
import 'package:tien_len/widgets/playing_card_widget.dart';

void main() {
  testWidgets('Card widgets render individual PNG assets', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Row(
          children: [
            PlayingCardWidget(card: PlayingCard(CardRank.ace, CardSuit.clubs)),
            CardBackWidget(),
          ],
        ),
      ),
    );
    expect(find.byType(Image), findsNWidgets(2));
    expect(
      (tester.widgetList<Image>(find.byType(Image)).last.image as AssetImage)
          .assetName,
      'assets/cards_png/back.png',
    );
  });

  testWidgets('Card taps disable Material feedback', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PlayingCardWidget(
          card: PlayingCard(CardRank.two, CardSuit.hearts),
        ),
      ),
    );

    expect(
      tester.widget<InkWell>(find.byType(InkWell)).enableFeedback,
      isFalse,
    );
  });

  test('All cards map to existing unique individual PNG assets', () {
    final cards = [
      for (final rank in CardRank.values)
        for (final suit in CardSuit.values) PlayingCard(rank, suit),
    ];
    final paths = cards.map((card) => card.assetPath).toSet();
    expect(paths, hasLength(52));
    expect(
      paths.every((path) => path.startsWith('assets/cards_png/faces/')),
      isTrue,
    );
    expect(paths.every((path) => path.endsWith('.png')), isTrue);
    expect(paths.any((path) => path.endsWith('.svg')), isFalse);
    expect(paths.every((path) => File(path).existsSync()), isTrue);
    expect(
      PlayingCard(CardRank.three, CardSuit.spades).assetPath,
      'assets/cards_png/faces/3_spades.png',
    );
    expect(
      PlayingCard(CardRank.ten, CardSuit.diamonds).assetPath,
      'assets/cards_png/faces/10_diamonds.png',
    );
    expect(
      PlayingCard(CardRank.jack, CardSuit.clubs).assetPath,
      'assets/cards_png/faces/jack_clubs.png',
    );
    expect(
      PlayingCard(CardRank.queen, CardSuit.hearts).assetPath,
      'assets/cards_png/faces/queen_hearts.png',
    );
    expect(
      PlayingCard(CardRank.king, CardSuit.spades).assetPath,
      'assets/cards_png/faces/king_spades.png',
    );
    expect(
      PlayingCard(CardRank.ace, CardSuit.clubs).assetPath,
      'assets/cards_png/faces/ace_clubs.png',
    );
    expect(
      PlayingCard(CardRank.two, CardSuit.hearts).assetPath,
      'assets/cards_png/faces/2_hearts.png',
    );
  });

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
