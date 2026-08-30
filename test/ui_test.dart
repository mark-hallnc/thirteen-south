import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tien_len/game/game_engine.dart';
import 'package:tien_len/l10n/app_localizations.dart';
import 'package:tien_len/main.dart';
import 'package:tien_len/models/player.dart';
import 'package:tien_len/models/playing_card.dart';
import 'package:tien_len/screens/game_screen.dart';
import 'package:tien_len/widgets/game_table_widgets.dart';
import 'package:tien_len/widgets/playing_card_widget.dart';

PlayingCard card(CardRank rank, CardSuit suit) => PlayingCard(rank, suit);

GameEngine humanLeadEngine({bool winningHand = false}) {
  final players = List.generate(
    4,
    (index) =>
        Player(id: 'p$index', displayName: 'P$index', isHuman: index == 0),
  );
  final threeSpades = card(CardRank.three, CardSuit.spades);
  return GameEngine(players: players)..startWithHands([
    [threeSpades, if (!winningHand) card(CardRank.ace, CardSuit.hearts)],
    [card(CardRank.four, CardSuit.spades)],
    [card(CardRank.five, CardSuit.spades)],
    [card(CardRank.six, CardSuit.spades)],
  ]);
}

Widget localizedGame(GameEngine engine, {Duration aiDelay = Duration.zero}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('vi')],
    home: GameScreen(engine: engine, aiDelay: aiDelay),
  );
}

Widget opponentPanel({required int cardCount}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 300,
        height: 110,
        child: OpponentPanel(
          opponentId: 'test-opponent',
          name: 'Computer 1',
          cardCount: cardCount,
          cardsLabel: 'cards',
          passedLabel: 'Passed',
          isPassed: false,
          isActive: false,
          position: OpponentPosition.top,
        ),
      ),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('Home screen renders', (tester) async {
    await tester.pumpWidget(const TienLenApp());
    await tester.pumpAndSettle();
    expect(find.text('Thirteen South: Tiến Lên'), findsOneWidget);
    expect(find.byKey(const ValueKey('new-game-button')), findsOneWidget);
    expect(find.text('Southern Vietnamese card game'), findsOneWidget);
  });

  testWidgets('New Game enters game screen and renders human cards', (
    tester,
  ) async {
    await tester.pumpWidget(const TienLenApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('new-game-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('game-table')), findsOneWidget);
    expect(find.byType(PlayingCardWidget), findsNWidgets(13));
  });

  testWidgets('Opponent hand renders one hidden card back per card', (
    tester,
  ) async {
    await tester.pumpWidget(opponentPanel(cardCount: 13));

    expect(find.byType(CardBackWidget), findsNWidgets(13));
    expect(
      find.byKey(const ValueKey('opponent-test-opponent-card-count')),
      findsOneWidget,
    );
    expect(find.text('13 cards'), findsOneWidget);
    expect(find.byType(PlayingCardWidget), findsNothing);
    expect(find.textContaining('♠'), findsNothing);

    await tester.pumpWidget(opponentPanel(cardCount: 8));
    await tester.pump();

    expect(find.byType(CardBackWidget), findsNWidgets(8));
    expect(find.text('8 cards'), findsOneWidget);
  });

  testWidgets('Side opponent hands rotate every hidden card', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 48,
            height: 150,
            child: OpponentHand(
              opponentId: 'left-opponent',
              cardCount: 13,
              position: OpponentPosition.left,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CardBackWidget), findsNWidgets(13));
    for (var index = 0; index < 13; index++) {
      final rotation = tester.widget<Transform>(
        find.byKey(ValueKey('opponent-left-opponent-card-rotation-$index')),
      );
      expect(rotation.transform.entry(0, 0), closeTo(0, .0001));
      expect(rotation.transform.entry(1, 0), closeTo(-1, .0001));
    }
  });

  testWidgets('Center table renders the played card faces', (tester) async {
    final cards = [
      card(CardRank.four, CardSuit.spades),
      card(CardRank.four, CardSuit.hearts),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            child: TableMoveArea(cards: cards, emptyLabel: 'Empty'),
          ),
        ),
      ),
    );

    expect(find.byType(PlayingCardWidget), findsNWidgets(2));
    expect(
      tester.widgetList<PlayingCardWidget>(find.byType(PlayingCardWidget)),
      everyElement(
        isA<PlayingCardWidget>().having((widget) => widget.width, 'width', 64),
      ),
    );
  });

  testWidgets('Game table fits a 320dp portrait screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final engine = GameEngine()..startNewGame();

    await tester.pumpWidget(
      localizedGame(engine, aiDelay: const Duration(hours: 1)),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('game-table')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Selecting a card lifts it and enables Play', (tester) async {
    final engine = humanLeadEngine();
    final selectedCard = engine.players.first.hand.first;
    await tester.pumpWidget(localizedGame(engine));
    await tester.pump();

    final positionFinder = find.byKey(ValueKey(selectedCard));
    expect(tester.widget<AnimatedPositioned>(positionFinder).top, 10);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('play-button')))
          .onPressed,
      isNull,
    );

    await tester.tap(
      find.byKey(
        ValueKey('card-${selectedCard.rank.name}-${selectedCard.suit.name}'),
      ),
    );
    await tester.pump();
    expect(tester.widget<AnimatedPositioned>(positionFinder).top, 0);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('play-button')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'Play and Pass are disabled while human leads with no selection',
    (tester) async {
      await tester.pumpWidget(localizedGame(humanLeadEngine()));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('play-button')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const ValueKey('pass-button')))
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('Language selection applies immediately and persists', (
    tester,
  ) async {
    await tester.pumpWidget(const TienLenApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('language-vi')));
    await tester.pumpAndSettle();
    expect(find.text('Cài đặt'), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('app_locale'), 'vi');

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const TienLenApp());
    await tester.pumpAndSettle();
    expect(find.text('Ván mới'), findsOneWidget);
  });

  testWidgets('Game-over overlay identifies a human winner', (tester) async {
    final engine = humanLeadEngine(winningHand: true);
    final winningCard = engine.players.first.hand.single;
    engine.playCards(engine.players.first.id, [winningCard]);

    await tester.pumpWidget(localizedGame(engine));
    await tester.pumpAndSettle();
    expect(find.text('Game Over'), findsOneWidget);
    expect(find.text('You win!'), findsOneWidget);
    expect(find.text('New Game'), findsOneWidget);
  });
}
