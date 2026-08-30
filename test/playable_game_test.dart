import 'package:flutter_test/flutter_test.dart';
import 'package:tien_len/ai/ai_player.dart';
import 'package:tien_len/game/game_engine.dart';
import 'package:tien_len/game/hand_analyzer.dart';
import 'package:tien_len/game/move.dart';
import 'package:tien_len/game/move_validator.dart';
import 'package:tien_len/models/player.dart';
import 'package:tien_len/models/playing_card.dart';

PlayingCard c(CardRank rank, CardSuit suit) => PlayingCard(rank, suit);
Move m(List<PlayingCard> cards) => HandAnalyzer().analyze(cards);

List<PlayingCard> pair(
  CardRank rank, [
  CardSuit first = CardSuit.spades,
  CardSuit second = CardSuit.clubs,
]) => [c(rank, first), c(rank, second)];

List<PlayingCard> triple(CardRank rank) => [
  c(rank, CardSuit.spades),
  c(rank, CardSuit.clubs),
  c(rank, CardSuit.diamonds),
];

List<PlayingCard> four(CardRank rank) =>
    CardSuit.values.map((suit) => c(rank, suit)).toList();

List<PlayingCard> consecutivePairs(List<CardRank> ranks) => [
  for (final rank in ranks) ...pair(rank),
];

GameEngine engineWithHands(List<List<PlayingCard>> hands, {int current = 0}) {
  final players = List.generate(
    4,
    (index) =>
        Player(id: 'p$index', displayName: 'P$index', isHuman: index == 0),
  );
  return GameEngine(players: players)
    ..startWithHands(hands, currentPlayerIndex: current);
}

void main() {
  final validator = MoveValidator();

  group('Opening', () {
    final threeSpades = c(CardRank.three, CardSuit.spades);

    test('3♠ holder starts', () {
      final engine = engineWithHands([
        [c(CardRank.four, CardSuit.spades)],
        [threeSpades],
        [c(CardRank.five, CardSuit.spades)],
        [c(CardRank.six, CardSuit.spades)],
      ], current: 1);
      expect(engine.state.currentPlayerIndex, 1);
    });

    test('opening single 3♠ is valid', () {
      final engine = engineWithHands([
        [threeSpades, c(CardRank.ace, CardSuit.hearts)],
        [c(CardRank.four, CardSuit.spades)],
        [c(CardRank.five, CardSuit.spades)],
        [c(CardRank.six, CardSuit.spades)],
      ]);
      expect(engine.playCards('p0', [threeSpades]).isValid, isTrue);
    });

    test('opening pair containing 3♠ is valid', () {
      final cards = pair(CardRank.three);
      final engine = engineWithHands([
        [...cards, c(CardRank.ace, CardSuit.hearts)],
        [c(CardRank.four, CardSuit.spades)],
        [c(CardRank.five, CardSuit.spades)],
        [c(CardRank.six, CardSuit.spades)],
      ]);
      expect(engine.playCards('p0', cards).isValid, isTrue);
    });

    test('opening straight containing 3♠ is valid', () {
      final cards = [
        threeSpades,
        c(CardRank.four, CardSuit.hearts),
        c(CardRank.five, CardSuit.clubs),
      ];
      final engine = engineWithHands([
        [...cards, c(CardRank.ace, CardSuit.hearts)],
        [c(CardRank.six, CardSuit.spades)],
        [c(CardRank.seven, CardSuit.spades)],
        [c(CardRank.eight, CardSuit.spades)],
      ]);
      expect(engine.playCards('p0', cards).isValid, isTrue);
    });

    test('opening move without 3♠ is rejected without mutation', () {
      final hand = [threeSpades, c(CardRank.four, CardSuit.hearts)];
      final engine = engineWithHands([
        hand,
        [c(CardRank.five, CardSuit.spades)],
        [c(CardRank.six, CardSuit.spades)],
        [c(CardRank.seven, CardSuit.spades)],
      ]);
      final result = engine.playCards('p0', [hand.last]);
      expect(result.reason, MoveValidationReason.mustIncludeThreeSpades);
      expect(engine.players[0].hand, hand);
      expect(engine.state.currentPlayerIndex, 0);
    });
  });

  group('Normal comparison', () {
    test('2 suit order is spades, clubs, diamonds, hearts', () {
      final twoSpades = m([c(CardRank.two, CardSuit.spades)]);
      final twoClubs = m([c(CardRank.two, CardSuit.clubs)]);
      final twoDiamonds = m([c(CardRank.two, CardSuit.diamonds)]);
      final twoHearts = m([c(CardRank.two, CardSuit.hearts)]);

      expect(
        validator.canBeat(candidate: twoHearts, current: twoDiamonds).isValid,
        isTrue,
      );
      expect(
        validator.canBeat(candidate: twoDiamonds, current: twoClubs).isValid,
        isTrue,
      );
      expect(
        validator.canBeat(candidate: twoClubs, current: twoSpades).isValid,
        isTrue,
      );
    });

    test('higher single and same-rank higher suit win', () {
      expect(
        validator.beats(
          m([c(CardRank.six, CardSuit.spades)]),
          m([c(CardRank.five, CardSuit.hearts)]),
        ),
        isTrue,
      );
      expect(
        validator.beats(
          m([c(CardRank.seven, CardSuit.hearts)]),
          m([c(CardRank.seven, CardSuit.diamonds)]),
        ),
        isTrue,
      );
    });

    test('higher pair wins and suit breaks equal-rank tie', () {
      expect(
        validator.beats(m(pair(CardRank.eight)), m(pair(CardRank.seven))),
        isTrue,
      );
      expect(
        validator.beats(
          m(pair(CardRank.seven, CardSuit.spades, CardSuit.hearts)),
          m(pair(CardRank.seven, CardSuit.clubs, CardSuit.diamonds)),
        ),
        isTrue,
      );
    });

    test('higher triple wins', () {
      expect(
        validator.beats(m(triple(CardRank.king)), m(triple(CardRank.queen))),
        isTrue,
      );
    });

    test('same-length higher straight wins', () {
      final low = [
        c(CardRank.three, CardSuit.spades),
        c(CardRank.four, CardSuit.spades),
        c(CardRank.five, CardSuit.spades),
      ];
      final high = [
        c(CardRank.four, CardSuit.clubs),
        c(CardRank.five, CardSuit.clubs),
        c(CardRank.six, CardSuit.clubs),
      ];
      expect(validator.beats(m(high), m(low)), isTrue);
    });

    test('different-length straight cannot respond', () {
      final three = [
        c(CardRank.three, CardSuit.spades),
        c(CardRank.four, CardSuit.spades),
        c(CardRank.five, CardSuit.spades),
      ];
      final fourCards = [...three, c(CardRank.six, CardSuit.spades)];
      expect(validator.beats(m(fourCards), m(three)), isFalse);
    });

    test('higher equal-length consecutive pairs win', () {
      expect(
        validator.beats(
          m(consecutivePairs([CardRank.five, CardRank.six, CardRank.seven])),
          m(consecutivePairs([CardRank.four, CardRank.five, CardRank.six])),
        ),
        isTrue,
      );
    });
  });

  group('Southern chops', () {
    final singleTwo = m([c(CardRank.two, CardSuit.hearts)]);
    final pairTwos = m(pair(CardRank.two));
    final tripleTwos = m(triple(CardRank.two));

    test('four of a kind beats a single 2', () {
      expect(validator.beats(m(four(CardRank.seven)), singleTwo), isTrue);
    });

    test('three consecutive pairs beat a single 2', () {
      expect(
        validator.beats(
          m(consecutivePairs([CardRank.eight, CardRank.nine, CardRank.ten])),
          singleTwo,
        ),
        isTrue,
      );
    });

    test('three consecutive pairs do not beat pair of 2s', () {
      expect(
        validator.beats(
          m(consecutivePairs([CardRank.eight, CardRank.nine, CardRank.ten])),
          pairTwos,
        ),
        isFalse,
      );
    });

    test('four consecutive pairs beat pair of 2s', () {
      expect(
        validator.beats(
          m(
            consecutivePairs([
              CardRank.six,
              CardRank.seven,
              CardRank.eight,
              CardRank.nine,
            ]),
          ),
          pairTwos,
        ),
        isTrue,
      );
    });

    test('five consecutive pairs beat triple 2s', () {
      expect(
        validator.beats(
          m(
            consecutivePairs([
              CardRank.four,
              CardRank.five,
              CardRank.six,
              CardRank.seven,
              CardRank.eight,
            ]),
          ),
          tripleTwos,
        ),
        isTrue,
      );
    });

    test('bombs do not beat unrelated ordinary combinations', () {
      final ace = m([c(CardRank.ace, CardSuit.hearts)]);
      expect(validator.beats(m(four(CardRank.seven)), ace), isFalse);
      expect(
        validator.beats(
          m(consecutivePairs([CardRank.eight, CardRank.nine, CardRank.ten])),
          ace,
        ),
        isFalse,
      );
    });

    test('bombs compare only within same type and length', () {
      expect(
        validator.beats(m(four(CardRank.eight)), m(four(CardRank.seven))),
        isTrue,
      );
      expect(
        validator.beats(
          m(
            consecutivePairs([
              CardRank.six,
              CardRank.seven,
              CardRank.eight,
              CardRank.nine,
            ]),
          ),
          m(consecutivePairs([CardRank.eight, CardRank.nine, CardRank.ten])),
        ),
        isFalse,
      );
    });
  });

  group('Engine turns and passing', () {
    late GameEngine engine;
    late PlayingCard threeSpades;

    setUp(() {
      threeSpades = c(CardRank.three, CardSuit.spades);
      engine = engineWithHands([
        [threeSpades, c(CardRank.ace, CardSuit.hearts)],
        [c(CardRank.four, CardSuit.spades), c(CardRank.eight, CardSuit.hearts)],
        [c(CardRank.five, CardSuit.spades), c(CardRank.nine, CardSuit.hearts)],
        [c(CardRank.six, CardSuit.spades), c(CardRank.ten, CardSuit.hearts)],
      ]);
    });

    test('successful move removes cards and advances turn', () {
      expect(engine.playCards('p0', [threeSpades]).isValid, isTrue);
      expect(engine.players[0].hand, isNot(contains(threeSpades)));
      expect(engine.state.currentPlayerIndex, 1);
    });

    test('card not held is rejected without removing cards', () {
      final before = [...engine.players[0].hand];
      final result = engine.playCards('p0', [
        c(CardRank.king, CardSuit.hearts),
      ]);
      expect(result.reason, MoveValidationReason.cardNotInHand);
      expect(engine.players[0].hand, before);
    });

    test('pass advances, locks, and skipped player remains locked', () {
      engine.playCards('p0', [threeSpades]);
      expect(engine.pass('p1').isValid, isTrue);
      expect(engine.state.hasPassed('p1'), isTrue);
      expect(engine.state.currentPlayerIndex, 2);
      engine.playCards('p2', [c(CardRank.five, CardSuit.spades)]);
      expect(engine.state.currentPlayerIndex, 3);
      engine.pass('p3');
      expect(engine.state.currentPlayerIndex, 0);
    });

    test('all opponents passing clears trick and restores lead', () {
      engine.playCards('p0', [threeSpades]);
      engine.pass('p1');
      engine.pass('p2');
      engine.pass('p3');
      expect(engine.state.currentTableMove, isNull);
      expect(engine.state.passedPlayerIds, isEmpty);
      expect(engine.state.currentPlayerIndex, 0);
    });

    test('cannot pass while leading a fresh trick', () {
      final result = engine.pass('p0');
      expect(result.reason, MoveValidationReason.cannotPassWhileLeading);
      expect(engine.state.currentPlayerIndex, 0);
    });

    test('empty hand wins and no later action is accepted', () {
      engine.players[0].replaceHand([threeSpades]);
      expect(engine.playCards('p0', [threeSpades]).isValid, isTrue);
      expect(engine.state.winner, engine.players[0]);
      expect(engine.state.isActive, isFalse);
      expect(engine.pass('p1').reason, MoveValidationReason.gameOver);
    });

    test('only current player may act', () {
      expect(
        engine.playCards('p1', engine.players[1].hand.take(1).toList()).reason,
        MoveValidationReason.notYourTurn,
      );
    });

    test('unpassed human can play or pass against a lower-suit 2', () {
      GameEngine inState() {
        final result = engineWithHands([
          [c(CardRank.two, CardSuit.hearts), c(CardRank.ace, CardSuit.spades)],
          [c(CardRank.four, CardSuit.spades)],
          [c(CardRank.five, CardSuit.spades)],
          [c(CardRank.six, CardSuit.spades)],
        ]);
        result.state
          ..openingRuleActive = false
          ..currentTableMove = m([c(CardRank.two, CardSuit.diamonds)])
          ..currentMovePlayerIndex = 3
          ..currentPlayerIndex = 0;
        return result;
      }

      final playEngine = inState();
      expect(
        playEngine.playCards('p0', [c(CardRank.two, CardSuit.hearts)]).isValid,
        isTrue,
      );

      final passEngine = inState();
      expect(passEngine.pass('p0').isValid, isTrue);
    });

    test('passed human with only a higher 2 is skipped', () {
      final result = engineWithHands([
        [c(CardRank.two, CardSuit.hearts)],
        [c(CardRank.four, CardSuit.spades)],
        [c(CardRank.five, CardSuit.spades)],
        [c(CardRank.six, CardSuit.spades)],
      ], current: 3);
      result.state
        ..openingRuleActive = false
        ..currentTableMove = m([c(CardRank.two, CardSuit.diamonds)])
        ..currentMovePlayerIndex = 2
        ..currentPlayerIndex = 3
        ..passedPlayerIds.add('p0');

      expect(
        validator.isChopAgainstTwos(
          m([c(CardRank.two, CardSuit.hearts)]),
          result.state.currentTableMove!,
        ),
        isFalse,
      );
      expect(result.pass('p3').isValid, isTrue);
      expect(result.state.currentPlayer.id, 'p1');
    });

    test('passed human may re-enter with four of a kind chop', () {
      final bomb = four(CardRank.seven);
      final result = engineWithHands([
        [...bomb, c(CardRank.ace, CardSuit.spades)],
        [c(CardRank.four, CardSuit.spades)],
        [c(CardRank.five, CardSuit.spades)],
        [c(CardRank.six, CardSuit.spades)],
      ], current: 3);
      result.state
        ..openingRuleActive = false
        ..currentTableMove = m([c(CardRank.two, CardSuit.diamonds)])
        ..currentMovePlayerIndex = 2
        ..currentPlayerIndex = 3
        ..passedPlayerIds.add('p0');

      expect(result.pass('p3').isValid, isTrue);
      expect(result.state.currentPlayer.id, 'p0');
      expect(result.playCards('p0', bomb).isValid, isTrue);
    });

    test('turn does not wrap to trick owner while an opponent is eligible', () {
      final result = engineWithHands([
        [c(CardRank.two, CardSuit.diamonds)],
        [c(CardRank.two, CardSuit.hearts)],
        [c(CardRank.five, CardSuit.spades)],
        [c(CardRank.six, CardSuit.spades)],
      ], current: 2);
      result.state
        ..openingRuleActive = false
        ..currentTableMove = m([c(CardRank.two, CardSuit.diamonds)])
        ..currentMovePlayerIndex = 0
        ..currentPlayerIndex = 2
        ..passedPlayerIds.add('p3');

      expect(result.pass('p2').isValid, isTrue);
      expect(result.state.currentPlayer.id, 'p1');
    });

    test('trick reset clears passes and restores owner lead', () {
      final result = engineWithHands([
        [c(CardRank.ace, CardSuit.hearts)],
        [c(CardRank.four, CardSuit.spades)],
        [c(CardRank.five, CardSuit.spades)],
        [c(CardRank.six, CardSuit.spades)],
      ], current: 3);
      result.state
        ..openingRuleActive = false
        ..currentTableMove = m([c(CardRank.ace, CardSuit.hearts)])
        ..currentMovePlayerIndex = 0
        ..currentPlayerIndex = 3
        ..passedPlayerIds.addAll(['p1', 'p2']);

      expect(result.pass('p3').isValid, isTrue);
      expect(result.state.currentTableMove, isNull);
      expect(result.state.passedPlayerIds, isEmpty);
      expect(result.state.currentPlayer.id, 'p0');
    });
  });

  group('Simple AI', () {
    final ai = AiPlayer();

    test('finds lowest legal single response without wasting 2', () {
      final player = Player(
        id: 'ai',
        displayName: 'AI',
        isHuman: false,
        hand: [
          c(CardRank.five, CardSuit.spades),
          c(CardRank.six, CardSuit.spades),
          c(CardRank.two, CardSuit.hearts),
        ],
      );
      final move = ai.chooseMove(
        player,
        currentMove: m([c(CardRank.five, CardSuit.hearts)]),
      );
      expect(move?.cards.single.rank, CardRank.six);
    });

    test('returns null when no response exists', () {
      final player = Player(
        id: 'ai',
        displayName: 'AI',
        isHuman: false,
        hand: [c(CardRank.five, CardSuit.spades)],
      );
      expect(
        ai.chooseMove(
          player,
          currentMove: m([c(CardRank.ace, CardSuit.hearts)]),
        ),
        isNull,
      );
    });

    test('can lead a valid move', () {
      final player = Player(
        id: 'ai',
        displayName: 'AI',
        isHuman: false,
        hand: [...pair(CardRank.four), c(CardRank.king, CardSuit.hearts)],
      );
      expect(ai.chooseMove(player)?.isValid, isTrue);
    });

    test('opening AI move contains 3♠', () {
      final threeSpades = c(CardRank.three, CardSuit.spades);
      final player = Player(
        id: 'ai',
        displayName: 'AI',
        isHuman: false,
        hand: [
          threeSpades,
          c(CardRank.four, CardSuit.hearts),
          c(CardRank.five, CardSuit.clubs),
        ],
      );
      expect(
        ai.chooseMove(player, mustContainThreeSpades: true)?.cards,
        contains(threeSpades),
      );
    });
  });
}
