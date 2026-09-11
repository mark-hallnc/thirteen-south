import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tien_len/ai/ai_difficulty.dart';
import 'package:tien_len/main.dart';
import 'package:tien_len/models/game_statistics.dart';
import 'package:tien_len/models/coin_statistics.dart';
import 'package:tien_len/models/playing_card.dart';
import 'package:tien_len/preferences_scope.dart';
import 'package:tien_len/services/preferences_service.dart';
import 'package:tien_len/screens/game_screen.dart';
import 'package:tien_len/screens/settings_screen.dart';
import 'package:tien_len/widgets/player_hand.dart';

import 'ui_test.dart' show humanLeadEngine, localizedGame;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('in-game settings returns to the same game and preferences', (
    tester,
  ) async {
    await tester.pumpWidget(const TienLenApp());
    await tester.pumpAndSettle();
    final engine = humanLeadEngine();
    final gameState = engine.state;
    final gameId = engine.gameId;
    final engineHand = List<PlayingCard>.of(engine.players.first.hand);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push<void>(
      MaterialPageRoute<void>(builder: (_) => GameScreen(engine: engine)),
    );
    await tester.pumpAndSettle();
    final screenState = tester.state(find.byType(GameScreen));
    PlayerHand hand() => tester.widget<PlayerHand>(find.byType(PlayerHand));
    hand().onReorder!(0, 1);
    hand().onCardTap(engineHand.first);
    await tester.pumpAndSettle();
    final displayOrder = List<PlayingCard>.of(hand().cards);

    for (final enabled in [false, true]) {
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      final toggle = find.byKey(const ValueKey('sounds-enabled'));
      await tester.scrollUntilVisible(toggle, 200);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(toggle).value, enabled);
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.state(find.byType(GameScreen)), same(screenState));
      expect(engine.state, same(gameState));
      expect(engine.gameId, gameId);
      expect(engine.players.first.hand, engineHand);
      expect(hand().cards, displayOrder);
      expect(hand().selectedCards, {engineHand.first});
      expect(
        PreferencesScope.of(
          tester.element(find.byType(GameScreen)),
        ).soundsEnabled,
        enabled,
      );
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('active back cancels safely or leaves without recording a loss', (
    tester,
  ) async {
    await tester.pumpWidget(const TienLenApp());
    await tester.pumpAndSettle();
    final engine = humanLeadEngine();
    final gameId = engine.gameId;
    final state = engine.state;
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push<void>(
      MaterialPageRoute<void>(builder: (_) => GameScreen(engine: engine)),
    );
    await tester.pumpAndSettle();
    final screenState = tester.state(find.byType(GameScreen));
    final hand = tester.widget<PlayerHand>(find.byType(PlayerHand));
    hand.onReorder!(0, 1);
    hand.onCardTap(engine.players.first.hand.first);
    await tester.pumpAndSettle();
    final order = List<PlayingCard>.of(hand.cards);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Leave game?'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(GameScreen)), same(screenState));
    expect(engine.state, same(state));
    expect(engine.gameId, gameId);
    final resumed = tester.widget<PlayerHand>(find.byType(PlayerHand));
    expect(resumed.cards, order);
    expect(resumed.selectedCards, {engine.players.first.hand.first});
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsNothing);
    expect(find.byKey(const ValueKey('new-game-button')), findsOneWidget);
    expect(engine.gameId, gameId);
    expect(engine.state.isActive, isTrue);
    final statistics = PreferencesService(
      await SharedPreferences.getInstance(),
    ).loadStatistics();
    expect(statistics.gamesPlayed, 0);
    expect(statistics.losses, 0);
  });

  testWidgets('completed game exits without confirmation', (tester) async {
    await tester.pumpWidget(const TienLenApp());
    await tester.pumpAndSettle();
    final engine = humanLeadEngine(winningHand: true);
    engine.playCards(engine.players.first.id, [
      engine.players.first.hand.single,
    ]);
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push<void>(
          MaterialPageRoute<void>(builder: (_) => GameScreen(engine: engine)),
        );
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(GameScreen), findsNothing);
    expect(find.byKey(const ValueKey('new-game-button')), findsOneWidget);
  });

  test('sounds default on and both values survive store reload', () async {
    final preferences = await SharedPreferences.getInstance();
    final service = PreferencesService(preferences);
    expect(service.loadSoundsEnabled(), isTrue);
    for (final value in [false, true]) {
      await service.saveSoundsEnabled(value);
      await preferences.reload();
      expect(PreferencesService(preferences).loadSoundsEnabled(), value);
      expect(preferences.getBool('sounds_enabled'), value);
    }
  });

  testWidgets('sound changes notify scope dependents', (tester) async {
    var enabled = true;
    late StateSetter update;
    var builds = 0;
    final child = Builder(
      builder: (context) {
        builds++;
        return Text('${PreferencesScope.of(context).soundsEnabled}');
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return PreferencesScope(
              coins: const CoinStatistics(),
              commitStake: (_, _) async => true,
              settleGame: (_, _, _) async => const CoinStatistics(),
              difficulty: AiDifficulty.normal,
              statistics: const GameStatistics(),
              soundsEnabled: enabled,
              setSoundsEnabled: (_) async {},
              setDifficulty: (_) async {},
              recordGameResult: (_, _) async {},
              resetStatistics: () async {},
              child: child,
            );
          },
        ),
      ),
    );
    final before = builds;
    update(() => enabled = false);
    await tester.pump();
    expect(builds, before + 1);
    expect(find.text('false'), findsOneWidget);
    update(() => enabled = false);
    await tester.pump();
    expect(builds, before + 1);
  });

  testWidgets('sound switch reflects persisted value and updates it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'sounds_enabled': false});
    await tester.pumpWidget(const TienLenApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Settings'));
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    final toggle = find.byKey(const ValueKey('sounds-enabled'));
    await tester.scrollUntilVisible(toggle, 200);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    expect(
      (await SharedPreferences.getInstance()).getBool('sounds_enabled'),
      isTrue,
    );
  });

  testWidgets('display order preserves engine order, plays, and resets', (
    tester,
  ) async {
    final engine = humanLeadEngine();
    engine.players.first.replaceHand([
      const PlayingCard(CardRank.three, CardSuit.spades),
      const PlayingCard(CardRank.four, CardSuit.clubs),
      const PlayingCard(CardRank.five, CardSuit.hearts),
      const PlayingCard(CardRank.seven, CardSuit.spades),
    ]);
    final original = List<PlayingCard>.of(engine.players.first.hand);
    await tester.pumpWidget(
      localizedGame(engine, aiDelay: const Duration(hours: 1)),
    );
    PlayerHand hand() => tester.widget<PlayerHand>(find.byType(PlayerHand));
    expect(hand().cards, original);
    hand().onReorder!(3, 1);
    await tester.pump();
    expect(hand().cards, [original[0], original[3], original[1], original[2]]);
    expect(engine.players.first.hand, original);
    hand().onReorder!(1, 3);
    await tester.pump();
    expect(hand().cards, original);
    hand().onReorder!(3, 1);
    await tester.pump();
    hand().onCardTap(original[0]);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('play-button')));
    await tester.pump();
    expect(hand().cards, [original[3], original[1], original[2]]);
    expect(engine.players.first.hand, original.skip(1).toList());
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start New Game'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('stake-10')));
    await tester.pump();
    expect(hand().cards, orderedEquals([...hand().cards]..sort()));
    expect(hand().cards, hasLength(13));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('horizontal drag reorders without selecting; taps still select', (
    tester,
  ) async {
    final cards = [
      for (final rank in [
        CardRank.three,
        CardRank.four,
        CardRank.five,
        CardRank.six,
      ])
        PlayingCard(rank, CardSuit.spades),
    ];
    final selected = <PlayingCard>{};
    final last = cards.last;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: StatefulBuilder(
                builder: (context, update) {
                  return PlayerHand(
                    cards: cards,
                    selectedCards: selected,
                    enabled: true,
                    onCardTap: (card) => update(() {
                      selected.contains(card)
                          ? selected.remove(card)
                          : selected.add(card);
                    }),
                    onReorder: (oldIndex, newIndex) => update(() {
                      cards.insert(newIndex, cards.removeAt(oldIndex));
                    }),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    final target = find.byKey(ValueKey(last));
    await tester.drag(target, const Offset(-110, 0));
    await tester.pumpAndSettle();
    expect(cards.indexOf(last), lessThan(3));
    expect(selected, isEmpty);
    final exposedCorner = tester.getTopLeft(target) + const Offset(8, 20);
    await tester.tapAt(exposedCorner);
    await tester.pumpAndSettle();
    expect(selected, contains(last));
    await tester.tapAt(tester.getTopLeft(target) + const Offset(8, 20));
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
  });
}
