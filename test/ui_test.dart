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

Widget localizedGame(GameEngine engine) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('vi')],
    home: GameScreen(engine: engine, aiDelay: Duration.zero),
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

  testWidgets('Selecting a card lifts it and enables Play', (tester) async {
    final engine = humanLeadEngine();
    final selectedCard = engine.players.first.hand.first;
    await tester.pumpWidget(localizedGame(engine));
    await tester.pump();

    final positionFinder = find.byKey(ValueKey(selectedCard));
    expect(tester.widget<AnimatedPositioned>(positionFinder).top, 12);
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
