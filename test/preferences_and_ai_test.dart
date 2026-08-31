import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tien_len/ai/ai_difficulty.dart';
import 'package:tien_len/ai/ai_player.dart';
import 'package:tien_len/game/game_engine.dart';
import 'package:tien_len/game/hand_analyzer.dart';
import 'package:tien_len/models/game_statistics.dart';
import 'package:tien_len/models/player.dart';
import 'package:tien_len/models/playing_card.dart';
import 'package:tien_len/services/preferences_service.dart';

PlayingCard card(CardRank rank, CardSuit suit) => PlayingCard(rank, suit);

void main() {
  group('GameStatistics', () {
    test('new statistics and zero-game win rate are safe', () {
      const statistics = GameStatistics();
      expect(statistics.gamesPlayed, 0);
      expect(statistics.wins, 0);
      expect(statistics.losses, 0);
      expect(statistics.currentWinStreak, 0);
      expect(statistics.bestWinStreak, 0);
      expect(statistics.winRate, 0);
    });

    test('wins increment games, wins, and streaks', () {
      final first = const GameStatistics().recordResult(humanWon: true);
      final second = first.recordResult(humanWon: true);
      expect(second.gamesPlayed, 2);
      expect(second.wins, 2);
      expect(second.losses, 0);
      expect(second.currentWinStreak, 2);
      expect(second.bestWinStreak, 2);
      expect(second.winRate, 1);
    });

    test('a loss increments losses and resets only current streak', () {
      final statistics = const GameStatistics()
          .recordResult(humanWon: true)
          .recordResult(humanWon: true)
          .recordResult(humanWon: false);
      expect(statistics.gamesPlayed, 3);
      expect(statistics.wins, 2);
      expect(statistics.losses, 1);
      expect(statistics.currentWinStreak, 0);
      expect(statistics.bestWinStreak, 2);
      expect(statistics.winRate, closeTo(2 / 3, .0001));
    });
  });

  group('PreferencesService', () {
    late PreferencesService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      service = PreferencesService(await SharedPreferences.getInstance());
    });

    test('defaults to Normal difficulty', () {
      expect(service.loadDifficulty(), AiDifficulty.normal);
    });

    test('selected difficulty persists', () async {
      await service.saveDifficulty(AiDifficulty.hard);
      expect(service.loadDifficulty(), AiDifficulty.hard);
    });

    test('invalid saved difficulty falls back to Normal', () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(PreferencesService.difficultyKey, 'expert');
      expect(service.loadDifficulty(), AiDifficulty.normal);
    });

    test('records human wins and AI wins exactly once per game', () async {
      await service.recordGameResult(gameId: 'win-1', humanWon: true);
      await service.recordGameResult(gameId: 'win-1', humanWon: true);
      final statistics = await service.recordGameResult(
        gameId: 'loss-1',
        humanWon: false,
      );
      expect(statistics.gamesPlayed, 2);
      expect(statistics.wins, 1);
      expect(statistics.losses, 1);
      expect(statistics.currentWinStreak, 0);
      expect(statistics.bestWinStreak, 1);
    });

    test('reset clears stats without resetting difficulty', () async {
      await service.saveDifficulty(AiDifficulty.easy);
      await service.recordGameResult(gameId: 'win-1', humanWon: true);
      final reset = await service.resetStatistics();
      expect(reset.gamesPlayed, 0);
      expect(reset.wins, 0);
      expect(reset.losses, 0);
      expect(reset.currentWinStreak, 0);
      expect(reset.bestWinStreak, 0);
      expect(service.loadDifficulty(), AiDifficulty.easy);
    });
  });

  group('Difficulty integration', () {
    test('changing difficulty does not reset game state', () {
      final players = List.generate(
        4,
        (index) =>
            Player(id: 'p$index', displayName: 'P$index', isHuman: index == 0),
      );
      final engine = GameEngine(players: players)
        ..startWithHands([
          [card(CardRank.three, CardSuit.spades)],
          [card(CardRank.four, CardSuit.spades)],
          [card(CardRank.five, CardSuit.spades)],
          [card(CardRank.six, CardSuit.spades)],
        ]);
      final state = engine.state;
      final gameId = engine.gameId;
      engine.difficulty = AiDifficulty.hard;
      expect(engine.state, same(state));
      expect(engine.gameId, gameId);
      expect(engine.difficulty, AiDifficulty.hard);
    });
  });

  group('AI difficulties', () {
    final ai = AiPlayer();
    final analyzer = HandAnalyzer();
    final tableFive = analyzer.analyze([card(CardRank.five, CardSuit.hearts)]);

    Player player(List<PlayingCard> hand) =>
        Player(id: 'ai', displayName: 'AI', isHuman: false, hand: hand);

    test('Easy always returns a legal move and favors a weak candidate', () {
      final move = ai.chooseMove(
        player([
          card(CardRank.six, CardSuit.spades),
          card(CardRank.king, CardSuit.hearts),
          card(CardRank.two, CardSuit.hearts),
        ]),
        currentMove: tableFive,
        difficulty: AiDifficulty.easy,
      );
      expect(move, isNotNull);
      expect(move!.cards.single.rank, CardRank.six);
    });

    test('Normal avoids a 2 when an ordinary response works', () {
      final move = ai.chooseMove(
        player([
          card(CardRank.six, CardSuit.spades),
          card(CardRank.two, CardSuit.hearts),
        ]),
        currentMove: tableFive,
        difficulty: AiDifficulty.normal,
      );
      expect(move?.cards.single.rank, CardRank.six);
    });

    test('Normal and Hard preserve a bomb when an ordinary move works', () {
      final hand = [
        card(CardRank.six, CardSuit.spades),
        for (final suit in CardSuit.values) card(CardRank.seven, suit),
      ];
      for (final difficulty in [AiDifficulty.normal, AiDifficulty.hard]) {
        final move = ai.chooseMove(
          player(hand),
          currentMove: tableFive,
          difficulty: difficulty,
        );
        expect(move?.isFourOfAKind, isFalse);
        expect(move?.cards.single.rank, CardRank.six);
      }
    });

    test('Hard responds to one-card pressure with a multi-card lead', () {
      final move = ai.chooseMove(
        player([
          card(CardRank.three, CardSuit.spades),
          card(CardRank.four, CardSuit.spades),
          card(CardRank.four, CardSuit.hearts),
          card(CardRank.king, CardSuit.clubs),
        ]),
        difficulty: AiDifficulty.hard,
        opponentCardCounts: const [1, 6, 8],
      );
      expect(move?.isPair, isTrue);
    });

    test('Hard sheds a multi-card combination in its own endgame', () {
      final move = ai.chooseMove(
        player([
          card(CardRank.four, CardSuit.spades),
          card(CardRank.four, CardSuit.hearts),
          card(CardRank.king, CardSuit.clubs),
        ]),
        difficulty: AiDifficulty.hard,
      );
      expect(move?.isPair, isTrue);
    });

    test('AI API depends on public counts, not hidden card identities', () {
      final hand = player([
        card(CardRank.six, CardSuit.spades),
        card(CardRank.king, CardSuit.hearts),
      ]);
      final first = ai.chooseMove(
        hand,
        currentMove: tableFive,
        difficulty: AiDifficulty.hard,
        opponentCardCounts: const [1, 5, 7],
      );
      final second = ai.chooseMove(
        hand,
        currentMove: tableFive,
        difficulty: AiDifficulty.hard,
        opponentCardCounts: const [1, 5, 7],
      );
      expect(first, second);
    });
  });
}
